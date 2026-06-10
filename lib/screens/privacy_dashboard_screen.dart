import 'package:flutter/material.dart';

import '../billing/tier.dart';
import '../main.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

/// Privacy dashboard (D14.13) — make the Karpathy criteria *visible*.
/// Trust UX: instead of "we have a privacy policy in a PDF," users can see
/// in-app what we never collect, what lives only on their device, and what
/// would go over the network if they tapped a cloud button.
class PrivacyDashboardScreen extends StatelessWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    final tier = entitlements.currentTier;
    final isPrivacy = tier == Tier.privacy;

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
              title: Text('Privacy dashboard',
                  style: RT.subtitle.copyWith(color: t.textPrimary)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _block(
                    t,
                    icon: Icons.block,
                    accent: t.positive,
                    title: 'What we NEVER collect',
                    items: const [
                      'No analytics SDK',
                      'No telemetry pings',
                      'No crash reports auto-sent',
                      'No advertising ID access',
                      'No location tracking',
                      'No account-required for any AI feature',
                    ],
                  ),
                  _block(
                    t,
                    icon: Icons.smartphone,
                    accent: t.accent,
                    title: 'What lives ONLY on your device',
                    items: const [
                      'All audio recordings',
                      'All transcripts',
                      'All summaries (on-device path)',
                      'Voice ID enrollments',
                      'Custom personas',
                      'Action items',
                      'Settings preferences',
                    ],
                  ),
                  _block(
                    t,
                    icon: Icons.cloud_outlined,
                    accent: isPrivacy ? t.positive : t.warn,
                    title: isPrivacy
                        ? 'Network: structurally disabled on Privacy tier'
                        : 'What goes over the network — only when YOU tap',
                    items: isPrivacy
                        ? const [
                            'Privacy tier: cloud-summary code path is dead-code-eliminated',
                            'No cloud Gemini calls possible',
                            'No workflow exports to cloud destinations',
                            'Audit any of this by reading lib/',
                          ]
                        : const [
                            'Cloud summary → Render proxy → Google Gemini (only on Generate Cloud Summary tap)',
                            'Workflow exports → your chosen Notion / Slack / GDocs (only on Export tap)',
                            'YouTube caption fetch → youtube.com (only on YouTube import tap)',
                            'Direct URL import → the URL you typed',
                            'Model downloads → Hugging Face on first-launch opt-in',
                            'Nothing else.',
                          ],
                  ),
                  _block(
                    t,
                    icon: Icons.lock_outline,
                    accent: t.accent,
                    title: 'App Lock + Encryption status',
                    items: [
                      'App Lock: configurable in Settings',
                      'Audio encryption at rest: via platform Keychain / Keystore',
                      'Backup: user-controlled, E2E-encrypted, never uploaded by Recap',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _block(
    RecapTheme t, {
    required IconData icon,
    required Color accent,
    required String title,
    required List<String> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: RT.subtitle.copyWith(color: t.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check, size: 14, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item,
                        style:
                            RT.bodySm.copyWith(color: t.textSecondary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
