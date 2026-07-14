import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recap/data/database.dart';
import 'package:recap/services/sync/hlc.dart';
import 'package:recap/services/sync/sync_dao.dart';

void main() {
  late AppDb db;
  late SyncDao dao;

  setUp(() {
    db = AppDb.forTesting(NativeDatabase.memory());
    dao = SyncDao(db: db, nodeId: 'node-1');
  });
  tearDown(() => db.close());

  Future<void> seedMeeting(String id) => db.into(db.meetings).insert(
        MeetingsCompanion.insert(
          id: id,
          title: 'M $id',
          durationMs: const Value(1),
          audioPath: '/tmp/$id.wav',
          createdAt: DateTime(2026, 7, 1),
          updatedAt: DateTime(2026, 7, 1),
          status: MeetingStatus.ready,
        ),
      );

  test('a change and its outbox marker commit atomically', () async {
    // The core guarantee. If the transaction rolls back, NEITHER the row nor its
    // outbox marker exists — a change can never be saved-but-unqueued.
    await expectLater(
      db.transaction(() async {
        await seedMeeting('m1');
        await dao.recordChange(
            table: 'meetings', id: 'm1', op: 'upsert', hlc: dao.tick());
        throw Exception('crash before commit');
      }),
      throwsException,
    );
    expect(await db.select(db.meetings).get(), isEmpty);
    expect(await dao.pending(), isEmpty);
  });

  test('a committed change leaves exactly one outbox row', () async {
    await db.transaction(() async {
      await seedMeeting('m1');
      await dao.recordChange(
          table: 'meetings', id: 'm1', op: 'upsert', hlc: dao.tick());
    });
    final pending = await dao.pending();
    expect(pending.length, 1);
    expect(pending.single.entityId, 'm1');
    expect(pending.single.op, 'upsert');
  });

  test('repeated edits to one row coalesce to a single push', () async {
    // A burst of edits to a note should become ONE server write, not twenty.
    for (var i = 0; i < 5; i++) {
      await dao.recordChange(
          table: 'meetings', id: 'm1', op: 'upsert', hlc: dao.tick());
    }
    final pending = await dao.pending();
    expect(pending.length, 1);
    // And it carries the LATEST clock, not the first.
    expect(pending.single.hlc, dao.clock.toString());
  });

  test('an upsert followed by a delete collapses to a delete', () async {
    await dao.recordChange(
        table: 'meetings', id: 'm1', op: 'upsert', hlc: dao.tick());
    await dao.recordChange(
        table: 'meetings', id: 'm1', op: 'delete', hlc: dao.tick());
    final pending = await dao.pending();
    expect(pending.length, 1);
    expect(pending.single.op, 'delete',
        reason: 'no point pushing a create for something we then deleted');
  });

  test('ack drains only the acknowledged rows', () async {
    await dao.recordChange(
        table: 'meetings', id: 'a', op: 'upsert', hlc: dao.tick());
    await dao.recordChange(
        table: 'meetings', id: 'b', op: 'upsert', hlc: dao.tick());
    final pending = await dao.pending();
    expect(pending.length, 2);

    await dao.ack([pending.first.id]);
    final remaining = await dao.pending();
    expect(remaining.length, 1);
    expect(remaining.single.entityId, 'b');
  });

  test('the HLC advances across changes and folds in remote clocks', () {
    final first = dao.tick(nowMs: 1000);
    final second = dao.tick(nowMs: 1000); // same ms
    expect(second > first, isTrue);

    // A remote edit from the future pulls our clock up, so our next edit sorts
    // after it.
    const remote = Hlc(millis: 5000, counter: 0, nodeId: 'other');
    dao.observe(remote, nowMs: 1001);
    final third = dao.tick(nowMs: 1001);
    expect(third > remote, isTrue);
  });

  test('backoff grows and is bounded', () {
    expect(SyncDao.backoff(0).inSeconds, lessThanOrEqualTo(2));
    expect(SyncDao.backoff(3).inSeconds, inInclusiveRange(8, 10));
    expect(SyncDao.backoff(50).inSeconds, lessThanOrEqualTo(360),
        reason: 'must cap, not grow forever');
  });
}
