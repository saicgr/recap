import 'package:flutter/material.dart';

import '../main.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

/// App Lock settings (D14.12). Face ID / Touch ID gate before opening the
/// app. Toggle, timeout picker, "lock now" action.
class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  @override
  void initState() {
    super.initState();
    appLock.addListener(_rebuild);
  }

  @override
  void dispose() {
    appLock.removeListener(_rebuild);
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
              title: Text('App Lock',
                  style: RT.subtitle.copyWith(color: t.textPrimary)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                        Row(
                          children: [
                            Icon(Icons.lock_outline,
                                color: t.accent, size: 20),
                            const SizedBox(width: 8),
                            Text('Require biometric to open',
                                style: RT.subtitle
                                    .copyWith(color: t.textPrimary)),
                            const Spacer(),
                            RecapToggle(
                              value: appLock.enabled,
                              onChanged: (v) async {
                                await appLock.setEnabled(v);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Face ID / Touch ID / device passcode is required on app launch and after the timeout below.',
                          style: RT.bodySm
                              .copyWith(color: t.textSecondary),
                        ),
                        const SizedBox(height: 18),
                        Text('Lock after',
                            style: RT.subtitle
                                .copyWith(color: t.textPrimary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final m in const [1, 5, 15, 60])
                              ChoiceChip(
                                label: Text('$m min',
                                    style: TextStyle(
                                        color: appLock.timeoutMinutes == m
                                            ? Colors.white
                                            : t.textPrimary)),
                                selected: appLock.timeoutMinutes == m,
                                selectedColor: t.accent,
                                backgroundColor: t.bgSubtle,
                                onSelected: (_) =>
                                    appLock.setTimeoutMinutes(m),
                              ),
                          ],
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
}
