import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../services/insights_service.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

/// Insights / local analytics screen (D14.10). All computation happens
/// on-device; never reported anywhere. Per Karpathy invariants this is the
/// *user's* analytics about *their own* data, surfaced *to* the user.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  WeeklySummary? _weekly;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final w = await insights.weeklySummary();
    if (!mounted) return;
    setState(() => _weekly = w);
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    final w = _weekly;
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
              title: Text('Insights',
                  style: RT.subtitle.copyWith(color: t.textPrimary)),
            ),
            Expanded(
              child: w == null
                  ? Center(child: CircularProgressIndicator(color: t.accent))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _card(
                          t,
                          title: 'This week',
                          subtitle:
                              '${DateFormat.MMMd().format(w.startOfWeek)} → ${DateFormat.MMMd().format(w.endOfWeek)}',
                          stats: [
                            ('Meetings', '${w.meetingCount}'),
                            ('Recorded', _fmtDuration(w.totalDuration)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: t.surface,
                            border: Border.all(color: t.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Coming soon',
                                  style: RT.subtitle
                                      .copyWith(color: t.textPrimary)),
                              const SizedBox(height: 8),
                              Text(
                                'Talk-time per speaker · Words-per-minute breakdown · Meeting-series trends · Cross-meeting topic clustering. All local. All private.',
                                style: RT.bodySm
                                    .copyWith(color: t.textSecondary),
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

  Widget _card(
    RecapTheme t, {
    required String title,
    required String subtitle,
    required List<(String, String)> stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: RT.subtitle.copyWith(color: t.textPrimary)),
          Text(subtitle, style: RT.caption.copyWith(color: t.textMuted)),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final s in stats)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$2,
                          style: RT.titleLg.copyWith(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(s.$1.toUpperCase(),
                          style: RT.caption.copyWith(
                              color: t.textMuted, letterSpacing: 0.8)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
