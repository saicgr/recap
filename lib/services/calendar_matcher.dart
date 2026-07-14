import 'package:device_calendar/device_calendar.dart' as dc;

/// Calendar integration (D11.1). At record-start, query the user's
/// calendars for events within ±5 min of `now`. If exactly one matches:
/// pre-fill the meeting title + propose attendees as speaker labels.
/// If multiple: surface a picker chip-bar on the recording screen.
///
/// **Permission UX:** request on first record (not app launch — minimum-
/// permission ethos). Decline gracefully — auto-title falls back to
/// "Meeting on {date} {time}".
class CalendarMatch {
  final String? eventTitle;
  final List<String> attendees;
  final DateTime? eventStart;
  final String? eventId;
  const CalendarMatch({
    required this.eventTitle,
    required this.attendees,
    required this.eventStart,
    required this.eventId,
  });

  bool get hasMatch => eventTitle != null;
}

/// One upcoming event, for the home-screen strip.
class UpcomingEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final List<String> attendees;

  const UpcomingEvent({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.attendees = const [],
  });

  bool get isNow {
    final now = DateTime.now();
    return start.isBefore(now) && (end?.isAfter(now) ?? false);
  }

  /// Minutes until start; negative once it has begun.
  int get minutesAway => start.difference(DateTime.now()).inMinutes;
}

class CalendarMatcher {
  final dc.DeviceCalendarPlugin _plugin = dc.DeviceCalendarPlugin();

  /// Returns the best-matching calendar event for [now], or an empty match
  /// if permission is denied / no event in range / multiple candidates.
  Future<CalendarMatch> matchNow({DateTime? now}) async {
    final t = now ?? DateTime.now();
    try {
      final permissions = await _plugin.hasPermissions();
      if (permissions.data != true) {
        final granted = await _plugin.requestPermissions();
        if (granted.data != true) return _empty();
      }
      final calendars = await _plugin.retrieveCalendars();
      final calData = calendars.data;
      if (calData == null || calData.isEmpty) return _empty();

      final params = dc.RetrieveEventsParams(
        startDate: t.subtract(const Duration(minutes: 5)),
        endDate: t.add(const Duration(minutes: 5)),
      );

      final matches = <dc.Event>[];
      for (final cal in calData) {
        // Do NOT skip read-only calendars. Shared and subscribed corporate
        // calendars are usually read-only, and that is precisely where work
        // meetings live — filtering them out meant auto-titling silently missed
        // the meetings it exists to name. Read-only only matters if we WRITE.
        if (cal.id == null) continue;
        final events = await _plugin.retrieveEvents(cal.id, params);
        final list = events.data;
        if (list == null) continue;
        for (final e in list) {
          if (e.title == null || e.title!.trim().isEmpty) continue;
          // Skip all-day events — they're usually OOO/birthdays, not meetings.
          if (e.allDay == true) continue;
          matches.add(e);
        }
      }
      if (matches.isEmpty) return _empty();
      // Single closest event by start time.
      matches.sort((a, b) {
        final aDist =
            (a.start?.millisecondsSinceEpoch ?? 0) - t.millisecondsSinceEpoch;
        final bDist =
            (b.start?.millisecondsSinceEpoch ?? 0) - t.millisecondsSinceEpoch;
        return aDist.abs().compareTo(bDist.abs());
      });
      final best = matches.first;
      final attendees = (best.attendees ?? [])
          .where((a) => a?.name != null && a!.name!.trim().isNotEmpty)
          .map((a) => a!.name!.trim())
          .toList();
      return CalendarMatch(
        eventTitle: best.title,
        attendees: attendees,
        eventStart: best.start?.toLocal(),
        eventId: best.eventId,
      );
    } catch (_) {
      return _empty();
    }
  }

  /// Events starting within [window] from now, soonest first.
  ///
  /// Feeds the home-screen "coming up" strip. Called on screen open and on app
  /// resume — never on a timer. A background poll of the calendar would be a
  /// background wake-up, and the Karpathy invariants say the app does work only
  /// when the user asks.
  ///
  /// Does NOT request permission: the strip is a nice-to-have, and a permission
  /// prompt fired by merely opening the home screen is hostile. It shows only
  /// if permission has already been granted (i.e. the user recorded once).
  Future<List<UpcomingEvent>> listUpcoming({
    Duration window = const Duration(hours: 24),
    DateTime? now,
    int limit = 10,
  }) async {
    final t = now ?? DateTime.now();
    try {
      final permissions = await _plugin.hasPermissions();
      if (permissions.data != true) return const [];

      final calendars = await _plugin.retrieveCalendars();
      final calData = calendars.data;
      if (calData == null || calData.isEmpty) return const [];

      // Start slightly in the past so a meeting already underway still appears —
      // that is the one you are most likely to want to record.
      final params = dc.RetrieveEventsParams(
        startDate: t.subtract(const Duration(minutes: 30)),
        endDate: t.add(window),
      );

      final out = <UpcomingEvent>[];
      for (final cal in calData) {
        // Read-only calendars included on purpose — see matchNow().
        if (cal.id == null) continue;
        final events = await _plugin.retrieveEvents(cal.id, params);
        for (final e in events.data ?? const <dc.Event>[]) {
          final title = e.title?.trim();
          final start = e.start?.toLocal();
          if (title == null || title.isEmpty || start == null) continue;
          if (e.allDay == true) continue; // OOO / birthdays, not meetings
          if (e.eventId == null) continue;
          out.add(UpcomingEvent(
            id: e.eventId!,
            title: title,
            start: start,
            end: e.end?.toLocal(),
            attendees: (e.attendees ?? [])
                .where((a) => a?.name != null && a!.name!.trim().isNotEmpty)
                .map((a) => a!.name!.trim())
                .toList(),
          ));
        }
      }

      out.sort((a, b) => a.start.compareTo(b.start));
      // De-dupe: the same event often appears in several calendars.
      final seen = <String>{};
      final deduped = <UpcomingEvent>[];
      for (final e in out) {
        if (!seen.add('${e.title}|${e.start.millisecondsSinceEpoch}')) continue;
        deduped.add(e);
        if (deduped.length >= limit) break;
      }
      return deduped;
    } catch (_) {
      // A calendar failure must never take down the home screen.
      return const [];
    }
  }

  CalendarMatch _empty() => const CalendarMatch(
        eventTitle: null,
        attendees: [],
        eventStart: null,
        eventId: null,
      );
}
