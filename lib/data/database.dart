import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// Enums (stored as text)
// ---------------------------------------------------------------------------

enum MeetingStatus { recording, processing, ready, failed }

enum TranscriptionMode { onDevice }

enum SummaryBackendKind { appleFoundationModels, gemma, cloud, byok, ollama }

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

class Meetings extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get audioPath => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get status => textEnum<MeetingStatus>()();
  TextColumn get failureReason => text().nullable()();
  TextColumn get calendarEventId => text().nullable()();
  TextColumn get language => text().withDefault(const Constant('en'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Transcripts extends Table {
  TextColumn get meetingId =>
      text().references(Meetings, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text()();
  TextColumn get modelId => text()(); // e.g. "whisper-small.en"
  IntColumn get processingMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {meetingId};
}

/// Chunked Whisper output during recording (live captions) and the final
/// per-segment timing for jump-to-time playback + speaker labels.
class TranscriptSegments extends Table {
  TextColumn get id => text()();
  TextColumn get meetingId =>
      text().references(Meetings, #id, onDelete: KeyAction.cascade)();
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();
  TextColumn get body => text()();
  BoolColumn get isFinal => boolean().withDefault(const Constant(false))();
  TextColumn get speakerLabel => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Summaries extends Table {
  TextColumn get id => text()();
  TextColumn get meetingId =>
      text().references(Meetings, #id, onDelete: KeyAction.cascade)();
  TextColumn get personaKey => text()(); // see lib/billing/persona.dart
  TextColumn get body => text()();
  TextColumn get backend => textEnum<SummaryBackendKind>()();
  TextColumn get modelId => text()(); // e.g. "gemini-3.1-flash-lite" / "gemma-4-e2b-it" / "apple-fm-3b"
  IntColumn get processingMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get meetingId =>
      text().references(Meetings, #id, onDelete: KeyAction.cascade)();
  IntColumn get atMs => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Daily + monthly usage counters for tier enforcement. One row per UTC day
/// (rolled forward at the user's local midnight) plus a per-month rollup.
class UsageDays extends Table {
  TextColumn get day => text()(); // YYYY-MM-DD in user TZ
  IntColumn get meetingsStarted => integer().withDefault(const Constant(0))();
  IntColumn get recordedMs => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {day};
}

class UsageMonths extends Table {
  TextColumn get month => text()(); // YYYY-MM in user TZ
  IntColumn get cloudSummariesUsed =>
      integer().withDefault(const Constant(0))();
  IntColumn get recordedMs => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {month};
}

/// Top-up credits (one-time IAP packs). One row per pack purchased; we
/// decrement when cloud summaries are consumed past the monthly quota.
class TopUpCredits extends Table {
  TextColumn get id => text()();
  IntColumn get remaining => integer()();
  DateTimeColumn get purchasedAt => dateTime()();
  TextColumn get productId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Persisted store purchases — the source of truth for the user's tier across
/// restarts. Before this table existed the tier lived only in a memory field on
/// DriftEntitlementService, so every relaunch silently dropped a paying
/// customer back to Free.
///
/// One row per store transaction, keyed by the store's own purchase id, which
/// makes restores idempotent: `restorePurchases()` replays every past
/// transaction through `purchaseStream`, and without a stable key each replay
/// would re-grant consumable top-up credits.
class Purchases extends Table {
  /// Store-issued purchase/transaction id (falls back to the product id for
  /// stores that omit it).
  TextColumn get id => text()();
  TextColumn get productId => text()();

  /// The [Tier] this purchase grants, by enum name. Null for top-up packs,
  /// which grant credits rather than a tier.
  TextColumn get tier => text().nullable()();

  /// Store transaction date. Nullable on purpose: the two stores disagree on
  /// the format (Android sends ms-since-epoch, iOS sends a date string), and
  /// recording "unknown" is better than fabricating DateTime.now() — the
  /// lifetime-grandfathering invariant is enforced against this value, so a
  /// wrong date silently corrupts it.
  DateTimeColumn get purchasedAt => dateTime().nullable()();

  /// 'store' | 'debug_override'. A debug tier switch must never be mistaken
  /// for a real purchase.
  TextColumn get source => text().withDefault(const Constant('store'))();

  DateTimeColumn get recordedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Voice ID enrollment (D14.4). One row per known speaker; embedding is a
/// WeSpeaker 256-dim Float32 vector stored as raw bytes.
class Voiceprints extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BlobColumn get embedding => blob()();
  TextColumn get avatarPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-segment embedding for cross-meeting search + chapter detection
/// (D14.10 / B3). 384-dim float32 from all-MiniLM-L6-v2.
class SegmentEmbeddings extends Table {
  TextColumn get segmentId =>
      text().references(TranscriptSegments, #id, onDelete: KeyAction.cascade)();
  TextColumn get meetingId =>
      text().references(Meetings, #id, onDelete: KeyAction.cascade)();
  BlobColumn get vec => blob()(); // Float32List.buffer.asUint8List()
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {segmentId};
}

/// Action items extracted from summaries (D14.9). One row per detected item;
/// status tracks completion across meetings.
enum ActionItemStatus { open, inProgress, done, dropped }

class ActionItems extends Table {
  TextColumn get id => text()();
  TextColumn get meetingId =>
      text().references(Meetings, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text()();
  TextColumn get assignee => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get status =>
      textEnum<ActionItemStatus>().withDefault(const Constant('open'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// User-defined folders / projects (D14.8). Nestable up to 3 levels via
/// [parentId].
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Many-to-many: meetings in folders. Drift relations.
class MeetingFolders extends Table {
  TextColumn get meetingId =>
      text().references(Meetings, #id, onDelete: KeyAction.cascade)();
  TextColumn get folderId =>
      text().references(Folders, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {meetingId, folderId};
}

/// Free-form tags (#hashtag style). Auto-suggested from NER + manual.
class MeetingTags extends Table {
  TextColumn get meetingId =>
      text().references(Meetings, #id, onDelete: KeyAction.cascade)();
  TextColumn get tag => text()();

  @override
  Set<Column> get primaryKey => {meetingId, tag};
}

/// Translation memory cache (D13.4) — repeated phrases get cached locally
/// for consistency + speed. Survives across meetings.
class TranslationCache extends Table {
  TextColumn get sourceHash => text()(); // sha256 of source
  TextColumn get sourceLang => text()();
  TextColumn get targetLang => text()();
  TextColumn get sourceText => text()();
  TextColumn get translation => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sourceHash, sourceLang, targetLang};
}

/// User-defined "do not translate" terms (Power tier — D13.4 glossary).
class GlossaryTerms extends Table {
  TextColumn get term => text()(); // exact-case match
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {term};
}

// ---------------------------------------------------------------------------
// FTS5 virtual table — cross-meeting search over transcripts + summaries.
// Drift's @UseRowClass + custom migration creates the virtual table.
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [
  Meetings,
  Transcripts,
  TranscriptSegments,
  Summaries,
  Bookmarks,
  UsageDays,
  UsageMonths,
  TopUpCredits,
  Voiceprints,
  SegmentEmbeddings,
  ActionItems,
  Folders,
  MeetingFolders,
  MeetingTags,
  TranslationCache,
  GlossaryTerms,
  Purchases,
])
class AppDb extends _$AppDb {
  AppDb() : super(_open());

  /// Test-only: run against an injected executor (e.g. NativeDatabase.memory())
  /// so migrations and entitlement logic can be exercised without a device.
  /// Do not use in app code — production always goes through [_open].
  AppDb.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // FTS5 virtual table for cross-meeting search. Indexes transcript
          // text + meeting title; we update via triggers below.
          await customStatement('''
            CREATE VIRTUAL TABLE meeting_search USING fts5(
              meeting_id UNINDEXED,
              title,
              body,
              tokenize = 'porter unicode61'
            );
          ''');
          await customStatement('''
            CREATE TRIGGER transcripts_ai AFTER INSERT ON transcripts BEGIN
              INSERT INTO meeting_search(meeting_id, title, body)
              SELECT new.meeting_id, m.title, new.body
              FROM meetings m WHERE m.id = new.meeting_id;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER transcripts_au AFTER UPDATE ON transcripts BEGIN
              DELETE FROM meeting_search WHERE meeting_id = new.meeting_id;
              INSERT INTO meeting_search(meeting_id, title, body)
              SELECT new.meeting_id, m.title, new.body
              FROM meetings m WHERE m.id = new.meeting_id;
            END;
          ''');
          await customStatement('''
            CREATE TRIGGER meetings_ad AFTER DELETE ON meetings BEGIN
              DELETE FROM meeting_search WHERE meeting_id = old.id;
            END;
          ''');
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2: added Voiceprints, SegmentEmbeddings, ActionItems,
          // Folders, MeetingFolders, MeetingTags, TranslationCache,
          // GlossaryTerms (D14.4 voice ID + D14.9 action items + D14.8
          // organization + D13.4 translation memory/glossary + B3 search).
          if (from < 2) {
            await m.createTable(voiceprints);
            await m.createTable(segmentEmbeddings);
            await m.createTable(actionItems);
            await m.createTable(folders);
            await m.createTable(meetingFolders);
            await m.createTable(meetingTags);
            await m.createTable(translationCache);
            await m.createTable(glossaryTerms);
          }
          // v2 → v3: Purchases. The tier was previously held only in memory,
          // so every relaunch dropped a paying user to Free. Existing installs
          // start with an empty table and repopulate it from iap.restore() on
          // the next launch.
          if (from < 3) {
            await m.createTable(purchases);
          }
        },
        beforeOpen: (details) async {
          // Foreign keys are OFF by default in SQLite — per connection, every
          // time. Without this, all 10 of our onDelete: cascade declarations
          // are inert decoration: deleting a meeting silently orphans its
          // transcripts, segments, summaries, bookmarks, embeddings and action
          // items, and they accumulate forever.
          //
          // ORDER MATTERS. Databases created before this hook existed have been
          // running with cascades disabled, so they may already contain orphans.
          // Turning enforcement on over a dirty database makes later writes fail
          // on constraints the user never violated. So: sweep first, enable
          // second. The sweep is idempotent and cheap once clean.
          await _sweepOrphans();
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Delete rows whose parent is already gone.
  ///
  /// Runs with foreign_keys still OFF (see beforeOpen) — which is what makes the
  /// deletes possible at all. Child-first order, so we never strand a row we
  /// were about to remove anyway. Wrapped in a transaction: interrupted halfway
  /// it rolls back, and the next launch simply sweeps again.
  Future<void> _sweepOrphans() async {
    await transaction(() async {
      await customStatement(
          'DELETE FROM transcripts WHERE meeting_id NOT IN (SELECT id FROM meetings)');
      await customStatement(
          'DELETE FROM transcript_segments WHERE meeting_id NOT IN (SELECT id FROM meetings)');
      await customStatement(
          'DELETE FROM summaries WHERE meeting_id NOT IN (SELECT id FROM meetings)');
      await customStatement(
          'DELETE FROM bookmarks WHERE meeting_id NOT IN (SELECT id FROM meetings)');
      await customStatement(
          'DELETE FROM action_items WHERE meeting_id NOT IN (SELECT id FROM meetings)');
      await customStatement(
          'DELETE FROM meeting_folders WHERE meeting_id NOT IN (SELECT id FROM meetings)');
      await customStatement(
          'DELETE FROM meeting_tags WHERE meeting_id NOT IN (SELECT id FROM meetings)');
      await customStatement(
          'DELETE FROM meeting_folders WHERE folder_id NOT IN (SELECT id FROM folders)');
      // segment_embeddings hangs off BOTH a segment and a meeting.
      await customStatement(
          'DELETE FROM segment_embeddings WHERE meeting_id NOT IN (SELECT id FROM meetings)');
      await customStatement(
          'DELETE FROM segment_embeddings WHERE segment_id NOT IN (SELECT id FROM transcript_segments)');
    });
  }

  // -------------------------------------------------------------------------
  // High-level queries used by services
  // -------------------------------------------------------------------------

  Future<List<Meeting>> recentMeetings({int limit = 100}) {
    return (select(meetings)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Stream<List<Meeting>> watchRecentMeetings({int limit = 100}) {
    return (select(meetings)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<Meeting?> meetingById(String id) {
    return (select(meetings)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Transcript?> transcriptFor(String meetingId) {
    return (select(transcripts)..where((t) => t.meetingId.equals(meetingId)))
        .getSingleOrNull();
  }

  Future<List<TranscriptSegment>> segmentsFor(String meetingId) {
    return (select(transcriptSegments)
          ..where((t) => t.meetingId.equals(meetingId))
          ..orderBy([(t) => OrderingTerm.asc(t.startMs)]))
        .get();
  }

  Stream<List<TranscriptSegment>> watchSegmentsFor(String meetingId) {
    return (select(transcriptSegments)
          ..where((t) => t.meetingId.equals(meetingId))
          ..orderBy([(t) => OrderingTerm.asc(t.startMs)]))
        .watch();
  }

  Future<List<Summary>> summariesFor(String meetingId) {
    return (select(summaries)
          ..where((t) => t.meetingId.equals(meetingId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<Bookmark>> bookmarksFor(String meetingId) {
    return (select(bookmarks)
          ..where((t) => t.meetingId.equals(meetingId))
          ..orderBy([(t) => OrderingTerm.asc(t.atMs)]))
        .get();
  }

  /// Aggregate stats for the Settings tier card.
  Future<({int total, int thisMonth, int totalMs})> meetingStats() async {
    final all = await select(meetings).get();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    var thisMonth = 0;
    var totalMs = 0;
    for (final m in all) {
      totalMs += m.durationMs;
      if (!m.createdAt.isBefore(monthStart)) thisMonth++;
    }
    return (total: all.length, thisMonth: thisMonth, totalMs: totalMs);
  }

  /// FTS5 search across transcripts + titles. Returns meeting IDs.
  Future<List<String>> searchMeetingIds(String query, {int limit = 50}) async {
    if (query.trim().isEmpty) return const [];
    final rows = await customSelect(
      'SELECT meeting_id FROM meeting_search WHERE meeting_search MATCH ? LIMIT ?',
      variables: [Variable<String>(query), Variable<int>(limit)],
    ).get();
    return rows.map((r) => r.read<String>('meeting_id')).toList();
  }
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'recap.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
