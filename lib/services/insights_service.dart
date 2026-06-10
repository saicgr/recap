import '../main.dart';

/// Local-only analytics for the user (D14.10). Privacy-preserving: every
/// computation happens on-device, never reported anywhere. The user opens
/// the Insights tab; we compute over their own meetings + transcripts.
///
/// Karpathy invariant: this is the *user's* analytics about *their* data,
/// surfaced *to* the user. Never sent anywhere. Opt-in via Settings →
/// Analytics toggle (off by default to honor the "no telemetry" rule).
class InsightsService {
  Future<WeeklySummary> weeklySummary({DateTime? endOfWeek}) async {
    final end = endOfWeek ?? DateTime.now();
    final start = end.subtract(const Duration(days: 7));
    final meetings = await db.select(db.meetings).get();
    final inRange = meetings
        .where((m) =>
            m.createdAt.isAfter(start) && m.createdAt.isBefore(end))
        .toList();
    final totalMs = inRange.fold<int>(0, (sum, m) => sum + m.durationMs);
    return WeeklySummary(
      meetingCount: inRange.length,
      totalDuration: Duration(milliseconds: totalMs),
      startOfWeek: start,
      endOfWeek: end,
    );
  }

  /// Talk-time per speaker for a given meeting. Sums segment durations by
  /// `speakerLabel`. Used in the per-meeting talk-time chart.
  Future<Map<String, Duration>> talkTimeByMeeting(String meetingId) async {
    final segs = await db.segmentsFor(meetingId);
    final out = <String, int>{};
    for (final s in segs) {
      final lbl = s.speakerLabel ?? 'Unknown';
      out[lbl] = (out[lbl] ?? 0) + (s.endMs - s.startMs);
    }
    return out.map((k, v) => MapEntry(k, Duration(milliseconds: v)));
  }

  /// Words per minute by speaker — flags the fast / slow talker. Useful for
  /// "are you dominating the meeting?" self-awareness.
  Future<Map<String, double>> wordsPerMinuteByMeeting(String meetingId) async {
    final segs = await db.segmentsFor(meetingId);
    final words = <String, int>{};
    final ms = <String, int>{};
    for (final s in segs) {
      final lbl = s.speakerLabel ?? 'Unknown';
      final wc = s.body.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      words[lbl] = (words[lbl] ?? 0) + wc;
      ms[lbl] = (ms[lbl] ?? 0) + (s.endMs - s.startMs);
    }
    final out = <String, double>{};
    words.forEach((k, w) {
      final t = ms[k] ?? 0;
      if (t > 0) {
        out[k] = w / (t / 60000.0);
      }
    });
    return out;
  }
}

class WeeklySummary {
  final int meetingCount;
  final Duration totalDuration;
  final DateTime startOfWeek;
  final DateTime endOfWeek;
  const WeeklySummary({
    required this.meetingCount,
    required this.totalDuration,
    required this.startOfWeek,
    required this.endOfWeek,
  });
}
