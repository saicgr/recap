import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

/// About + License attribution + Privacy Policy + ToS links (D14.18).
/// Required for App Store / Play Store submission.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
                'About',
                style: RT.subtitle.copyWith(color: t.textPrimary),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _hero(t),
                  const SizedBox(height: 24),
                  _row(t, 'Version', '0.1.0'),
                  _row(t, 'Build', 'dev'),
                  _row(t, 'Whisper', 'whisper.cpp + ggml'),
                  _row(
                    t,
                    'Diarization',
                    'Pyannote 3.0 + WeSpeaker (via sherpa-onnx)',
                  ),
                  _row(
                    t,
                    'On-device LLM',
                    'Gemma 4 E2B / E4B + Apple Foundation Models + Ollama (desktop)',
                  ),
                  _row(
                    t,
                    'Cloud (opt-in)',
                    'Gemini 3.1 Flash Lite via Render proxy',
                  ),
                  const SizedBox(height: 24),
                  _linkRow(t, 'Privacy policy', _privacyPolicyUrl),
                  _linkRow(t, 'Terms of service', _tosUrl),
                  _linkRow(
                    t,
                    'Source code (privacy-critical paths)',
                    _sourceUrl,
                  ),
                  _linkRow(t, 'Open-source licenses', _licensesUrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(RecapTheme t) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.mic, size: 48, color: t.accent),
          const SizedBox(height: 12),
          Text(
            'Recap',
            style: RT.titleLg.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Voice Memos, with on-device AI.',
            style: RT.body.copyWith(color: t.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _row(RecapTheme t, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: RT.body.copyWith(color: t.textPrimary)),
          ),
          Text(value, style: RT.bodySm.copyWith(color: t.textSecondary)),
        ],
      ),
    );
  }

  Widget _linkRow(RecapTheme t, String label, String url) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: ListTile(
        title: Text(label, style: TextStyle(color: t.textPrimary)),
        trailing: Icon(Icons.open_in_new, size: 18, color: t.textMuted),
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  static const _privacyPolicyUrl = 'https://recapfreenote.com/privacy';
  static const _tosUrl = 'https://recapfreenote.com/terms';
  static const _sourceUrl = 'https://github.com/recapfreenote/recap';
  static const _licensesUrl = 'https://recapfreenote.com/licenses';
}
