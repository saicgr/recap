import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../billing/entitlement_service.dart';
import '../data/database.dart';
import '../main.dart';
import '../services/transcriber.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  TierUsage? _usage;
  StreamSubscription<TierUsage>? _usageSub;

  @override
  void initState() {
    super.initState();
    transcriber.addListener(_onTranscriber);
    _usageSub = entitlements.watchUsage().listen((u) {
      if (mounted) setState(() => _usage = u);
    });
  }

  @override
  void dispose() {
    transcriber.removeListener(_onTranscriber);
    _usageSub?.cancel();
    super.dispose();
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
      body: SafeArea(
        child: StreamBuilder<List<Meeting>>(
          stream: db.watchRecentMeetings(limit: 200),
          builder: (ctx, snap) {
            final meetings = snap.data ?? const [];
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
          leading: Text('Recap',
              style: RT.subtitle.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              )),
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
                Text('No recordings yet',
                    style: RT.titleLg.copyWith(color: t.textPrimary)),
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
                    Text('Fully offline · No account',
                        style: RT.label.copyWith(color: t.textMuted)),
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
          leading: Text('Recap',
              style: RT.subtitle.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              )),
          trailing: [
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
                  Text('All recordings',
                      style: RT.titleLg.copyWith(color: t.textPrimary)),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${meetings.length} · $totalDuration',
                      style: RT.label.copyWith(
                          color: t.textMuted, fontWeight: FontWeight.w500),
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
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(entry.key.toUpperCase(),
                      style: RT.caption.copyWith(color: t.textMuted)),
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
                child: Icon(Icons.groups_outlined,
                    size: 16, color: t.textSecondary),
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
                        Text(' · ',
                            style: RT.bodySm.copyWith(color: t.textMuted)),
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
          Text(label,
              style: RT.caption.copyWith(
                color: t.textMuted,
                letterSpacing: 0.8,
              )),
          const SizedBox(width: 8),
          Text(current,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
          Text(' / $cap',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: t.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
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
