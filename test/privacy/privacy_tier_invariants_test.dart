import 'package:flutter_test/flutter_test.dart';
import 'package:recap/billing/tier.dart';

/// The Privacy tier ($69) sells exactly one promise: this build cannot reach
/// the network. CLAUDE.md calls it "verifiable in code" — these tests are what
/// make that claim mean something, rather than a comment someone can quietly
/// break.
///
/// It WAS broken: `privacy(exports: ExportTarget.values)` shipped Notion, Slack
/// and Google Docs — three third-party network calls — on the no-network SKU.
void main() {
  group('Privacy tier cannot reach the network', () {
    test('offers no cloud export destination', () {
      final cloud = Tier.privacy.availableExports
          .where((t) => t.isCloudDestination)
          .toList();
      expect(
        cloud,
        isEmpty,
        reason: 'Privacy tier is offering network exports: $cloud. '
            'The entire \$69 SKU is "this build cannot reach the network".',
      );
    });

    test('has cloud summaries, exports and transcription all disabled', () {
      expect(Tier.privacy.cloudSummariesEnabled, isFalse);
      expect(Tier.privacy.cloudExportsEnabled, isFalse);
      expect(Tier.privacy.cloudTranscriptionEnabled, isFalse);
      expect(Tier.privacy.byok, isFalse,
          reason: 'BYOK is a user-supplied key for a cloud provider');
    });

    test('still gets the full offline feature set it paid for', () {
      // Privacy is a premium SKU, not a crippled one — it must keep everything
      // that runs on-device. A regression that "fixes" the network leak by
      // gutting the tier would pass the tests above.
      expect(Tier.privacy.personaTemplates, SummaryStyle.values);
      expect(Tier.privacy.speakerLabels, isTrue);
      expect(Tier.privacy.crossMeetingSearch, isTrue);
      expect(Tier.privacy.autoSegment, isTrue);
      expect(Tier.privacy.watermark, isFalse);
      expect(Tier.privacy.availableExports, contains(ExportTarget.markdown));
      expect(
        Tier.privacy.availableExports,
        contains(ExportTarget.obsidian),
        reason: 'Obsidian is a local vault file write, not a network call',
      );
    });

    test('the filter holds even if the exports list is wrong', () {
      // Defence in depth: availableExports strips network destinations
      // regardless of what someone later writes into the raw exports list.
      // This is the guard that survives a careless edit.
      for (final t in Tier.values) {
        if (t.cloudExportsEnabled) continue;
        expect(
          t.availableExports.any((e) => e.isCloudDestination),
          isFalse,
          reason: '${t.name} has cloudExportsEnabled=false but leaks a '
              'network destination through availableExports',
        );
      }
    });
  });

  group('cloud destination classification', () {
    test('network destinations are classified as cloud', () {
      expect(ExportTarget.notion.isCloudDestination, isTrue);
      expect(ExportTarget.slack.isCloudDestination, isTrue);
      expect(ExportTarget.googleDocs.isCloudDestination, isTrue);
    });

    test('local destinations are not', () {
      expect(ExportTarget.copy.isCloudDestination, isFalse);
      expect(ExportTarget.shareSheet.isCloudDestination, isFalse);
      expect(ExportTarget.markdown.isCloudDestination, isFalse);
      expect(ExportTarget.appleNotes.isCloudDestination, isFalse);
      expect(ExportTarget.appleReminders.isCloudDestination, isFalse);
      expect(ExportTarget.obsidian.isCloudDestination, isFalse);
    });
  });

  group('on-device stays the default everywhere', () {
    test('no tier defaults to cloud transcription', () {
      // cloudTranscriptionEnabled gates AVAILABILITY, not the default. Turning
      // it on is an explicit user action (Settings -> Cloud transcription).
      // Nothing here should ever imply cloud is the default ASR path.
      expect(Tier.privacy.cloudTranscriptionEnabled, isFalse);
      for (final t in [Tier.free, Tier.pro, Tier.power]) {
        expect(t.cloudTranscriptionEnabled, isTrue,
            reason: '${t.name} may OFFER cloud transcription (still off by '
                'default in Settings)');
      }
    });
  });
}
