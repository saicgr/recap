import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Identity against Neon Auth (Better Auth), driven over plain REST.
///
/// There is no Better Auth SDK for Dart, so this hand-rolls the flow. It is NOT
/// guesswork — it was verified end to end against the live project with curl
/// (see ~/.claude memory `neon-sync-proven`). The non-obvious parts, which cost
/// a day if you rediscover them:
///
///   1. POST /sign-in/email returns an OPAQUE SESSION TOKEN, not a JWT, plus a
///      Set-Cookie. Requests need an `Origin` header (Better Auth CSRF).
///   2. GET /token mints the actual EdDSA JWT — but ONLY when the session is
///      presented as a COOKIE. Bearer does not work on /token.
///   3. The JWT expires in ~15 minutes. The Data API validates it against the
///      JWKS; an expired one 401s. So re-mint from the still-valid session
///      before expiry rather than forcing a re-login.
///
/// Sign-in is OPTIONAL and gates nothing (moat #3): the app records,
/// transcribes and summarizes with no account. This exists only so that a user
/// who WANTS sync or sharing can have it.
class NeonAuth {
  NeonAuth({
    required this.authBaseUrl,
    http.Client? client,
    Duration? refreshLeeway,
  }) : _client = client ?? http.Client(),
       _refreshLeeway = refreshLeeway ?? const Duration(minutes: 2);

  /// e.g. https://<ep>.neonauth.<region>.aws.neon.tech/neondb/auth
  final String authBaseUrl;
  final http.Client _client;
  final Duration _refreshLeeway;

  /// A synthetic origin. Native clients send none, and Better Auth's CSRF check
  /// wants one; it must be in the project's trusted origins.
  static const _origin = 'https://app.recap.so';

  String? _sessionToken;
  String? _jwt;
  DateTime? _jwtExpiry;
  Future<String>? _inFlightJwt;

  String? get sessionToken => _sessionToken;
  bool get isSignedIn => _sessionToken != null;

  /// Restore a persisted session (from secure storage) without a network call.
  void restoreSession(String sessionToken) => _sessionToken = sessionToken;

  Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json',
    'Origin': _origin,
  };

  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? name,
  }) => _session('/sign-up/email', {
    'email': email,
    'password': password,
    if (name != null) 'name': name,
  });

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) => _session('/sign-in/email', {'email': email, 'password': password});

  Future<AuthResult> _session(String path, Map<String, dynamic> body) async {
    final http.Response resp;
    try {
      resp = await _client
          .post(
            Uri.parse('$authBaseUrl$path'),
            headers: _jsonHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const AuthException('Timed out reaching the sign-in server.');
    } on IOException catch (e) {
      throw AuthException('Could not reach the sign-in server: $e');
    }

    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw const AuthException('Incorrect email or password.');
    }
    if (resp.statusCode == 409 || resp.statusCode == 422) {
      throw const AuthException('That email is already registered.');
    }
    if (resp.statusCode >= 400) {
      throw AuthException(
        'Sign-in failed (HTTP ${resp.statusCode}). Please try again.',
      );
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final token = json['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const AuthException('Sign-in returned no session.');
    }
    _sessionToken = token;
    _jwt = null;
    _jwtExpiry = null;

    final user = json['user'] as Map<String, dynamic>?;
    return AuthResult(
      sessionToken: token,
      userId: user?['id'] as String? ?? '',
      email: user?['email'] as String? ?? body['email'] as String,
    );
  }

  /// A valid JWT for the Data API, minting or re-minting as needed.
  ///
  /// Single-flighted so a burst of API calls does not fire N concurrent /token
  /// requests.
  Future<String> jwt() {
    final cached = _jwt;
    final exp = _jwtExpiry;
    if (cached != null &&
        exp != null &&
        DateTime.now().isBefore(exp.subtract(_refreshLeeway))) {
      return Future.value(cached);
    }
    return _inFlightJwt ??= _mintJwt().whenComplete(() => _inFlightJwt = null);
  }

  Future<String> _mintJwt() async {
    final session = _sessionToken;
    if (session == null) {
      throw const AuthException('Not signed in.');
    }

    final http.Response resp;
    try {
      resp = await _client
          .get(
            Uri.parse('$authBaseUrl/token'),
            // THE non-obvious bit: /token reads the session from the COOKIE, not a
            // bearer. The cookie name is Better Auth's default.
            headers: {
              'Origin': _origin,
              HttpHeaders.cookieHeader: 'better-auth.session_token=$session',
            },
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const AuthException('Timed out refreshing your session.');
    } on IOException catch (e) {
      throw AuthException('Could not refresh your session: $e');
    }

    if (resp.statusCode == 401) {
      // The session itself expired or was revoked — a real re-login is needed.
      _sessionToken = null;
      throw const AuthException('Your session expired. Please sign in again.');
    }
    if (resp.statusCode >= 400) {
      throw AuthException(
        'Could not get an access token (HTTP '
        '${resp.statusCode}).',
      );
    }

    final jwt =
        (jsonDecode(resp.body) as Map<String, dynamic>)['token'] as String?;
    if (jwt == null || jwt.isEmpty) {
      throw const AuthException('The auth server returned no access token.');
    }

    _jwt = jwt;
    _jwtExpiry =
        _expiryOf(jwt) ?? DateTime.now().add(const Duration(minutes: 14));
    return jwt;
  }

  /// Read `exp` from the JWT payload so we refresh proactively instead of after
  /// a 401.
  static DateTime? _expiryOf(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
              )
              as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      }
    } catch (_) {
      // Unparseable — fall back to the conservative default in the caller.
    }
    return null;
  }

  void signOut() {
    _sessionToken = null;
    _jwt = null;
    _jwtExpiry = null;
  }
}

class AuthResult {
  const AuthResult({
    required this.sessionToken,
    required this.userId,
    required this.email,
  });
  final String sessionToken;
  final String userId;
  final String email;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
