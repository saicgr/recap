import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Sharing a workspace without ever handing the server a key.
///
/// Each workspace has one symmetric key `K_ws`. To add a member, an existing
/// member encrypts `K_ws` TO that member's public key. The server stores only
/// wrapped blobs it cannot open, and the plaintext key never exists anywhere but
/// on members' devices.
///
/// ## Key rotation on removal — NOT optional
///
/// When a member is removed, the workspace MUST be re-keyed (new `kid`, new
/// `K_ws`, re-wrapped for everyone who remains). Simply deleting their
/// membership row stops the *server* from serving them rows, but they still hold
/// the old `K_ws` — so any ciphertext they already fetched, or could obtain from
/// a backup, stays readable to them forever. Revocation without rotation is
/// theatre.
class KeyWrap {
  KeyWrap._();

  static final _x25519 = X25519();
  static final _aead = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// A member's long-lived identity keypair. The private half never leaves the
  /// device (and is itself wrapped by the recovery code — see recovery.dart).
  static Future<SimpleKeyPair> generateIdentity() => _x25519.newKeyPair();

  /// Fresh symmetric key for a workspace (or for a new generation of one).
  static Future<SecretKey> generateWorkspaceKey() => _aead.newSecretKey();

  /// Encrypt [workspaceKey] to [recipientPublicKey].
  ///
  /// Ephemeral-static X25519: a throwaway keypair per wrap, so the same key
  /// wrapped twice produces different bytes and reveals nothing by comparison.
  /// The ephemeral public key travels with the blob.
  ///
  /// Wire: `base64( ephemeralPub:32 || nonce:12 || ct || tag:16 )`
  static Future<String> wrapFor({
    required SecretKey workspaceKey,
    required SimplePublicKey recipientPublicKey,
  }) async {
    final ephemeral = await _x25519.newKeyPair();
    final shared = await _x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: recipientPublicKey,
    );

    final ephemeralPub = await ephemeral.extractPublicKey();
    // Bind the derived KEK to the ephemeral public key, so a blob cannot be
    // lifted and replayed under a different ephemeral.
    final kek = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: ephemeralPub.bytes,
      info: utf8.encode('recap/keywrap/v1'),
    );

    final nonce = _aead.newNonce();
    final box = await _aead.encrypt(
      await workspaceKey.extractBytes(),
      secretKey: kek,
      nonce: nonce,
    );

    final out = BytesBuilder()
      ..add(ephemeralPub.bytes)
      ..add(nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return base64.encode(out.toBytes());
  }

  /// Recover the workspace key from a blob wrapped for [myIdentity].
  static Future<SecretKey> unwrap({
    required String wrapped,
    required SimpleKeyPair myIdentity,
  }) async {
    final raw = base64.decode(wrapped);
    if (raw.length < 32 + 12 + 16) {
      throw const KeyWrapError('wrapped key is truncated');
    }

    final ephemeralPub = SimplePublicKey(
      raw.sublist(0, 32),
      type: KeyPairType.x25519,
    );
    final nonce = raw.sublist(32, 44);
    final rest = raw.sublist(44);
    final cipherText = rest.sublist(0, rest.length - 16);
    final mac = Mac(rest.sublist(rest.length - 16));

    final shared = await _x25519.sharedSecretKey(
      keyPair: myIdentity,
      remotePublicKey: ephemeralPub,
    );
    final kek = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: ephemeralPub.bytes,
      info: utf8.encode('recap/keywrap/v1'),
    );

    try {
      final keyBytes = await _aead.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: kek,
      );
      return SecretKey(keyBytes);
    } on SecretBoxAuthenticationError {
      // Not our blob, or it was tampered with. Never return a garbage key: it
      // would decrypt every row to noise and look like data corruption.
      throw const KeyWrapError(
        'could not unwrap the workspace key — it was not sealed to this identity',
      );
    }
  }

  /// A short human-comparable fingerprint of a public key ("safety number").
  ///
  /// Trust in the key directory is TOFU: the server hands out public keys, and a
  /// malicious operator could hand out its own and read everything from then on.
  /// Comparing this string out-of-band is what makes that attack DETECTABLE. It
  /// does not make it impossible — say so plainly rather than overclaiming.
  static Future<String> safetyNumber(SimplePublicKey key) async {
    final digest = await Sha256().hash(key.bytes);
    final hex = digest.bytes
        .take(10)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final groups = <String>[];
    for (var i = 0; i < hex.length; i += 4) {
      groups.add(hex.substring(i, i + 4));
    }
    return groups.join(' ');
  }
}

class KeyWrapError implements Exception {
  const KeyWrapError(this.message);
  final String message;
  @override
  String toString() => 'KeyWrapError: $message';
}
