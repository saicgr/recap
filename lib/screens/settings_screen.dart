import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import '../billing/tier.dart';
import '../main.dart';
import '../services/sherpa_diarizer.dart';
import '../services/summarizer/gemma_downloader.dart';
import '../services/transcriber.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';
import 'about_screen.dart';
import 'action_items_screen.dart';
import 'app_lock_settings_screen.dart';
import 'backup_screen.dart';
import 'byok_screen.dart';
import 'compare_screen.dart';
import 'help_screen.dart';
import 'insights_screen.dart';
import 'paywall_screen.dart';
import 'privacy_dashboard_screen.dart';
import 'storage_screen.dart';
import 'topup_screen.dart';
import 'voice_enrollment_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    transcriber.addListener(_rebuild);
    themeController.addListener(_rebuild);
    diarizer.addListener(_rebuild);
    gemmaDownloader.addListener(_rebuild);
  }

  @override
  void dispose() {
    transcriber.removeListener(_rebuild);
    themeController.removeListener(_rebuild);
    diarizer.removeListener(_rebuild);
    gemmaDownloader.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Scaffold(
      backgroundColor: t.bgSubtle,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              leading: IconBtn(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Settings',
                style: RT.subtitle.copyWith(color: t.textPrimary),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 32),
                children: [
                  _tierCard(t),
                  _appearanceGroup(t),
                  _summariesGroup(t),
                  _transcriptionGroup(t),
                  _organizationGroup(t),
                  _privacyGroup(t),
                  _backupGroup(t),
                  _aboutGroup(t),
                  if (kDebugMode) _debugGroup(t),
                  _footnote(t),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appearanceGroup(RecapTheme t) {
    return SettingsGroup(
      label: 'Appearance',
      children: [
        SettingsRow(
          icon: Icons.palette_outlined,
          accentIcon: true,
          title: 'Tweaks',
          value: _tweaksSummary(),
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: _openTweaks,
          last: true,
        ),
      ],
    );
  }

  String _tweaksSummary() {
    final mode = themeController.mode == RecapMode.dark ? 'Dark' : 'Light';
    final style = themeController.buttonStyle == RecapButtonStyle.glass
        ? 'Glass'
        : 'Flat';
    return '$mode · $style · ${themeController.accent.name}';
  }

  Future<void> _openTweaks() async {
    final t = RecapThemeScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _TweaksSheet(),
    );
    if (mounted) setState(() {});
  }

  // ─── Tier card ────────────────────────────────────────────────────────────

  Widget _tierCard(RecapTheme t) {
    final tier = entitlements.currentTier;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: t.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your plan',
                      style: RT.caption.copyWith(color: t.textMuted),
                    ),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: t.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: RT.caption.copyWith(color: t.accent),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Recap ${_capitalize(tier.name)}',
                      style: RT.title.copyWith(color: t.textPrimary),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        tier.priceUsd == 0
                            ? 'Free'
                            : '\$${tier.priceUsd} lifetime',
                        style: RT.bodySm.copyWith(color: t.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FutureBuilder<({int total, int thisMonth, int totalMs})>(
                  future: db.meetingStats(),
                  builder: (ctx, snap) {
                    final s = snap.data ?? (total: 0, thisMonth: 0, totalMs: 0);
                    return Row(
                      children: [
                        _stat(t, 'Recordings', '${s.total}'),
                        const SizedBox(width: 24),
                        _stat(t, 'This month', '${s.thisMonth}'),
                        const SizedBox(width: 24),
                        _stat(t, 'Total time', _formatDuration(s.totalMs)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Btn(
                      label: 'Upgrade',
                      variant: BtnVariant.accentSoft,
                      size: BtnSize.sm,
                      trailing: Icons.arrow_forward,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaywallScreen(),
                        ),
                      ),
                    ),
                    if (tier.topUpsEnabled) ...[
                      const SizedBox(width: 8),
                      Btn(
                        label: 'Top up cloud',
                        variant: BtnVariant.ghost,
                        size: BtnSize.sm,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TopUpScreen(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(RecapTheme t, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
            letterSpacing: -0.2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: RT.caption.copyWith(color: t.textMuted),
        ),
      ],
    );
  }

  String _formatDuration(int ms) {
    final s = ms ~/ 1000;
    if (s < 60) return '${s}s';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  // ─── Summaries group ──────────────────────────────────────────────────────

  Widget _summariesGroup(RecapTheme t) {
    final tier = entitlements.currentTier;
    return SettingsGroup(
      label: 'Summaries',
      children: [
        SettingsRow(
          icon: Icons.auto_awesome,
          accentIcon: true,
          title: 'Summary engine',
          value: _summaryModeLabel(settings.summaryModeRaw),
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: _pickSummaryMode,
        ),
        SettingsRow(
          icon: Icons.download_outlined,
          title: 'On-device AI model',
          value: _gemmaStatusLabel(),
          trailing: gemmaDownloader.status == GemmaDownloadStatus.downloading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(t.accent),
                  ),
                )
              : gemmaDownloader.status == GemmaDownloadStatus.failed
              ? Icon(Icons.refresh, color: t.recordRed, size: 18)
              : Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: _onGemmaTap,
        ),
        if (tier == Tier.power)
          SettingsRow(
            icon: Icons.vpn_key_outlined,
            title: 'Bring your own key',
            value: 'Not set',
            trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ByokScreen()),
            ),
          ),
        SettingsRow(
          icon: Icons.cloud_outlined,
          title: 'Worker URL',
          value: settings.proxyUrl.isEmpty
              ? 'Not set'
              : Uri.parse(settings.proxyUrl).host,
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: _editWorkerUrl,
          last: true,
        ),
      ],
    );
  }

  // ─── Transcription group ──────────────────────────────────────────────────

  Widget _transcriptionGroup(RecapTheme t) {
    return SettingsGroup(
      label: 'Transcription',
      children: [
        SettingsRow(
          icon: Icons.memory,
          title: 'Model',
          value: _modelStatusLabel(),
          trailing: transcriber.status == TranscriberStatus.downloading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(t.accent),
                  ),
                )
              : transcriber.status == TranscriberStatus.failed
              ? Icon(Icons.refresh, color: t.recordRed, size: 18)
              : Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: _pickModel,
        ),
        SettingsRow(
          icon: Icons.language,
          title: 'Language',
          value: settings.audioLanguage == 'auto' ? 'Auto-detect' : 'English',
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: _pickLanguage,
        ),
        SettingsRow(
          icon: Icons.record_voice_over_outlined,
          title: 'Speaker model',
          value: _speakerModelStatusLabel(),
          trailing: diarizer.status == SherpaDiarizerStatus.downloading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(t.accent),
                  ),
                )
              : diarizer.status == SherpaDiarizerStatus.failed
              ? Icon(Icons.refresh, color: t.recordRed, size: 18)
              : Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: _onSpeakerModelTap,
        ),
        SettingsRow(
          icon: Icons.timer_outlined,
          title: 'Show timestamps',
          trailing: RecapToggle(
            value: settings.showTimestamps,
            onChanged: (v) async {
              await settings.setShowTimestamps(v);
              if (mounted) setState(() {});
            },
          ),
        ),
        SettingsRow(
          icon: Icons.delete_outline,
          title: 'Auto-delete after ${settings.autoDeleteDays} days',
          trailing: RecapToggle(
            value: settings.autoDeleteOldRecordings,
            onChanged: (v) async {
              await settings.setAutoDelete(v);
              if (mounted) setState(() {});
            },
          ),
          last: true,
        ),
      ],
    );
  }

  Widget _organizationGroup(RecapTheme t) {
    return SettingsGroup(
      label: 'Organization',
      children: [
        SettingsRow(
          icon: Icons.task_alt_outlined,
          title: 'Action items',
          value: 'Tap to view',
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ActionItemsScreen()),
          ),
        ),
        SettingsRow(
          icon: Icons.record_voice_over_outlined,
          title: 'Voice enrollment',
          value: 'Auto-label known speakers',
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VoiceEnrollmentScreen()),
          ),
        ),
        SettingsRow(
          icon: Icons.insights_outlined,
          title: 'Insights',
          value: 'Talk time, weekly summary — local only',
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InsightsScreen()),
          ),
          last: true,
        ),
      ],
    );
  }

  Widget _privacyGroup(RecapTheme t) {
    return SettingsGroup(
      label: 'Privacy & security',
      children: [
        SettingsRow(
          icon: Icons.shield_outlined,
          title: 'Privacy dashboard',
          value: 'What lives on-device · what goes over the network',
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyDashboardScreen()),
          ),
        ),
        SettingsRow(
          icon: Icons.lock_outline,
          title: 'App Lock',
          value: 'Biometric · timeout',
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppLockSettingsScreen()),
          ),
          last: true,
        ),
      ],
    );
  }

  Widget _backupGroup(RecapTheme t) {
    return SettingsGroup(
      label: 'Backup',
      children: [
        SettingsRow(
          icon: Icons.backup_outlined,
          title: 'Backup & restore',
          value: 'Export everything · user-controlled · encrypted',
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BackupScreen()),
          ),
          last: true,
        ),
      ],
    );
  }

  // ─── About ────────────────────────────────────────────────────────────────

  Widget _aboutGroup(RecapTheme t) {
    return SettingsGroup(
      label: 'About',
      children: [
        SettingsRow(
          icon: Icons.auto_awesome_outlined,
          accentIcon: true,
          title: 'What makes Recap different',
          value: 'No account · any phone · on-device',
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CompareScreen()),
          ),
        ),
        SettingsRow(
          icon: Icons.help_outline,
          title: 'Help & FAQ',
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpScreen()),
          ),
        ),
        SettingsRow(
          icon: Icons.storage_outlined,
          title: 'Storage',
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StorageScreen()),
          ),
        ),
        SettingsRow(
          icon: Icons.info_outline,
          title: 'About Recap',
          value: '0.1.0',
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutScreen()),
          ),
          last: true,
        ),
      ],
    );
  }

  Widget _debugGroup(RecapTheme t) {
    return SettingsGroup(
      label: 'Debug',
      children: [
        SettingsRow(
          icon: Icons.swap_horiz,
          accentIcon: true,
          title: 'Switch tier',
          value: _capitalize(entitlements.currentTier.name),
          trailing: Icon(Icons.chevron_right, color: t.textMuted, size: 18),
          onTap: _pickTier,
          last: true,
        ),
      ],
    );
  }

  Future<void> _pickTier() async {
    final t = RecapThemeScope.of(context);
    final pick = await showModalBottomSheet<Tier>(
      context: context,
      backgroundColor: t.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Debug: switch tier',
                  style: RT.title.copyWith(color: t.textPrimary),
                ),
              ),
              for (final tier in Tier.values)
                ListTile(
                  onTap: () => Navigator.pop(ctx, tier),
                  title: Text(
                    _capitalize(tier.name),
                    style: RT.body.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    _tierDesc(tier),
                    style: RT.bodySm.copyWith(color: t.textMuted),
                  ),
                  trailing: entitlements.currentTier == tier
                      ? Icon(Icons.check, color: t.accent)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
    if (pick != null) {
      await entitlements.setTier(pick);
      if (mounted) setState(() {});
    }
  }

  String _tierDesc(Tier tier) {
    // Recording is unlimited on every tier; the only quota worth surfacing
    // here is the cloud-summary allowance.
    final parts = <String>['\$${tier.priceUsd}', 'unlimited recording'];
    if (tier.cloudSummariesEnabled) {
      parts.add(
        tier.byok
            ? 'BYOK cloud'
            : '${tier.cloudSummariesPerMonth ?? 0} cloud/mo',
      );
    } else {
      parts.add('no cloud');
    }
    return parts.join(' · ');
  }

  Widget _footnote(RecapTheme t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
      child: Text(
        "Recap doesn't run analytics or telemetry. Your audio never leaves your device unless you turn on cloud summaries.",
        textAlign: TextAlign.center,
        style: RT.bodySm.copyWith(color: t.textMuted),
      ),
    );
  }

  // ─── Bottom-sheet pickers ─────────────────────────────────────────────────

  String _summaryModeLabel(String raw) => switch (raw) {
    'cloud' => 'Cloud (Gemini)',
    'onDevice' => 'On-device',
    _ => 'Auto',
  };

  String _modelStatusLabel() {
    final model = transcriber.model.modelName;
    switch (transcriber.status) {
      case TranscriberStatus.uninitialized:
        return 'Loading';
      case TranscriberStatus.downloading:
        final p = transcriber.downloadProgress;
        final pct = p == null ? '' : ' · ${(p * 100).toStringAsFixed(0)}%';
        final received = _formatBytes(transcriber.bytesReceived);
        final total = transcriber.bytesTotal > 0
            ? _formatBytes(transcriber.bytesTotal)
            : '~';
        return 'Downloading $model$pct · $received / $total';
      case TranscriberStatus.ready:
        return 'Whisper $model';
      case TranscriberStatus.failed:
        return 'Failed — retry';
    }
  }

  String _speakerModelStatusLabel() {
    switch (diarizer.status) {
      case SherpaDiarizerStatus.uninitialized:
        return 'Tap to download · ~80 MB';
      case SherpaDiarizerStatus.downloading:
        final p = diarizer.downloadProgress;
        final pct = p == null ? '' : ' · ${(p * 100).toStringAsFixed(0)}%';
        final received = _formatBytes(diarizer.bytesReceived);
        final total = diarizer.bytesTotal > 0
            ? _formatBytes(diarizer.bytesTotal)
            : '~';
        return 'Downloading$pct · $received / $total';
      case SherpaDiarizerStatus.ready:
        return 'Pyannote + WeSpeaker · ready';
      case SherpaDiarizerStatus.failed:
        return 'Failed — tap to retry';
    }
  }

  void _onSpeakerModelTap() {
    if (diarizer.status == SherpaDiarizerStatus.downloading) return;
    diarizer.warmUp();
  }

  String _gemmaStatusLabel() {
    final variant = entitlements.currentTier.gemmaVariant;
    final sizeGb = (variant.approxBytes / (1000 * 1000 * 1000)).toStringAsFixed(
      1,
    );
    switch (gemmaDownloader.status) {
      case GemmaDownloadStatus.unknown:
        return 'Checking…';
      case GemmaDownloadStatus.notInstalled:
        return 'Tap to download · ${variant.displayName} · ~$sizeGb GB';
      case GemmaDownloadStatus.downloading:
        final pct = (gemmaDownloader.progress * 100).toStringAsFixed(0);
        return 'Downloading ${variant.displayName} · $pct%';
      case GemmaDownloadStatus.installed:
        return '${variant.displayName} · ready';
      case GemmaDownloadStatus.failed:
        return 'Failed — tap to retry';
    }
  }

  Future<void> _onGemmaTap() async {
    if (gemmaDownloader.status == GemmaDownloadStatus.downloading) return;
    final t = RecapThemeScope.of(context);
    final builtinAvailable = await builtinAiBackend.isAvailable();
    if (!mounted) return;
    final current = settings.effectiveGemmaVariant(
      entitlements.currentTier.gemmaVariant,
    );
    final picked = await showModalBottomSheet<GemmaVariant>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'On-device summary model',
                  style: RT.title.copyWith(color: t.textPrimary),
                ),
              ),
              if (builtinAvailable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Your device can use Gemini Nano / Apple Intelligence — '
                    'used automatically, no download. Pick a Gemma below as the '
                    'offline fallback.',
                    style: RT.body.copyWith(color: t.textMuted),
                  ),
                ),
              for (final v in GemmaVariant.values)
                ListTile(
                  onTap: () => Navigator.pop(ctx, v),
                  title: Text(
                    v.displayName,
                    style: RT.body.copyWith(color: t.textPrimary),
                  ),
                  subtitle: Text(
                    v == GemmaVariant.e2b
                        ? '~2.4 GB · runs on almost any phone'
                        : '~4.3 GB · sharper summaries, best for long meetings; '
                              'needs ~6 GB RAM',
                    style: RT.body.copyWith(color: t.textMuted),
                  ),
                  trailing: current == v
                      ? Icon(Icons.check, color: t.accent, size: 18)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await settings.setGemmaVariant(picked);
    gemmaDownloader.updateUrl(picked.defaultUrl);
    gemmaDownloader.warmUp();
  }

  String _formatBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(b < 10 * 1024 * 1024 ? 1 : 0)} MB';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Future<void> _pickModel() async {
    final t = RecapThemeScope.of(context);
    final pick = await showModalBottomSheet<WhisperModel>(
      context: context,
      backgroundColor: t.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = <(WhisperModel, String, String)>[
          (
            WhisperModel.tinyEn,
            'Tiny · English',
            '~75 MB · fastest, lower accuracy',
          ),
          (WhisperModel.baseEn, 'Base · English', '~140 MB · balanced'),
          (WhisperModel.smallEn, 'Small · English', '~466 MB · most accurate'),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(
                    'Transcription model',
                    style: RT.title.copyWith(color: t.textPrimary),
                  ),
                ),
                for (final (model, name, sub) in options)
                  ListTile(
                    onTap: () => Navigator.pop(ctx, model),
                    title: Text(
                      name,
                      style: RT.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      sub,
                      style: RT.bodySm.copyWith(color: t.textMuted),
                    ),
                    trailing: transcriber.model == model
                        ? Icon(Icons.check, color: t.accent)
                        : null,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(
                    'Switching downloads the new model the next time you record. The previous model stays on disk until you change again.',
                    style: RT.bodySm.copyWith(color: t.textMuted),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (pick != null && pick != transcriber.model) {
      await transcriber.setModel(pick);
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickSummaryMode() async {
    final t = RecapThemeScope.of(context);
    final pick = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in ['auto', 'onDevice', 'cloud'])
                ListTile(
                  title: Text(
                    _summaryModeLabel(mode),
                    style: RT.body.copyWith(color: t.textPrimary),
                  ),
                  trailing: settings.summaryModeRaw == mode
                      ? Icon(Icons.check, color: t.accent)
                      : null,
                  onTap: () => Navigator.pop(ctx, mode),
                ),
            ],
          ),
        ),
      ),
    );
    if (pick != null) {
      await settings.setSummaryMode(pick);
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickLanguage() async {
    final t = RecapThemeScope.of(context);
    final pick = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in ['auto', 'en'])
              ListTile(
                title: Text(
                  v == 'auto' ? 'Auto-detect' : 'English',
                  style: RT.body.copyWith(color: t.textPrimary),
                ),
                trailing: settings.audioLanguage == v
                    ? Icon(Icons.check, color: t.accent)
                    : null,
                onTap: () => Navigator.pop(ctx, v),
              ),
          ],
        ),
      ),
    );
    if (pick != null) {
      await settings.setAudioLanguage(pick);
      if (mounted) setState(() {});
    }
  }

  Future<void> _editWorkerUrl() async {
    final t = RecapThemeScope.of(context);
    final controller = TextEditingController(text: settings.proxyUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text(
          'Cloudflare Worker URL',
          style: RT.subtitle.copyWith(color: t.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: t.textPrimary),
          decoration: InputDecoration(
            hintText: 'https://…',
            hintStyle: TextStyle(color: t.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: t.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: t.accent),
            ),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: t.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('Save', style: TextStyle(color: t.accent)),
          ),
        ],
      ),
    );
    if (url != null) {
      await settings.setProxyUrl(url);
      if (mounted) setState(() {});
    }
  }
}

/// The Tweaks bottom sheet (Theme · Buttons · Accent).
/// Listens to the global ThemeController so previews update live as the user
/// taps options.
class _TweaksSheet extends StatefulWidget {
  const _TweaksSheet();

  @override
  State<_TweaksSheet> createState() => _TweaksSheetState();
}

class _TweaksSheetState extends State<_TweaksSheet> {
  @override
  void initState() {
    super.initState();
    themeController.addListener(_rebuild);
  }

  @override
  void dispose() {
    themeController.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 10, 0, 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: t.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 0, 16),
              child: Row(
                children: [
                  Text(
                    'Tweaks',
                    style: RT.title.copyWith(color: t.textPrimary),
                  ),
                  const Spacer(),
                  IconBtn(
                    icon: Icons.close,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            _section(t, 'THEME'),
            const SizedBox(height: 8),
            Text(
              'Mode',
              style: RT.body.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Segmented<RecapMode>(
              value: themeController.mode,
              onChanged: (v) => themeController.setMode(v),
              options: const [
                (value: RecapMode.light, label: 'Light'),
                (value: RecapMode.dark, label: 'Dark'),
              ],
            ),
            const SizedBox(height: 20),
            _section(t, 'BUTTONS'),
            const SizedBox(height: 8),
            Text(
              'Style',
              style: RT.body.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Segmented<RecapButtonStyle>(
              value: themeController.buttonStyle,
              onChanged: (v) => themeController.setButtonStyle(v),
              options: const [
                (value: RecapButtonStyle.flat, label: 'Flat'),
                (value: RecapButtonStyle.glass, label: 'Glass'),
              ],
            ),
            const SizedBox(height: 20),
            _section(t, 'ACCENT'),
            const SizedBox(height: 8),
            Text(
              'Color',
              style: RT.body.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            AccentSwatches(
              value: themeController.accent,
              onChanged: (a) => themeController.setAccent(a),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _section(RecapTheme t, String label) =>
      Text(label, style: RT.caption.copyWith(color: t.textMuted));
}
