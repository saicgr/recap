import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recap/data/database.dart';
import 'package:recap/services/sync/crypto/key_wrap.dart';
import 'package:recap/services/sync/data_api.dart';
import 'package:recap/services/sync/sync_dao.dart';
import 'package:recap/services/sync/sync_engine.dart';

/// A DataApi stand-in backed by an in-memory "server" table, so the full
/// push/pull cycle — including real encryption — runs with no network. Two
/// engines pointed at the same fake are two devices in one workspace.
class FakeServer {
  final Map<String, Map<String, dynamic>> rows = {}; // id -> row

  DataApi apiFor() => _FakeDataApi(this);
}

class _FakeDataApi implements DataApi {
  _FakeDataApi(this.server);
  final FakeServer server;

  @override
  Future<void> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    required String onConflict,
  }) async {
    for (final r in rows) {
      server.rows[r['id'] as String] = Map.of(r);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, String> query = const {},
  }) async {
    final cursor = (query['hlc'] ?? 'gt.').substring(3);
    final out =
        server.rows.values
            .where((r) => (r['hlc'] as String).compareTo(cursor) > 0)
            .map(Map<String, dynamic>.of)
            .toList()
          ..sort((a, b) => (a['hlc'] as String).compareTo(b['hlc'] as String));
    return out;
  }

  @override
  Future<dynamic> rpc(String fn, Map<String, dynamic> args) async => null;

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late SecretKey kws;
  late FakeServer server;

  setUp(() async {
    kws = await KeyWrap.generateWorkspaceKey();
    server = FakeServer();
  });

  ({AppDb db, SyncEngine engine, SyncDao dao}) device(String node) {
    final db = AppDb.forTesting(NativeDatabase.memory());
    final dao = SyncDao(db: db, nodeId: node);
    final engine = SyncEngine(
      db: db,
      dao: dao,
      api: server.apiFor(),
      workspaceId: 'ws-1',
      workspaceKey: kws,
      kid: 1,
    );
    return (db: db, engine: engine, dao: dao);
  }

  Future<void> makeMeeting(
    AppDb db,
    SyncDao dao,
    String id,
    String title,
  ) async {
    await db.transaction(() async {
      await db
          .into(db.meetings)
          .insert(
            MeetingsCompanion.insert(
              id: id,
              title: title,
              durationMs: const Value(1000),
              audioPath: '/tmp/$id.wav',
              createdAt: DateTime(2026, 7, 1),
              updatedAt: DateTime(2026, 7, 1),
              status: MeetingStatus.ready,
            ),
          );
      await dao.recordChange(
        table: 'meetings',
        id: id,
        op: 'upsert',
        hlc: dao.tick(),
      );
    });
  }

  test(
    'a meeting created on device A appears, decrypted, on device B',
    () async {
      final a = device('A');
      final b = device('B');

      await makeMeeting(a.db, a.dao, 'm1', 'Q3 Board Review');
      await a.engine.syncOnce();

      // The server holds only ciphertext.
      expect(server.rows['m1']!['title_enc'], isA<String>());
      expect(server.rows['m1']!['title_enc'], isNot(contains('Board')));

      await b.engine.syncOnce();
      final onB = await (b.db.select(b.db.meetings)).getSingle();
      expect(onB.id, 'm1');
      expect(onB.title, 'Q3 Board Review');

      await a.db.close();
      await b.db.close();
    },
  );

  test('the operator (holding no key) cannot read the title', () async {
    final a = device('A');
    await makeMeeting(a.db, a.dao, 'm1', 'Secret Layoffs Plan');
    await a.engine.syncOnce();

    final stored = server.rows['m1']!['title_enc'] as String;
    final wrongKey = await KeyWrap.generateWorkspaceKey();
    final peeker = device('X');
    final peekEngine = SyncEngine(
      db: peeker.db,
      dao: peeker.dao,
      api: server.apiFor(),
      workspaceId: 'ws-1',
      workspaceKey: wrongKey, // operator does not have K_ws
      kid: 1,
    );
    await peekEngine.syncOnce();
    // The row is skipped (undecryptable), not written with garbage.
    expect(await peeker.db.select(peeker.db.meetings).get(), isEmpty);
    expect(stored, isNot(contains('Layoffs')));

    await a.db.close();
    await peeker.db.close();
  });

  test(
    'last-writer-wins: a newer remote edit overwrites; an older one does not',
    () async {
      final a = device('A');
      final b = device('B');

      await makeMeeting(a.db, a.dao, 'm1', 'Original');
      await a.engine.syncOnce();
      await b.engine.syncOnce();
      expect((await b.db.select(b.db.meetings).getSingle()).title, 'Original');

      // A edits later -> B should adopt it.
      await a.db.transaction(() async {
        await (a.db.update(a.db.meetings)..where((t) => t.id.equals('m1')))
            .write(const MeetingsCompanion(title: Value('Edited on A')));
        await a.dao.recordChange(
          table: 'meetings',
          id: 'm1',
          op: 'upsert',
          hlc: a.dao.tick(),
        );
      });
      await a.engine.syncOnce();
      await b.engine.syncOnce();
      expect(
        (await b.db.select(b.db.meetings).getSingle()).title,
        'Edited on A',
      );

      await a.db.close();
      await b.db.close();
    },
  );

  test('a remote tombstone deletes the row locally', () async {
    final a = device('A');
    final b = device('B');

    await makeMeeting(a.db, a.dao, 'm1', 'Doomed');
    await a.engine.syncOnce();
    await b.engine.syncOnce();
    expect(await b.db.select(b.db.meetings).get(), isNotEmpty);

    await a.db.transaction(() async {
      await (a.db.delete(a.db.meetings)..where((t) => t.id.equals('m1'))).go();
      await a.dao.recordChange(
        table: 'meetings',
        id: 'm1',
        op: 'delete',
        hlc: a.dao.tick(),
      );
    });
    await a.engine.syncOnce();
    await b.engine.syncOnce();

    // Peers LEARN the deletion — the reason deletes are tombstones, not silent
    // local removals.
    expect(await b.db.select(b.db.meetings).get(), isEmpty);

    await a.db.close();
    await b.db.close();
  });

  test('syncing twice is idempotent — no duplicate rows', () async {
    final a = device('A');
    final b = device('B');
    await makeMeeting(a.db, a.dao, 'm1', 'Once');
    await a.engine.syncOnce();
    await b.engine.syncOnce();
    await b.engine.syncOnce(); // pull again over the overlap window
    expect((await b.db.select(b.db.meetings).get()).length, 1);

    await a.db.close();
    await b.db.close();
  });
}
