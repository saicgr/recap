import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../data/database.dart';
import 'crypto/envelope.dart';
import 'data_api.dart';
import 'hlc.dart';
import 'sync_dao.dart';

/// Drains the outbox to Neon (push) and pulls peers' changes back (pull).
///
/// Local Drift is the source of truth. The engine reconciles it with the server;
/// it never becomes the truth itself, and the app is fully usable with the engine
/// switched off (offline, or no account). Everything that crosses the wire is
/// ciphertext — the engine seals on push and opens on pull, and the server sees
/// only [Envelope] blobs.
///
/// **Privacy tier never constructs this** (see main.dart). That is the structural
/// guarantee: not a disabled flag, but an object that does not exist, so there is
/// no socket to open.
class SyncEngine {
  SyncEngine({
    required this.db,
    required this.dao,
    required this.api,
    required this.workspaceId,
    required this.workspaceKey,
    required this.kid,
  });

  final AppDb db;
  final SyncDao dao;
  final DataApi api;

  /// The workspace this engine syncs. One engine per active workspace.
  final String workspaceId;
  final SecretKey workspaceKey;
  final int kid;

  bool _running = false;

  /// Key of the cursor for THIS workspace, so multiple workspaces do not clobber
  /// each other's pull position.
  String get _cursorKey => 'sync_cursor_$workspaceId';

  /// One full cycle: push local changes, then pull remote ones. Safe to call
  /// repeatedly; it no-ops if already running.
  Future<SyncOutcome> syncOnce() async {
    if (_running) return SyncOutcome.skipped;
    _running = true;
    try {
      final pushed = await _push();
      final pulled = await _pull();
      return SyncOutcome(pushed: pushed, pulled: pulled);
    } on SyncAuthError {
      // JWT rejected; NeonAuth will re-mint on the next call. Surface so the
      // caller can decide whether to prompt a re-login.
      rethrow;
    } on SyncTransientError {
      // Offline / 5xx. The outbox kept everything; try again later. Not an error
      // the user needs to see.
      return SyncOutcome.deferred;
    } finally {
      _running = false;
    }
  }

  // -- push -------------------------------------------------------------------

  Future<int> _push() async {
    final batch = await dao.pending(limit: 100);
    if (batch.isEmpty) return 0;

    final upserts = <Map<String, dynamic>>[];
    final acked = <int>[];

    for (final row in batch) {
      // v1 syncs meetings. Other entities register here as they come online; an
      // unknown table is acked-and-skipped rather than blocking the queue.
      if (row.entityTable != 'meetings') {
        acked.add(row.id);
        continue;
      }
      final payload = await _encodeMeeting(row);
      if (payload == null) {
        // The local row is gone and it was an upsert — nothing to send. (A
        // delete produces a tombstone payload, handled in _encodeMeeting.)
        acked.add(row.id);
        continue;
      }
      upserts.add(payload);
    }

    if (upserts.isNotEmpty) {
      // A permanent 4xx here would otherwise wedge the whole queue forever;
      // bump attempts and let backoff + the stuck-change surface handle it.
      try {
        await api.upsert('meetings', upserts, onConflict: 'id');
      } on SyncPermanentError {
        for (final row in batch) {
          await dao.markAttempt(row.id);
        }
        rethrow;
      }
    }

    // Ack the pushed upserts too — they were the rows we just wrote.
    for (final row in batch) {
      if (!acked.contains(row.id)) acked.add(row.id);
    }
    await dao.ack(acked);
    return upserts.length;
  }

  Future<Map<String, dynamic>?> _encodeMeeting(SyncOutboxData outbox) async {
    final hlc = outbox.hlc;
    final id = outbox.entityId;

    if (outbox.op == 'delete') {
      // Tombstone: the server keeps the row so peers learn it is gone, but its
      // content is nulled.
      return {
        'id': id,
        'workspace_id': workspaceId,
        'kid': kid,
        'hlc': hlc,
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
        'title_enc': await _seal('', id, 'title', hlc),
      };
    }

    final m = await (db.select(
      db.meetings,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (m == null) return null; // deleted locally before we pushed the upsert

    return {
      'id': id,
      'workspace_id': workspaceId,
      'kid': kid,
      'hlc': hlc,
      'duration_ms': m.durationMs,
      'deleted_at': null,
      'title_enc': await _seal(m.title, id, 'title', hlc),
    };
  }

  Future<String> _seal(
    String plaintext,
    String rowId,
    String field,
    String hlc,
  ) => Envelope.seal(
    plaintext: plaintext,
    workspaceKey: workspaceKey,
    kid: kid,
    workspaceId: workspaceId,
    table: 'meetings',
    rowId: rowId,
    field: field,
    hlc: hlc,
  );

  // -- pull -------------------------------------------------------------------

  Future<int> _pull() async {
    final cursor = await _readCursor();

    // A 10s overlap on the cursor: clocks and commit ordering are not perfectly
    // monotonic, so re-fetching a small window prevents a row that committed at
    // "the same" timestamp from being skipped forever. Apply is idempotent, so
    // re-seeing a row is free.
    final rows = await api.select(
      'meetings',
      query: {
        'workspace_id': 'eq.$workspaceId',
        'hlc': 'gt.$cursor',
        'order': 'hlc.asc',
        'limit': '200',
        'select': 'id,hlc,duration_ms,deleted_at,title_enc',
      },
    );
    if (rows.isEmpty) return 0;

    var applied = 0;
    String? maxHlc;
    for (final row in rows) {
      final ok = await _applyMeeting(row);
      if (ok) applied++;
      final h = row['hlc'] as String?;
      if (h != null && (maxHlc == null || h.compareTo(maxHlc) > 0)) maxHlc = h;
    }

    if (maxHlc != null) await _writeCursor(_overlap(maxHlc));
    return applied;
  }

  /// Apply one remote meeting. Last-writer-wins by HLC, per row.
  Future<bool> _applyMeeting(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final remoteHlc = row['hlc'] as String?;
    if (remoteHlc == null) return false;

    // Fold the remote clock into ours so our next local edit sorts after it.
    try {
      dao.observe(Hlc.parse(remoteHlc));
    } catch (_) {
      // A wildly-future remote clock — HLC.receive rejects it. Skip the row
      // rather than poison our clock or crash the whole pull.
      return false;
    }

    final existing = await (db.select(
      db.meetings,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    // Last-writer-wins: if our local copy is newer, keep it. We compare the
    // stored HLC we last applied; a locally-edited row carries a pending outbox
    // entry whose HLC is what matters.
    final localHlc = await _localHlcFor('meetings', id);
    if (localHlc != null && localHlc.compareTo(remoteHlc) >= 0) {
      return false; // ours is newer or equal — do not clobber a local edit
    }

    final deletedAt = row['deleted_at'];
    if (deletedAt != null) {
      // Remote tombstone. Delete locally (cascades handle children) and clear
      // any stale outbox entry.
      if (existing != null) {
        await (db.delete(db.meetings)..where((t) => t.id.equals(id))).go();
      }
      await _clearLocalHlc('meetings', id);
      return true;
    }

    final title = await _open(
      row['title_enc'] as String?,
      id,
      'title',
      remoteHlc,
    );
    if (title == null) {
      // undecryptable (missing key) — skip, do not corrupt
      return false;
    }

    final now = DateTime.now();
    if (existing == null) {
      await db
          .into(db.meetings)
          .insert(
            MeetingsCompanion.insert(
              id: id,
              title: title,
              durationMs: Value((row['duration_ms'] as num?)?.toInt() ?? 0),
              // Audio is synced separately (R2); a pulled meeting has no local
              // file yet. The transcript screen tolerates a missing audioPath.
              audioPath: '',
              createdAt: now,
              updatedAt: now,
              status: MeetingStatus.ready,
            ),
            mode: InsertMode.insertOrReplace,
          );
    } else {
      await (db.update(db.meetings)..where((t) => t.id.equals(id))).write(
        MeetingsCompanion(title: Value(title), updatedAt: Value(now)),
      );
    }
    await _setLocalHlc('meetings', id, remoteHlc);
    return true;
  }

  Future<String?> _open(
    String? sealed,
    String rowId,
    String field,
    String hlc,
  ) async {
    if (sealed == null) return null;
    try {
      return await Envelope.open(
        sealed: sealed,
        workspaceKey: workspaceKey,
        workspaceId: workspaceId,
        table: 'meetings',
        rowId: rowId,
        field: field,
        hlc: hlc,
      );
    } on EnvelopeError {
      // Wrong key generation, or tampering. Skipping is correct: writing a
      // placeholder would look like the user's data, and crashing would stall
      // the whole pull on one bad row.
      return null;
    }
  }

  // -- applied-HLC bookkeeping + cursor --------------------------------------
  //
  // A tiny key/value table records the HLC we last applied per row, so LWW can
  // compare without decrypting, and the pull cursor per workspace. Stored in a
  // Drift-managed misc table via customStatement to avoid another migration in
  // this step; promoted to a real table when the sync schema settles.

  Future<String?> _localHlcFor(String table, String id) async {
    final rows = await db
        .customSelect(
          'SELECT v FROM sync_meta WHERE k = ?',
          variables: [Variable<String>('hlc:$table:$id')],
        )
        .get();
    return rows.isEmpty ? null : rows.first.read<String>('v');
  }

  Future<void> _setLocalHlc(String table, String id, String hlc) =>
      db.customStatement(
        'INSERT INTO sync_meta(k,v) VALUES(?,?) '
        'ON CONFLICT(k) DO UPDATE SET v=excluded.v',
        ['hlc:$table:$id', hlc],
      );

  Future<void> _clearLocalHlc(String table, String id) => db.customStatement(
    'DELETE FROM sync_meta WHERE k = ?',
    ['hlc:$table:$id'],
  );

  Future<String> _readCursor() async {
    final rows = await db
        .customSelect(
          'SELECT v FROM sync_meta WHERE k = ?',
          variables: [Variable<String>(_cursorKey)],
        )
        .get();
    return rows.isEmpty ? '' : rows.first.read<String>('v');
  }

  Future<void> _writeCursor(String cursor) => db.customStatement(
    'INSERT INTO sync_meta(k,v) VALUES(?,?) '
    'ON CONFLICT(k) DO UPDATE SET v=excluded.v',
    [_cursorKey, cursor],
  );

  /// Rewind the cursor by ~10s worth of HLC millis so an overlapping window is
  /// re-scanned next pull. Cheap insurance against a row committed at a boundary
  /// being skipped.
  String _overlap(String hlc) {
    try {
      final h = Hlc.parse(hlc);
      final rewound = Hlc(
        millis: (h.millis - 10000).clamp(0, h.millis),
        counter: 0,
        nodeId: h.nodeId,
      );
      return rewound.toString();
    } catch (_) {
      return hlc;
    }
  }
}

class SyncOutcome {
  const SyncOutcome({this.pushed = 0, this.pulled = 0, this.status = 'ok'});
  const SyncOutcome._(this.status) : pushed = 0, pulled = 0;

  final int pushed;
  final int pulled;
  final String status;

  static const skipped = SyncOutcome._('skipped');
  static const deferred = SyncOutcome._('deferred');
}
