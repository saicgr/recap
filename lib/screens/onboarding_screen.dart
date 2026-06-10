import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

/// First-launch onboarding (D14.1 + D15.3). 5 screens. Designed so the user
/// can record within ~30s of first launch — bundled Whisper tiny.en +
/// native ASR mean zero downloads required for live captions on screen 5's
/// "Record now" CTA.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _wifiOnly = true;

  static const _pages = 5;

  Future<void> _markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed_v1', true);
    if (mounted) widget.onComplete();
  }

  Future<void> _kickOffBackgroundDownloads() async {
    // Heavy downloads (base.en, Gemma 4 E2B, Pyannote) start in background;
    // user can record immediately with bundled tiny.en + native ASR.
    transcriber.warmUp();
    gemmaDownloader.warmUp();
    diarizer.warmUp();
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _welcome(t),
                  _privacyPitch(t),
                  _permissions(t),
                  _downloadOptIn(t),
                  _startRecording(t),
                ],
              ),
            ),
            _dotsAndNext(t),
          ],
        ),
      ),
    );
  }

  Widget _welcome(RecapTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic, size: 88, color: t.accent),
          const SizedBox(height: 32),
          Text('Recap',
              style: RT.titleLg.copyWith(
                  color: t.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
            'Voice Memos, with on-device AI.',
            textAlign: TextAlign.center,
            style: RT.bodyLg.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Transcripts, speaker labels, summaries, viral clips — all on your phone. No account, no subscription, lifetime price.',
            textAlign: TextAlign.center,
            style: RT.body.copyWith(color: t.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _privacyPitch(RecapTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 48, color: t.accent),
          const SizedBox(height: 24),
          Text('Nothing leaves your phone',
              style: RT.title.copyWith(color: t.textPrimary)),
          const SizedBox(height: 16),
          _bullet(t, 'No account required. Ever.'),
          _bullet(t, 'No analytics. No telemetry.'),
          _bullet(t, 'No background pings — online only when you tap a cloud button.'),
          _bullet(t, 'Transcription runs locally (Whisper).'),
          _bullet(t, 'Summaries run locally (Gemma 4 / Apple Foundation Models).'),
          _bullet(t, 'Cloud summaries are opt-in only.'),
          _bullet(t,
              'On the Privacy tier, cloud is structurally disabled — verifiable by reading our code.'),
        ],
      ),
    );
  }

  Widget _bullet(RecapTheme t, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: t.positive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: RT.body.copyWith(color: t.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _permissions(RecapTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mic_none, size: 48, color: t.accent),
          const SizedBox(height: 24),
          Text('Permissions',
              style: RT.title.copyWith(color: t.textPrimary)),
          const SizedBox(height: 16),
          _permRow(t, Icons.mic, 'Microphone',
              'Required for recording. Recap never shares mic audio.', true),
          _permRow(t, Icons.calendar_month_outlined, 'Calendar',
              'Optional. Auto-titles meetings from calendar events.', false),
          _permRow(t, Icons.notifications_none, 'Notifications',
              'Optional. Local-only — "transcript ready", "action item due".',
              false),
        ],
      ),
    );
  }

  Widget _permRow(RecapTheme t, IconData icon, String name, String desc,
      bool required) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: t.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name,
                      style: RT.body.copyWith(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  if (required)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: t.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Required',
                          style:
                              RT.caption.copyWith(color: t.accent)),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(desc,
                    style: RT.bodySm.copyWith(color: t.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadOptIn(RecapTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_download_outlined, size: 48, color: t.accent),
          const SizedBox(height: 24),
          Text('Better AI in the background',
              style: RT.title.copyWith(color: t.textPrimary)),
          const SizedBox(height: 12),
          Text(
            'A small Whisper model is bundled, so live captions work right now. The better Whisper (~140 MB) + on-device AI summary model (~2.4 GB) download in the background while you record.',
            style: RT.body.copyWith(color: t.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Wi-Fi only',
                    style: RT.body.copyWith(color: t.textPrimary)),
              ),
              RecapToggle(
                value: _wifiOnly,
                onChanged: (v) => setState(() => _wifiOnly = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Recommended — large models stay off your cellular data plan.',
            style: RT.caption.copyWith(color: t.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _startRecording(RecapTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fiber_manual_record, size: 88, color: t.recordRed),
          const SizedBox(height: 32),
          Text("You're set",
              style: RT.titleLg.copyWith(
                  color: t.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Text(
            'Tap Record on the home screen to capture your first meeting. Live captions appear instantly.',
            textAlign: TextAlign.center,
            style: RT.bodyLg.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 48),
          Btn(
            label: 'Start using Recap',
            variant: BtnVariant.primary,
            full: true,
            size: BtnSize.lg,
            onPressed: () async {
              await _kickOffBackgroundDownloads();
              await _markComplete();
            },
          ),
        ],
      ),
    );
  }

  Widget _dotsAndNext(RecapTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          for (var i = 0; i < _pages; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? t.accent : t.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          const Spacer(),
          if (_page < _pages - 1)
            Btn(
              label: 'Next',
              variant: BtnVariant.accentSoft,
              size: BtnSize.sm,
              trailing: Icons.arrow_forward,
              onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut),
            ),
        ],
      ),
    );
  }
}
