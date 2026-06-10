import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Local-only Free+ unlock. Apple Sign-in / email — no backend, no SMTP, no
/// server-side verification. The presence of a stored credential is enough
/// to mark the user as "signed in," which the EntitlementService consults to
/// elevate them from Free → Free+.
///
/// Karpathy invariant: nothing leaves the device. Apple Sign-in does talk to
/// Apple's servers (the user actively authorizes it), but we never persist
/// the returned authorization code anywhere except local keychain. We don't
/// hit an auth backend with it.
class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _kProvider = 'auth_provider';
  static const _kIdentifier = 'auth_identifier';

  Future<String?> get currentProvider => _storage.read(key: _kProvider);
  Future<String?> get currentIdentifier => _storage.read(key: _kIdentifier);

  /// True if the user has any kind of Free+ unlock stored.
  Future<bool> get isSignedIn async =>
      (await _storage.read(key: _kProvider)) != null;

  /// Sign in with Apple. iOS only. Returns true on success.
  Future<bool> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw StateError('Sign in with Apple is only available on iOS / macOS.');
    }
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        // No email scope — we don't want it on the device anyway.
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final id = credential.userIdentifier ?? credential.givenName ?? 'apple';
    await _storage.write(key: _kProvider, value: 'apple');
    await _storage.write(key: _kIdentifier, value: id);
    return true;
  }

  /// Email "sign-in" — no verification, no SMTP. We just store the address
  /// locally as a soft commitment. Honest about it in the UI copy.
  Future<bool> signInWithEmail(String email) async {
    if (!_isEmail(email)) {
      throw ArgumentError('Not a valid email');
    }
    await _storage.write(key: _kProvider, value: 'email');
    await _storage.write(key: _kIdentifier, value: email.toLowerCase());
    return true;
  }

  Future<void> signOut() async {
    await _storage.delete(key: _kProvider);
    await _storage.delete(key: _kIdentifier);
  }

  static bool _isEmail(String s) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(s.trim());
}
