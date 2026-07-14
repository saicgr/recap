import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'cloud_proxy.dart';

/// The slice of secure storage [InstallIdentity] needs.
///
/// Injected rather than used directly so this is unit-testable: `flutter test`
/// has no MethodChannel, and flutter_secure_storage is a plugin.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Production [SecretStore] — iOS Keychain / Android Keystore.
class SecureStorageSecretStore implements SecretStore {
  const SecureStorageSecretStore(
      [this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// The app's anonymous identity with the Render proxy.
///
/// Two values, both in the keychain:
///   - `install_id`: a random, stable, url-safe id. NOT a secret; it is sent in
///     the clear as X-Install-Id.
///   - `install_hmac_token`: HMAC(installId, PEPPER), issued by /v1/register.
///     Only the server can produce it, which is what makes a forged token 401.
///
/// This is NOT an account. There is no email, no password, no sign-in — Recap
/// requires no account to record, transcribe, or summarize. It exists purely so
/// the proxy can rate-limit and meter an install, and so a random string cannot
/// drain the owner's Gemini bill.
///
/// Registration is LAZY and single-flighted: nothing here touches the network
/// until the user explicitly asks for a cloud summary. Registering at launch
/// would be a background ping, which the Karpathy invariants forbid outright.
class InstallIdentity {
  InstallIdentity({
    required this.proxyUrlProvider,
    SecretStore? store,
    http.Client? client,
    Duration? timeout,
  })  : _store = store ?? const SecureStorageSecretStore(),
        _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 20);

  static const kInstallIdKey = 'install_id';
  static const kTokenKey = 'install_hmac_token';

  /// The pre-Render key: a locally generated random token the old Cloudflare
  /// Worker accepted because it validated nothing. Render 401s it, so it is
  /// migrated to an install_id and then deleted, in case anything ever tried to
  /// send it as a token again.
  static const kLegacyTokenKey = 'install_token';

  final String Function() proxyUrlProvider;
  final SecretStore _store;
  final http.Client _client;
  final Duration _timeout;

  String? _cachedId;
  String? _cachedToken;
  Future<String>? _inFlightRegistration;

  /// Stable install id, created on first use. Matches the server's
  /// `/^[A-Za-z0-9_-]{16,128}$/`.
  Future<String> installId() async {
    final cached = _cachedId;
    if (cached != null) return cached;

    final existing = await _readOrThrow(kInstallIdKey);
    if (existing != null && existing.isNotEmpty) {
      return _cachedId = existing;
    }

    // Adopt the legacy Worker token as the install id: it is already a 64-hex
    // random string, which is a valid install-id shape, and reusing it keeps a
    // user's proxy rate-limit bucket stable across the migration.
    final legacy = await _readOrThrow(kLegacyTokenKey);
    final id = (legacy != null && _isValidInstallId(legacy))
        ? legacy
        : _generateInstallId();

    await _writeOrThrow(kInstallIdKey, id);
    if (legacy != null) {
      // It is not a valid Render token and never will be.
      await _store.delete(kLegacyTokenKey).catchError((_) {});
    }
    return _cachedId = id;
  }

  /// The server-issued token, registering on first use.
  ///
  /// Single-flighted: two concurrent cloud summaries must not both POST
  /// /v1/register (the endpoint is per-IP rate limited, and a double
  /// registration is pure waste).
  Future<String> token({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cachedToken;
      if (cached != null) return cached;
      final stored = await _readOrThrow(kTokenKey);
      if (stored != null && stored.isNotEmpty) return _cachedToken = stored;
    }
    return _inFlightRegistration ??= _register().whenComplete(() {
      _inFlightRegistration = null;
    });
  }

  Future<String> _register() async {
    final base = requireConfiguredProxyUrl(proxyUrlProvider());
    final id = await installId();

    final http.Response resp;
    try {
      resp = await _client
          .post(
            Uri.parse('$base/v1/register'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'install_id': id}),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw CloudError(CloudFailureKind.timeout,
          'Timed out reaching the cloud proxy. Check your connection.');
    } on IOException catch (e) {
      // Covers SocketException, HandshakeException, TlsException, and every
      // other transport failure — a captive portal throws HandshakeException,
      // not SocketException, and that is the common real-world case.
      throw CloudError(CloudFailureKind.offline,
          'Could not reach the cloud proxy: ${truncateForError('$e')}');
    }

    if (resp.statusCode == 429) {
      throw CloudError(CloudFailureKind.rateLimited,
          'Too many registration attempts. Try again in a little while.');
    }
    if (resp.statusCode >= 400) {
      throw CloudError(
        CloudFailureKind.server,
        'Cloud registration failed (HTTP ${resp.statusCode}): '
        '${truncateForError(resp.body)}',
      );
    }

    final String token;
    try {
      token =
          (jsonDecode(resp.body) as Map<String, dynamic>)['token'] as String;
    } catch (_) {
      throw CloudError(CloudFailureKind.emptyResponse,
          'Cloud registration returned no token.');
    }
    if (token.isEmpty) {
      throw CloudError(CloudFailureKind.emptyResponse,
          'Cloud registration returned an empty token.');
    }

    await _writeOrThrow(kTokenKey, token);
    return _cachedToken = token;
  }

  /// Headers every authenticated proxy call must carry.
  Future<Map<String, String>> authHeaders({bool forceRefresh = false}) async {
    return {
      'Authorization': 'Bearer ${await token(forceRefresh: forceRefresh)}',
      'X-Install-Id': await installId(),
    };
  }

  // -- keychain I/O -----------------------------------------------------------
  //
  // Keychain reads DO fail in the wild: on Android a Keystore key does not
  // survive a backup/restore onto a new device, so the encrypted blob decrypts
  // to garbage and throws. Swallowing that and silently minting a new identity
  // would quietly reset the user's quota bucket; we surface it instead.

  Future<String?> _readOrThrow(String key) async {
    try {
      return await _store.read(key);
    } catch (e) {
      throw CloudError(CloudFailureKind.server,
          'Secure storage is unreadable (key "$key"): ${truncateForError('$e')}');
    }
  }

  Future<void> _writeOrThrow(String key, String value) async {
    try {
      await _store.write(key, value);
    } catch (e) {
      throw CloudError(CloudFailureKind.server,
          'Secure storage is unwritable (key "$key"): ${truncateForError('$e')}');
    }
  }

  static bool _isValidInstallId(String s) =>
      RegExp(r'^[A-Za-z0-9_-]{16,128}$').hasMatch(s);

  static String _generateInstallId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
