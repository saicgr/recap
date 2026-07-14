import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// End-to-end encryption for synced rows.
///
/// Neon and R2 store CIPHERTEXT ONLY. The operator holds no key and cannot read
/// user content — that is the whole point, and it is what Granola cannot say:
/// their own security page names Deepgram/AssemblyAI for ASR and
/// OpenAI/Anthropic for summaries, and their iOS app uploads your audio after
/// the meeting. Their guarantee is a contractual promise about a pipeline you
/// cannot inspect. Ours is structural.
///
/// ## Envelope
///
/// ```
/// [ver:1][alg:1][kid:u32-be][salt:16][nonce:12][ciphertext || GCM tag:16]
/// ```
/// serialised as base64 TEXT — **not** bytea. PostgREST hex-encodes bytea, which
/// doubles every payload on the wire.
///
/// ## Per-row key derivation
///
/// `K_row = HKDF-SHA256(K_ws, salt, "recap/enc/v1/" || table || row || field)`
///
/// A fresh random salt per row means the same workspace key never encrypts two
/// rows with the same derived key, so a nonce collision cannot leak a keystream
/// across rows.
///
/// ## AAD
///
/// `workspace || kid || table || row || field || hlc`
///
/// The HLC is in the AAD deliberately: without it the operator could take an old
/// ciphertext for a row and replay it in place of the current one. The row would
/// decrypt cleanly — it is genuinely our ciphertext — and the user would silently
/// see stale content. Binding the clock makes that swap fail to authenticate.
class Envelope {
  Envelope._();

  static const _version = 1;
  static const _algAesGcm = 1;

  static const _saltLen = 16;
  static const _nonceLen = 12;

  static final _aead = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// Bind a ciphertext to exactly where it lives. A row moved to another field,
  /// table, workspace, or key generation will not authenticate.
  static Uint8List _aad({
    required String workspaceId,
    required int kid,
    required String table,
    required String rowId,
    required String field,
    required String hlc,
  }) =>
      Uint8List.fromList(
        utf8.encode('$workspaceId|$kid|$table|$rowId|$field|$hlc'),
      );

  static Future<SecretKey> _deriveRowKey({
    required SecretKey workspaceKey,
    required List<int> salt,
    required String table,
    required String rowId,
    required String field,
  }) =>
      _hkdf.deriveKey(
        secretKey: workspaceKey,
        nonce: salt,
        info: utf8.encode('recap/enc/v1/$table/$rowId/$field'),
      );

  /// Encrypt [plaintext] for one field of one row.
  static Future<String> seal({
    required String plaintext,
    required SecretKey workspaceKey,
    required int kid,
    required String workspaceId,
    required String table,
    required String rowId,
    required String field,
    required String hlc,
    /// Test-only determinism. Never pass this in production — a reused
    /// salt+nonce under the same key is catastrophic for AES-GCM.
    List<int>? salt,
    List<int>? nonce,
  }) async {
    final s = salt ?? _randomBytes(_saltLen);
    final n = nonce ?? _randomBytes(_nonceLen);
    if (s.length != _saltLen) throw ArgumentError('salt must be $_saltLen bytes');
    if (n.length != _nonceLen) {
      throw ArgumentError('nonce must be $_nonceLen bytes');
    }

    final rowKey = await _deriveRowKey(
      workspaceKey: workspaceKey,
      salt: s,
      table: table,
      rowId: rowId,
      field: field,
    );

    final box = await _aead.encrypt(
      utf8.encode(plaintext),
      secretKey: rowKey,
      nonce: n,
      aad: _aad(
        workspaceId: workspaceId,
        kid: kid,
        table: table,
        rowId: rowId,
        field: field,
        hlc: hlc,
      ),
    );

    final out = BytesBuilder()
      ..addByte(_version)
      ..addByte(_algAesGcm)
      ..add(_u32be(kid))
      ..add(s)
      ..add(n)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return base64.encode(out.toBytes());
  }

  /// Decrypt a sealed field.
  ///
  /// Throws [EnvelopeError] on any failure — a wrong key, a tampered payload, a
  /// replayed ciphertext from another row or another HLC. It NEVER returns a
  /// partial or empty string: silently handing back "" would look like an empty
  /// note rather than a broken one, and the user would think their data was lost
  /// rather than unreadable.
  static Future<String> open({
    required String sealed,
    required SecretKey workspaceKey,
    required String workspaceId,
    required String table,
    required String rowId,
    required String field,
    required String hlc,
  }) async {
    final Uint8List raw;
    try {
      raw = base64.decode(sealed);
    } catch (_) {
      throw const EnvelopeError('envelope is not valid base64');
    }

    const header = 2 + 4 + _saltLen + _nonceLen;
    if (raw.length < header + 16) {
      throw const EnvelopeError('envelope is truncated');
    }
    if (raw[0] != _version) {
      throw EnvelopeError('unsupported envelope version ${raw[0]}');
    }
    if (raw[1] != _algAesGcm) {
      throw EnvelopeError('unsupported envelope alg ${raw[1]}');
    }

    final kid = _readU32be(raw, 2);
    final salt = raw.sublist(6, 6 + _saltLen);
    final nonce = raw.sublist(6 + _saltLen, header);
    final rest = raw.sublist(header);
    final cipherText = rest.sublist(0, rest.length - 16);
    final mac = Mac(rest.sublist(rest.length - 16));

    final rowKey = await _deriveRowKey(
      workspaceKey: workspaceKey,
      salt: salt,
      table: table,
      rowId: rowId,
      field: field,
    );

    try {
      final clear = await _aead.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: rowKey,
        aad: _aad(
          workspaceId: workspaceId,
          kid: kid,
          table: table,
          rowId: rowId,
          field: field,
          hlc: hlc,
        ),
      );
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      throw const EnvelopeError(
        'ciphertext failed authentication — wrong key, tampered payload, or a '
        'row/clock mismatch',
      );
    }
  }

  /// The key generation a sealed payload was written with, without decrypting.
  /// The sync engine uses it to fetch the right wrapped key.
  static int kidOf(String sealed) {
    final raw = base64.decode(sealed);
    if (raw.length < 6) throw const EnvelopeError('envelope is truncated');
    return _readU32be(raw, 2);
  }

  static Uint8List _u32be(int v) => Uint8List(4)
    ..[0] = (v >> 24) & 0xff
    ..[1] = (v >> 16) & 0xff
    ..[2] = (v >> 8) & 0xff
    ..[3] = v & 0xff;

  static int _readU32be(Uint8List b, int o) =>
      (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];

  static final _rng = SecureRandom.fast;

  static Uint8List _randomBytes(int n) {
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = _rng.nextUint32() & 0xff;
    }
    return out;
  }
}

class EnvelopeError implements Exception {
  const EnvelopeError(this.message);
  final String message;
  @override
  String toString() => 'EnvelopeError: $message';
}
