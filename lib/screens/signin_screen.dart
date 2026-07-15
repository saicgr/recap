import 'dart:io';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _onSuccess() async {
    // Sign-in no longer promotes tier (Free+ was dropped in the simplification
    // to a 4-tier ladder — it violated the no-account Karpathy invariant).
    // Sign-in now exists only for optional features like cross-device
    // settings sync, restore-purchases on a new device, etc.
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _withApple() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _auth.signInWithApple();
      await _onSuccess();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withEmail() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _auth.signInWithEmail(_email.text);
      await _onSuccess();
    } catch (e) {
      setState(() => _error = 'Enter a valid email.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
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
                'Free+',
                style: RT.subtitle.copyWith(color: t.textPrimary),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  Text(
                    'Unlock Free+',
                    style: RT.titleLg.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Free+ doubles your meetings/day, extends per-meeting cap to 40 min, and unlocks Apple Reminders / Apple Notes exports.',
                    style: RT.body.copyWith(
                      color: t.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _bullets(t, const [
                    '3 meetings/day instead of 2',
                    '40-min per-meeting cap (was 30)',
                    '20 hours/month total (was 10)',
                    '10 cloud summaries/month (was 2)',
                    '+ Apple Reminders / Apple Notes exports',
                  ]),
                  const SizedBox(height: 24),
                  if (Platform.isIOS || Platform.isMacOS) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _withApple,
                        icon: const Icon(Icons.apple, color: Colors.white),
                        label: const Text(
                          'Sign in with Apple',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Google sign-in placeholder — needs OAuth client + Firebase
                  // setup on both platforms before it can ship. Surface as
                  // "coming soon" so the option is visible.
                  Material(
                    color: t.surface,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: t.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      onTap: null, // disabled
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.g_mobiledata,
                              size: 24,
                              color: t.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sign in with Google · coming soon',
                              style: RT.body.copyWith(color: t.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: t.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR EMAIL',
                          style: RT.caption.copyWith(color: t.textMuted),
                        ),
                      ),
                      Expanded(child: Divider(color: t.divider)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    cursorColor: t.accent,
                    style: RT.body.copyWith(color: t.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: t.surface,
                      hintText: 'you@example.com',
                      hintStyle: RT.body.copyWith(color: t.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: t.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: t.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: t.accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Btn(
                    label: 'Continue with email',
                    variant: BtnVariant.primary,
                    full: true,
                    size: BtnSize.lg,
                    onPressed: _busy ? null : _withEmail,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Email is stored on this device only — never sent to a server, never used to message you. We don\'t verify it.',
                    style: RT.bodySm.copyWith(color: t.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: RT.body.copyWith(color: t.recordRed),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullets(RecapTheme t, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check, size: 14, color: t.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line,
                    style: RT.bodySm.copyWith(
                      color: t.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
