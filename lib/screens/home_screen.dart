import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../billing/entitlement_service.dart';
import '../data/database.dart';
import '../main.dart';
import '../services/calendar_matcher.dart';
import '../services/transcriber.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';
import '../widgets/folder_drawer.dart';
import 'chat_screen.dart';
import 'import_screen.dart';
import 'paywall_screen.dart';
import 'recording_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'transcript_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  TierUsage? _usage;
  StreamSubscription<TierUsage>? _usageSub;

  /// null == "All recordings". Otherwise the folder we are filtered to.
  Folder? _folder;

  List<UpcomingEvent> _upcoming = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    transcriber.addListener(_onTranscriber);
    _usageSub = entitlements.watchUsage().listen((u) {
      if (mounted) setState(() => _usage = u);
    });
    _loadUpcoming();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    transcriber.removeListener(_onTranscriber);
    _usageSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh on resume — never on a timer. Polling the calendar in the
    // background would be a background wake-up; the app does work when the user
    // asks, not on a schedule.
    if (state == AppLifecycleState.resumed) _loadUpcoming();
  }

  Future<void> _loadUpcoming() async {
    final events = await calendarMatcher.listUpcoming(
      window: Duration(hours: settings.upcomingWindowHours),
    );
    if (mounted) setState(() => _upcoming = events);
  }

  void _onTranscriber() {
    if (mounted) setState(() {});
  }

  Future<void> _startRecording() async {
    final decision = await entitlements.decideStartRecording();
    if (!mounted) return;
    switch (decision) {
      case AllowRecording():
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecordingScreen()),
        );
    }
  }

  // _showBlockedSheet was the daily/monthly recording-cap upsell. Removed
  // when we dropped recording quotas — recording is now unlimited on every
  // tier. The cloud-summary upsell (BlockedCloudQuota path) lives on the
  // Summary tab in TranscriptScreen instead.

  void _openSettings() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );

  void _openImport() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ImportScreen()),
  );

  /// Chat over the whole corpus. On-device, so every tier gets it — including
  /// Privacy, where Granola's cloud-only chat simply cannot go.
  void _openChat() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ChatScreen()),
  );

  void _openSearch() {
    if (!entitlements.currentTier.crossMeetingSearch) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
            reason: 'Cross-meeting search is a Pro feature.',
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  Map<String, List<Meeting>> _group(List<Meeting> meetings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final out = <String, List<Meeting>>{};
    for (final m in meetings) {
      final c = m.createdAt;
      final day = DateTime(c.year, c.month, c.day);
      String section;
      if (day == today) {
        section = 'Today';
      } else if (day == yesterday) {
        section = 'Yesterday';
      } else if (day.isAfter(weekStart) || day.isAtSameMomentAs(weekStart)) {
        section = 'This week';
      } else {
        section = 'Earlier';
      }
      (out[section] ??= []).add(m);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      // Granola's mobile app cannot do this: it shows "Folders will appear here
      // after they are synced", because its folders live on a server. Ours are
      // local-first, so they work offline and with no account.
      drawer: FolderDrawer(
        selected: _folder,
        onSelect: (f) {
          setState(() => _folder = f);
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: StreamBuilder<List<Meeting>>(
          // Single filter point: swap the source stream when a folder is picked.
          stream: _folder == null
              ? db.watchRecentMeetings(limit: 200)
              : folderService.watchMeetingsInFolder(_folder!.id),
          builder: (ctx, snap) {
            final meetings = snap.data ?? const [];
            // An empty FOLDER is not an empty APP — showing the first-run
            // illustration here would tell the user they have no recordings at
            // all, which is false and alarming.
            if (meetings.isEmpty && _folder != null) {
              return _emptyFolder(t);
            }
            if (meetings.isEmpty) return _empty(t);
            return _list(t, meetings);
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RecordFab(size: 64, onPressed: _startRecording),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _empty(RecapTheme t) {
    return Column(
      children: [
        TopBar(
          leading: Text(
            'Recap',
            style: RT.subtitle.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          trailing: [
            IconBtn(icon: Icons.file_upload_outlined, onPressed: _openImport),
            const SizedBox(width: 4),
            IconBtn(icon: Icons.settings_outlined, onPressed: _openSettings),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _quietIllustration(t),
                const SizedBox(height: 32),
                Text(
                  'No recordings yet',
                  style: RT.titleLg.copyWith(color: t.textPrimary),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap the button below to record your first meeting. Audio stays on your device.',
                  textAlign: TextAlign.center,
                  style: RT.bodyLg.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 13, color: t.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Fully offline · No account',
                      style: RT.label.copyWith(color: t.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _modelStatusInline(t),
              ],
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _quietIllustration(RecapTheme t) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 140.0 - i * 36,
              height: 140.0 - i * 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: t.border,
                  style: BorderStyle.solid,
                  width: 1,
                ),
              ),
            ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.bgSubtle,
            ),
            child: Icon(Icons.mic, size: 22, color: t.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _modelStatusInline(RecapTheme t) {
    final s = transcriber.status;
    if (s == TranscriberStatus.ready) return const SizedBox.shrink();

    String text;
    Color color;
    double? progress;
    switch (s) {
      case TranscriberStatus.uninitialized:
        text = 'Preparing on-device AI…';
        color = t.textMuted;
      case TranscriberStatus.downloading:
        final p = transcriber.downloadProgress;
        progress = p;
        final received = _formatBytes(transcriber.bytesReceived);
        final total = transcriber.bytesTotal > 0
            ? _formatBytes(transcriber.bytesTotal)
            : '~';
        final pct = p == null ? '' : '${(p * 100).toStringAsFixed(0)}% · ';
        text = 'Downloading Whisper · $pct$received / $total';
        color = t.accent;
      case TranscriberStatus.failed:
        text = 'Model download failed — open Settings to retry';
        color = t.recordRed;
      case TranscriberStatus.ready:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  value: s == TranscriberStatus.downloading ? progress : null,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(width: 8),
              Text(text, style: RT.label.copyWith(color: color)),
            ],
          ),
          if (s == TranscriberStatus.downloading) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: t.bgSubtle,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(b < 10 * 1024 * 1024 ? 1 : 0)} MB';
  }

  Widget _list(RecapTheme t, List<Meeting> meetings) {
    final totalMs = meetings.fold<int>(0, (a, m) => a + m.durationMs);
    final totalDuration = _formatDuration(totalMs);
    final grouped = _group(meetings);
    return Column(
      children: [
        TopBar(
          large: true,
          leading: Builder(
            builder: (ctx) => IconBtn(
              icon: Icons.folder_outlined,
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          trailing: [
            IconBtn(icon: Icons.auto_awesome_outlined, onPressed: _openChat),
            const SizedBox(width: 4),
            IconBtn(icon: Icons.search, onPressed: _openSearch),
            const SizedBox(width: 4),
            IconBtn(icon: Icons.file_upload_outlined, onPressed: _openImport),
            const SizedBox(width: 4),
            IconBtn(icon: Icons.settings_outlined, onPressed: _openSettings),
          ],
          largeTitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      _folder?.name ?? 'All recordings',
                      overflow: TextOverflow.ellipsis,
                      style: RT.titleLg.copyWith(color: t.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${meetings.length} · $totalDuration',
                      style: RT.label.copyWith(
                        color: t.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (_usage != null) _usageRow(t),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              // "Coming up" — only on the unfiltered list, where it belongs.
              if (_folder == null && _upcoming.isNotEmpty) _upcomingStrip(t),
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: RT.caption.copyWith(color: t.textMuted),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: t.surface,
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < entry.value.length; i++)
                        _meetingRow(
                          t,
                          entry.value[i],
                          last: i == entry.value.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _meetingRow(RecapTheme t, Meeting m, {required bool last}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TranscriptScreen(meeting: m)),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: last
                  ? BorderSide.none
                  : BorderSide(color: t.divider, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.bgSubtle,
                  border: Border.all(color: t.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.groups_outlined,
                  size: 16,
                  color: t.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RT.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          _formatDuration(m.durationMs),
                          style: RT.bodySm
                              .copyWith(color: t.textMuted)
                              .merge(RT.num),
                        ),
                        Text(
                          ' · ',
                          style: RT.bodySm.copyWith(color: t.textMuted),
                        ),
                        Text(
                          DateFormat('h:mm a').format(m.createdAt),
                          style: RT.bodySm.copyWith(color: t.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (m.status == MeetingStatus.processing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(t.accent),
                  ),
                )
              else if (m.status == MeetingStatus.failed)
                Icon(Icons.error_outline, color: t.recordRed, size: 16)
              else
                Icon(Icons.chevron_right, color: t.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  /// "Coming up" — the next calendar events, each one tap from being recorded.
  ///
  /// Granola's mobile list is short and fixed; ours honours
  /// settings.upcomingWindowHours. Shown only when calendar permission has
  /// already been granted — merely opening the home screen must never trigger a
  /// permission prompt.
  Widget _upcomingStrip(RecapTheme t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'COMING UP',
              style: RT.caption.copyWith(
                color: t.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final e in _upcoming.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SurfaceCard(
                onTap: _startRecording,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      e.isNow
                          ? Icons.radio_button_checked
                          : Icons.event_outlined,
                      size: 18,
                      color: e.isNow ? t.accent : t.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            overflow: TextOverflow.ellipsis,
                            style: RT.body.copyWith(color: t.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _whenLabel(e),
                            style: RT.caption.copyWith(color: t.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip2(label: e.isNow ? 'Record now' : 'Record'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _whenLabel(UpcomingEvent e) {
    if (e.isNow) return 'Happening now';
    final mins = e.minutesAway;
    if (mins < 1) return 'Starting now';
    if (mins < 60) return 'In $mins min';
    final time = DateFormat('EEE h:mm a').format(e.start);
    if (e.attendees.isEmpty) return time;
    return '$time · ${e.attendees.length} attendee'
        '${e.attendees.length == 1 ? '' : 's'}';
  }

  /// An empty FOLDER is not an empty APP. Showing the first-run illustration
  /// here would tell the user they have no recordings at all — false, and
  /// alarming.
  Widget _emptyFolder(RecapTheme t) {
    return Column(
      children: [
        TopBar(
          large: true,
          leading: Builder(
            builder: (ctx) => IconBtn(
              icon: Icons.folder_outlined,
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          trailing: [
            IconBtn(icon: Icons.search, onPressed: _openSearch),
            const SizedBox(width: 4),
            IconBtn(icon: Icons.settings_outlined, onPressed: _openSettings),
          ],
          largeTitle: Text(
            _folder?.name ?? '',
            overflow: TextOverflow.ellipsis,
            style: RT.titleLg.copyWith(color: t.textPrimary),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 40,
                    color: t.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nothing in this folder yet',
                    textAlign: TextAlign.center,
                    style: RT.subtitle.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open a recording and use "Move to folder" to file it here.',
                    textAlign: TextAlign.center,
                    style: RT.bodySm.copyWith(color: t.textMuted),
                  ),
                  const SizedBox(height: 20),
                  Btn(
                    label: 'Show all recordings',
                    onPressed: () => setState(() => _folder = null),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _usageRow(RecapTheme t) {
    // Recording caps removed on every tier — capture is unlimited. The only
    // remaining quota worth surfacing here is cloud-summary usage, and that
    // lives on the Summary tab. Keep this widget as a no-op shim so existing
    // call sites don't churn; future quota-chips (e.g. translation cloud
    // calls) can land here.
    return const SizedBox.shrink();
  }

  // ignore: unused_element
  Widget _usageChip(
    RecapTheme t, {
    required String label,
    required String current,
    required String cap,
    required double progress,
    required bool warn,
  }) {
    final color = warn ? t.recordRed : t.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.bgSubtle,
        border: Border.all(color: warn ? t.recordRed : t.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: RT.caption.copyWith(color: t.textMuted, letterSpacing: 0.8),
          ),
          const SizedBox(width: 8),
          Text(
            current,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            ' / $cap',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: t.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    final s = ms ~/ 1000;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m';
  }
}
