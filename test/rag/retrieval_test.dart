import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recap/data/database.dart';

void main() {
  group('escapeFts5', () {
    test('quotes each token so FTS5 operators cannot be injected', () {
      // Raw user text went straight into MATCH. A hyphen is the NOT operator in
      // FTS5, so searching `budget - Q3` threw a syntax error and the search
      // screen simply broke.
      expect(escapeFts5('budget - Q3'), '"budget" "-" "Q3"');
      expect(escapeFts5('pricing'), '"pricing"');
    });

    test('strips quotes rather than letting them unbalance the query', () {
      // O'Brien and "quoted phrase" both used to blow up the MATCH parser.
      expect(escapeFts5("O'Brien"), '"OBrien"');
      expect(escapeFts5('say "hello" now'), '"say" "hello" "now"');
    });

    test('bare boolean keywords are neutralised, not executed', () {
      // Unquoted, FTS5 reads these as operators; quoted they are literals.
      expect(escapeFts5('cats AND dogs'), '"cats" "AND" "dogs"');
      expect(escapeFts5('a NEAR b'), '"a" "NEAR" "b"');
    });

    test('empty / whitespace input yields an empty match (not a crash)', () {
      expect(escapeFts5(''), '');
      expect(escapeFts5('   '), '');
      expect(escapeFts5('""'), '');
    });
  });

  group('FTS index', () {
    late AppDb db;
    setUp(() => db = AppDb.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> seed(String id, String title, String body) async {
      await db.into(db.meetings).insert(MeetingsCompanion.insert(
            id: id,
            title: title,
            durationMs: const Value(1000),
            audioPath: '/tmp/$id.wav',
            createdAt: DateTime(2026, 7, 1),
            updatedAt: DateTime(2026, 7, 1),
            status: MeetingStatus.ready,
          ));
      await db.into(db.transcripts).insert(TranscriptsCompanion.insert(
            meetingId: id,
            body: body,
            modelId: 'whisper',
            processingMs: const Value(1),
            createdAt: DateTime(2026, 7, 1),
          ));
    }

    test('a query with punctuation searches instead of throwing', () async {
      await seed('m1', 'Pricing', 'we agreed on the budget for Q3');
      // Before escapeFts5 this threw an FTS5 syntax error.
      expect(await db.searchMeetingIds('budget - Q3'), isNotEmpty);
      expect(await db.searchMeetingIds("O'Brien"), isEmpty); // no crash
    });

    test('renaming a meeting re-indexes it', () async {
      await seed('m1', 'Old Title', 'quarterly numbers');
      expect(await db.searchMeetingIds('Old'), ['m1']);

      await (db.update(db.meetings)..where((m) => m.id.equals('m1')))
          .write(const MeetingsCompanion(title: Value('Renamed Title')));

      // There was no meetings_au trigger, so a renamed meeting stayed
      // searchable only under its OLD title, forever.
      expect(await db.searchMeetingIds('Renamed'), ['m1']);
      expect(await db.searchMeetingIds('Old'), isEmpty);
      // The body must survive the re-index.
      expect(await db.searchMeetingIds('quarterly'), ['m1']);
    });

    test('searchRanked returns higher scores for better matches', () async {
      await seed('m1', 'Budget', 'budget budget budget planning');
      await seed('m2', 'Other', 'we mentioned budget once');

      final ranked = await db.searchRanked('budget');
      expect(ranked.length, 2);
      // bm25 is negative-best; searchRanked flips it so higher == better.
      expect(ranked.first.score, greaterThanOrEqualTo(ranked.last.score));
    });
  });
}
