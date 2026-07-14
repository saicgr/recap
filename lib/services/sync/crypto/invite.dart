import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// The client half of the workspace invite flow.
///
/// A single random invite token is split into TWO independent HKDF outputs:
///
///   lookup = HKDF(token, "recap/invite/lookup")   -> the server sees this
///   kek    = HKDF(token, "recap/invite/kek")      -> the server NEVER sees this
///
/// This split is the whole security argument, and it was a correction from an
/// earlier broken design. The naive version sent the raw token to the server and
/// stored the token-wrapped key beside it — so at redemption the operator held
/// BOTH halves and could derive every workspace key. Here:
///
///   - The inviter wraps K_ws with `kek` locally and uploads only the wrapped
///     blob + sha256(lookup).
///   - The invitee receives the TOKEN out-of-band (an invite link fragment,
///     which never hits a server log), sends only `lookup` to accept_invite, and
///     gets the blob back. It derives `kek` from the token it holds and unwraps
///     locally.
///
/// Because lookup and kek are independent HKDF outputs, seeing `lookup` reveals
/// nothing about `kek`. The operator stores a blob it cannot open.
class Invite {
  Invite._();

  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final _aead = AesGcm.with256bits();

  /// A fresh, URL-safe invite token. This is the ONLY secret; it travels
  /// out-of-band and is never sent to the server whole.
  static String newToken() {
    final rng = SecureRandom.fast;
    final bytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      bytes[i] = rng.nextUint32() & 0xff;
    }
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static Future<SecretKey> _derive(String token, String label) => _hkdf.deriveKey(
        secretKey: SecretKey(utf8.encode(token)),
        nonce: const [], // token itself is the high-entropy input
        info: utf8.encode(label),
      );

  /// `lookup`, sent to the server to find the invite row. Not secret.
  static Future<String> lookup(String token) async {
    final k = await _derive(token, 'recap/invite/lookup');
    return base64Url.encode(await k.extractBytes()).replaceAll('=', '');
  }

  /// Inviter side: wrap the workspace key with `kek` derived from the token.
  /// The resulting blob is what the server stores and later hands the invitee.
  static Future<String> wrapKey({
    required String token,
    required SecretKey workspaceKey,
  }) async {
    final kek = await _derive(token, 'recap/invite/kek');
    final nonce = _aead.newNonce();
    final box = await _aead.encrypt(
      await workspaceKey.extractBytes(),
      secretKey: kek,
      nonce: nonce,
    );
    final out = BytesBuilder()
      ..add(nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return base64.encode(out.toBytes());
  }

  /// Invitee side: unwrap the workspace key using `kek` derived from the token.
  static Future<SecretKey> unwrapKey({
    required String token,
    required String wrapped,
  }) async {
    final kek = await _derive(token, 'recap/invite/kek');
    final raw = base64.decode(wrapped);
    if (raw.length < 12 + 16) {
      throw const InviteError('wrapped invite key is truncated');
    }
    final nonce = raw.sublist(0, 12);
    final rest = raw.sublist(12);
    final cipherText = rest.sublist(0, rest.length - 16);
    final mac = Mac(rest.sublist(rest.length - 16));
    try {
      final keyBytes = await _aead.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: kek,
      );
      return SecretKey(keyBytes);
    } on SecretBoxAuthenticationError {
      // Wrong token, or a tampered blob. Never return a garbage key: it would
      // decrypt the workspace to noise and look like data corruption.
      throw const InviteError(
        'could not unwrap the invite — the invite link is wrong or corrupted',
      );
    }
  }
}

class InviteError implements Exception {
  const InviteError(this.message);
  final String message;
  @override
  String toString() => 'InviteError: $message';
}
