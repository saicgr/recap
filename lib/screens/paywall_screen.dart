import 'package:flutter/material.dart';

import '../billing/tier.dart';
import '../main.dart';
import '../services/iap_service.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';
import 'compare_screen.dart';

class PaywallScreen extends StatefulWidget {
  final String? reason;
  const PaywallScreen({super.key, this.reason});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _picked = 'pro';
  bool _busy = false;
  String? _error;

  static const _tiers = [
    (
      id: 'privacy',
      tier: Tier.privacy,
      sub: 'Verifiable no-network',
      perks: [
        'Everything in Pro, but cloud is structurally disabled',
        'Pyannote diarization + voice ID — all offline',
        'On-device translation only',
        'Verifiable in code — review lib/ to confirm zero network',
        'For users who want a one-time-buy product they can audit',
      ],
      featured: false,
      pid: ProductIds.privacy,
    ),
    (
      id: 'pro',
      tier: Tier.pro,
      sub: 'The full Recap experience',
      perks: [
        'Unlimited recording + on-device AI',
        'Whisper small.en + Gemma 4 E4B + Apple FM',
        '100 cloud summaries / month',
        'All 7 personas + viral clip studio',
        'Speaker labels, voice ID, translation',
        'Cross-meeting search + auto-chapters',
        'No watermark on shares',
      ],
      featured: true,
      pid: ProductIds.pro,
    ),
    (
      id: 'power',
      tier: Tier.power,
      sub: 'For heavy users + workflow nerds',
      perks: [
        'Everything in Pro',
        'BYOK Gemini — unlimited cloud',
        'Notion / Slack / Obsidian / GDocs exports',
        'MCP companion (Claude Desktop etc.)',
        'Custom persona prompts',
        'Wake word + smart compose',
      ],
      featured: false,
      pid: ProductIds.power,
    ),
  ];

  Future<void> _buy() async {
    final entry = _tiers.firstWhere((t) => t.id == _picked);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await iap.buy(entry.pid);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    final picked = _tiers.firstWhere((x) => x.id == _picked);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              leading: IconBtn(
                icon: Icons.close,
                onPressed: () => Navigator.pop(context),
              ),
              trailing: [
                TextButton(
                  onPressed: _busy ? null : () => iap.restore(),
                  child: Text('Restore',
                      style: RT.label.copyWith(
                        color: t.textSecondary,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  if (widget.reason != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.bgSubtle,
                        border: Border.all(color: t.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(widget.reason!,
                          style:
                              RT.body.copyWith(color: t.textPrimary)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  RichText(
                    text: TextSpan(
                      style: RT.titleLg.copyWith(
                          color: t.textPrimary, height: 36 / 28),
                      children: [
                        const TextSpan(text: 'Lifetime. No account.\n'),
                        TextSpan(
                          text: 'No telemetry.',
                          style: TextStyle(color: t.accent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'One-time purchase. Pick the tier that fits how you work — upgrade anytime by paying the difference.',
                    style: RT.bodyLg.copyWith(color: t.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CompareScreen()),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Why Recap?',
                              style: RT.label.copyWith(
                                  color: t.accent,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward,
                              size: 14, color: t.accent),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final entry in _tiers) ...[
                    _tierCard(t, entry),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.bgSubtle,
                      border: Border.all(color: t.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.lock_outline,
                              size: 14, color: t.accent),
                          const SizedBox(width: 8),
                          Text(
                            'What "no telemetry" means',
                            style: RT.label.copyWith(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          'We don\'t run analytics, crash reporting, or A/B tests. Cloud summaries — if enabled — route through a stateless proxy that strips identifiers.',
                          style: RT.bodySm
                              .copyWith(color: t.textSecondary, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: RT.body.copyWith(color: t.recordRed)),
                  ],
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: t.bg,
                border: Border(top: BorderSide(color: t.divider)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Column(
                children: [
                  Btn(
                    label:
                        'Continue with ${_capitalize(picked.id)} · \$${picked.tier.priceUsd}',
                    variant: BtnVariant.primary,
                    size: BtnSize.lg,
                    full: true,
                    onPressed: _busy ? null : _buy,
                  ),
                  const SizedBox(height: 8),
                  Text('One-time purchase. No subscription.',
                      style: RT.bodySm.copyWith(color: t.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tierCard(
      RecapTheme t, ({
    String id,
    Tier tier,
    String sub,
    List<String> perks,
    bool featured,
    String pid,
  }) entry) {
    final picked = entry.id == _picked;
    return GestureDetector(
      onTap: () => setState(() => _picked = entry.id),
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(
            color: picked ? t.accent : t.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (entry.featured)
              Positioned(
                top: -22,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('MOST POPULAR',
                      style: RT.caption.copyWith(color: Colors.white)),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_capitalize(entry.id),
                              style: RT.subtitle.copyWith(
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(entry.sub,
                              style:
                                  RT.bodySm.copyWith(color: t.textMuted)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('\$',
                                  style: RT.body.copyWith(
                                      color: t.textMuted,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Text('${entry.tier.priceUsd}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: t.textPrimary,
                                  letterSpacing: -0.5,
                                ).merge(RT.num)),
                          ],
                        ),
                        Text('once',
                            style: RT.caption
                                .copyWith(color: t.textMuted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final perk in entry.perks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check,
                            size: 14,
                            color: picked ? t.accent : t.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(perk,
                              style: RT.bodySm.copyWith(
                                  color: t.textSecondary, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
