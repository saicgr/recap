import 'package:flutter/material.dart';

import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';
import 'privacy_dashboard_screen.dart';

/// "What makes Recap different" (D14.20).
///
/// Capability-framed positioning surface. Per the product brand (Karpathy-
/// minimalist, no trash-talk) this names ZERO competitors — every point is
/// stated as a Recap capability with a generic "elsewhere" contrast. The
/// detailed, sourced competitive analysis lives in docs/MARKET_ANALYSIS.md;
/// this screen is the user-facing distillation of its moat section.
class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  // (icon, title, what Recap does, what most apps do)
  static const _pillars = <(IconData, String, String, String)>[
    (
      Icons.person_off_outlined,
      'No account, ever',
      'Record, transcribe, and summarize without signing up for anything.',
      'Most apps require an account — some even to summarize your own recording.',
    ),
    (
      Icons.smartphone,
      'Works on any phone',
      'iPhone and Android — plus Mac, Windows, and the browser.',
      'Built-in AI recorders are locked to one brand, or one platform.',
    ),
    (
      Icons.devices_other_outlined,
      'Runs where others won\'t',
      'No special chip required — if a small model fits, Recap runs.',
      'Premium AI features are often gated to the newest flagship hardware.',
    ),
    (
      Icons.cloud_off_outlined,
      'Nothing leaves your device',
      'Transcription and summaries run on-device by default. Cloud is opt-in.',
      'Many apps upload your audio to their servers to process it.',
    ),
    (
      Icons.auto_awesome_outlined,
      'On-device AI summaries — every tier',
      'The summary is generated on your phone, not just the transcript.',
      'AI summaries are usually cloud-only or reserved for the top plan.',
    ),
    (
      Icons.sell_outlined,
      'Pay once, keep it forever',
      'A one-time price. No subscription, no per-seat billing, no renewals.',
      'Most meeting tools bill every month, indefinitely.',
    ),
    (
      Icons.videocam_off_outlined,
      'No bot in your meeting',
      'Captures audio directly — nobody invited a recorder into the call.',
      'Many tools add a visible bot as a participant in the meeting.',
    ),
    (
      Icons.verified_user_outlined,
      'Privacy you can verify',
      'On the Privacy tier the network code path doesn\'t exist — and the code is open to read.',
      'Privacy is usually a policy document you have to take on faith.',
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
              title: Text('What makes Recap different',
                  style: RT.subtitle.copyWith(color: t.textPrimary)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'One idea, everywhere',
                    style: RT.title.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recap is a meeting recorder built around a single idea: your conversations are yours. Here is how that plays out — point by point.',
                    style:
                        RT.body.copyWith(color: t.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  for (final p in _pillars) _pillar(t, p.$1, p.$2, p.$3, p.$4),
                  const SizedBox(height: 8),
                  _closer(t, context),
                  const SizedBox(height: 16),
                  Text(
                    'No analytics. No telemetry. No competitor names harvested for ads — '
                    'we don\'t run any. The full, sourced comparison lives in our docs.',
                    textAlign: TextAlign.center,
                    style: RT.caption.copyWith(
                        color: t.textMuted, letterSpacing: 0, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillar(
    RecapTheme t,
    IconData icon,
    String title,
    String recap,
    String elsewhere,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: t.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: t.accent, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: RT.subtitle.copyWith(color: t.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _line(t, Icons.check, t.positive, 'Recap', recap),
          const SizedBox(height: 6),
          _line(t, Icons.remove, t.textMuted, 'Elsewhere', elsewhere),
        ],
      ),
    );
  }

  Widget _line(
    RecapTheme t,
    IconData icon,
    Color color,
    String tag,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: RT.bodySm.copyWith(color: t.textSecondary, height: 1.45),
              children: [
                TextSpan(
                  text: '$tag — ',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _closer(RecapTheme t, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.accentBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('See it for yourself',
              style: RT.subtitle.copyWith(color: t.textPrimary)),
          const SizedBox(height: 6),
          Text(
            'Open the Privacy dashboard for a live audit of exactly what stays on your device and what would go over the network if you tapped a cloud button.',
            style: RT.bodySm.copyWith(color: t.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),
          Btn(
            label: 'Open Privacy dashboard',
            variant: BtnVariant.accentSoft,
            trailing: Icons.arrow_forward,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyDashboardScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
