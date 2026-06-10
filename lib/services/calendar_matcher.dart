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
        if (cal.isReadOnly == true) continue;
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
            (a.start?.millisecondsSinceEpoch ?? 0) -
                t.millisecondsSinceEpoch;
        final bDist =
            (b.start?.millisecondsSinceEpoch ?? 0) -
                t.millisecondsSinceEpoch;
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

  CalendarMatch _empty() => const CalendarMatch(
        eventTitle: null,
        attendees: [],
        eventStart: null,
        eventId: null,
      );
}
