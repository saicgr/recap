import 'dart:math';

import 'package:drift/drift.dart';

import '../../data/database.dart';
import 'hlc.dart';

/// The write path for anything that syncs.
///
/// The one rule: a syncable change and its outbox marker are written in ONE
/// transaction, so they cannot come apart. Call [recordChange] inside the same
/// [AppDb.transaction] that mutates the row, and a crash can never leave a saved
/// change that no one remembers to sync.
class SyncDao {
  SyncDao({required this.db, required this.nodeId, Hlc? clock})
    : _clock = clock ?? Hlc.zero(nodeId);

  final AppDb db;

  /// Stable per-install id for this device's HLC. Persisted alongside the
  /// install identity.
  final String nodeId;

  Hlc _clock;

  /// Advance the clock and return the new stamp for a change happening now.
  Hlc tick({int? nowMs}) {
    _clock = _clock.tick(nowMs: nowMs ?? DateTime.now().millisecondsSinceEpoch);
    return _clock;
  }

  Hlc get clock => _clock;

  /// Fold a remote HLC into ours so our next local edit sorts after it.
  void observe(Hlc remote, {int? nowMs}) {
    _clock = _clock.receive(
      remote,
      nowMs: nowMs ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Enqueue a change. MUST be called inside the transaction that made it.
  ///
  /// Coalesces per (table,id): only the latest state of a row needs to reach the
  /// server, so a burst of edits to one note becomes one push, not twenty. A
  /// pending upsert followed by a delete collapses to a delete.
  Future<void> recordChange({
    required String table,
    required String id,
    required String op, // 'upsert' | 'delete'
    required Hlc hlc,
  }) async {
    await (db.delete(
      db.syncOutbox,
    )..where((o) => o.entityTable.equals(table) & o.entityId.equals(id))).go();
    await db
        .into(db.syncOutbox)
        .insert(
          SyncOutboxCompanion.insert(
            entityTable: table,
            entityId: id,
            op: op,
            hlc: hlc.toString(),
          ),
        );
  }

  /// The next batch to push, oldest first.
  Future<List<SyncOutboxData>> pending({int limit = 100}) =>
      (db.select(db.syncOutbox)
            ..orderBy([(o) => OrderingTerm.asc(o.id)])
            ..limit(limit))
          .get();

  /// Drop rows the server has acknowledged.
  Future<void> ack(Iterable<int> outboxIds) async {
    final ids = outboxIds.toList();
    if (ids.isEmpty) return;
    await (db.delete(db.syncOutbox)..where((o) => o.id.isIn(ids))).go();
  }

  /// Record a failed attempt for backoff, and surface a change that keeps
  /// failing rather than retrying it silently forever.
  Future<void> markAttempt(int outboxId) async {
    await db.customUpdate(
      'UPDATE sync_outbox SET attempts = attempts + 1 WHERE id = ?',
      variables: [Variable<int>(outboxId)],
      updates: {db.syncOutbox},
    );
  }

  /// Exponential backoff with jitter for a row that has failed [attempts] times.
  static Duration backoff(int attempts) {
    final secs = min(300, pow(2, attempts.clamp(0, 8)).toInt());
    final jitterMs = (secs * 1000 * 0.2).toInt();
    // Deterministic jitter would sync every stuck device in lockstep.
    return Duration(
      seconds: secs,
      milliseconds: Random().nextInt(jitterMs == 0 ? 1 : jitterMs),
    );
  }
}
