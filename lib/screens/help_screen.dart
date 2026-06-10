import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

/// Help / FAQ screen (D14.18). Local Markdown content + a single email
/// link. No web tracking, no help-center analytics, no zendesk popups.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = <(String, String)>[
    (
      'How does on-device transcription work?',
      'Recap bundles Whisper tiny.en (~75 MB) so your first recording transcribes immediately with no downloads. In the background, a higher-accuracy model (base.en for Free, small.en for Pro+) downloads on Wi-Fi. On iOS / Android 13+, Recap can also use Apple SFSpeechRecognizer / Google on-device SpeechRecognizer — faster + saves battery via the Neural Engine.',
    ),
    (
      'Where are my recordings stored?',
      'On your device only, in Recap\'s app-private storage. Uninstalling the app deletes them. Use Settings → Backup to export to iCloud Drive / Google Drive / a file you keep.',
    ),
    (
      'Do you send my recordings to the cloud?',
      'Only if you tap a cloud button (cloud summary, workflow export to Notion/Slack/GDocs, YouTube import, direct URL import, OAuth sign-in). On the Privacy tier, cloud is structurally disabled — verifiable by reading our source. See Settings → Privacy dashboard for a live audit.',
    ),
    (
      'How does the YouTube import work?',
      'Recap fetches the public caption track from YouTube — we never download the video itself (against YouTube ToS). If a video has no captions, you\'ll see a clear error.',
    ),
    (
      'What\'s the difference between Free, Pro, Privacy, and Power?',
      'Free: 5 cloud summaries / month, tiny Whisper, watermarked exports. Pro \$49: 100 cloud summaries, small Whisper + Gemma 4 E4B + Apple FM, all features. Privacy \$69: same as Pro but cloud is verifiably disabled. Power \$99: BYOK Gemini, Notion/Slack/GDocs exports, MCP companion, wake word, custom personas.',
    ),
    (
      'Why doesn\'t Recap have a meeting bot for Zoom?',
      'Bots add a third participant to the call. Recap captures audio directly from your phone\'s mic, your laptop\'s system audio (desktop), or your browser tab (Chrome extension). No one in the meeting sees that you\'re recording — same legal posture as recording yourself.',
    ),
    (
      'How do I get my data out?',
      'Settings → Backup → Export now produces a .recap-backup zip containing all meetings, transcripts, summaries, and audio. Use the share-sheet to send it wherever you like.',
    ),
    (
      'What makes Recap different from my phone\'s built-in recorder or other meeting apps?',
      'Three things. (1) No account — you never sign up to record, transcribe, or summarize, where many apps require one even for on-device summaries. (2) It runs everywhere — iPhone and Android, plus desktop and the browser — not locked to one brand or to the newest flagship hardware. (3) It\'s on-device and one-time — summaries run on your phone by default and you pay once, instead of uploading audio to the cloud on a monthly subscription. See Settings → What makes Recap different for the full picture.',
    ),
  ];

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
              title: Text('Help',
                  style: RT.subtitle.copyWith(color: t.textPrimary)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final faq in _faqs)
                    _faqTile(t, faq.$1, faq.$2),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: t.surface,
                      border: Border.all(color: t.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Still stuck?',
                            style: RT.subtitle
                                .copyWith(color: t.textPrimary)),
                        const SizedBox(height: 8),
                        Text(
                          'We don\'t track support tickets. Email us with what happened + any logs you want to share. We\'ll get back to you.',
                          style: RT.bodySm
                              .copyWith(color: t.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Btn(
                          label: 'Email support',
                          variant: BtnVariant.accentSoft,
                          trailing: Icons.mail_outline,
                          onPressed: () async {
                            final uri = Uri.parse(
                                'mailto:support@recapfreenote.com?subject=Recap%20support');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqTile(RecapTheme t, String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(q,
            style: RT.body.copyWith(
                color: t.textPrimary, fontWeight: FontWeight.w600)),
        iconColor: t.textMuted,
        collapsedIconColor: t.textMuted,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(a,
                style: RT.bodySm.copyWith(
                    color: t.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
