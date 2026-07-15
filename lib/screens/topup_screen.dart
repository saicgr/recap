import 'package:flutter/material.dart';

import '../billing/tier.dart';
import '../main.dart';
import '../services/iap_service.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  TopUpPack _picked = TopUpPack.medium;
  bool _busy = false;
  String? _error;

  static const _packs = <(TopUpPack, String, String, String?)>[
    (TopUpPack.small, '25 cloud summaries', '\$2.99', null),
    (TopUpPack.medium, '100 cloud summaries', '\$9.99', '25% off'),
    (TopUpPack.large, '500 cloud summaries', '\$39.99', '40% off · best value'),
  ];

  static const _pids = <TopUpPack, String>{
    TopUpPack.small: ProductIds.topUp25,
    TopUpPack.medium: ProductIds.topUp100,
    TopUpPack.large: ProductIds.topUp500,
  };

  Future<void> _buy() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await iap.buy(_pids[_picked]!);
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
    final pickEntry = _packs.firstWhere((p) => p.$1 == _picked);
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
              title: Text(
                'Cloud summaries',
                style: RT.subtitle.copyWith(color: t.textPrimary),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Text(
                    'Top up cloud summaries',
                    style: RT.titleLg.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'One-time IAP. Credits never expire. Use only when you hit your monthly cloud quota.',
                    style: RT.body.copyWith(
                      color: t.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final entry in _packs) ...[
                    _packCard(t, entry),
                    const SizedBox(height: 10),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: RT.body.copyWith(color: t.recordRed)),
                  ],
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: t.bg,
                border: Border(top: BorderSide(color: t.divider)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  Btn(
                    label:
                        'Buy ${pickEntry.$2.split(' ').first} for ${pickEntry.$3}',
                    variant: BtnVariant.primary,
                    size: BtnSize.lg,
                    full: true,
                    onPressed: _busy ? null : _buy,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Charged through your App Store / Play account.',
                    style: RT.bodySm.copyWith(color: t.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _packCard(RecapTheme t, (TopUpPack, String, String, String?) entry) {
    final picked = entry.$1 == _picked;
    return GestureDetector(
      onTap: () => setState(() => _picked = entry.$1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: picked ? t.accentSoft : t.surface,
          border: Border.all(
            color: picked ? t.accent : t.border,
            width: picked ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: picked ? t.accent : Colors.transparent,
                border: Border.all(
                  color: picked ? t.accent : t.border,
                  width: 1.5,
                ),
              ),
              child: picked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.$2,
                    style: RT.subtitle.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (entry.$4 != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      entry.$4!,
                      style: RT.caption.copyWith(color: t.accent),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              entry.$3,
              style: RT.subtitle.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
