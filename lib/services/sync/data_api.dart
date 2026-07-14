import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'neon_auth.dart';

/// Thin client for the Neon Data API (PostgREST), authenticated per request with
/// the user's JWT.
///
/// Every call carries a fresh-enough JWT from [NeonAuth]; the server validates
/// it against the JWKS and RLS scopes every row to the caller's workspaces. This
/// client therefore does NO tenancy checking itself — it cannot, and must not
/// try. The database is the boundary.
class DataApi {
  DataApi({
    required this.baseUrl,
    required this.auth,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final NeonAuth auth;
  final http.Client _client;

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer ${await auth.jwt()}',
      };

  /// GET a table/view with PostgREST query params (e.g. filters, order, limit).
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, String> query = const {},
  }) async {
    final uri = Uri.parse('$baseUrl/$table').replace(queryParameters: {
      if (query.isEmpty) 'select': '*',
      ...query,
    });
    final resp = await _send(() async =>
        _client.get(uri, headers: await _headers()));
    return (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
  }

  /// Upsert rows. `on_conflict` + `Prefer: resolution=merge-duplicates` is how
  /// PostgREST does an idempotent write, which the sync push relies on.
  Future<void> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    required String onConflict,
  }) async {
    if (rows.isEmpty) return;
    final uri = Uri.parse('$baseUrl/$table')
        .replace(queryParameters: {'on_conflict': onConflict});
    await _send(() async => _client.post(
          uri,
          headers: {
            ...await _headers(),
            'Prefer': 'resolution=merge-duplicates,return=minimal',
          },
          body: jsonEncode(rows),
        ));
  }

  /// Call a Postgres function (e.g. create_workspace, accept_invite).
  Future<dynamic> rpc(String fn, Map<String, dynamic> args) async {
    final resp = await _send(() async => _client.post(
          Uri.parse('$baseUrl/rpc/$fn'),
          headers: await _headers(),
          body: jsonEncode(args),
        ));
    if (resp.body.isEmpty) return null;
    return jsonDecode(resp.body);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() run,
  ) async {
    final http.Response resp;
    try {
      resp = await run().timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const SyncTransientError('Timed out talking to the sync server.');
    } on IOException catch (e) {
      // Offline is normal and expected — the app is local-first. Callers treat
      // this as "try again later", never as data loss.
      throw SyncTransientError('Offline: $e');
    }

    if (resp.statusCode == 401) {
      // JWT rejected. Surface distinctly so the engine can force a re-mint or a
      // re-login rather than retry forever.
      throw const SyncAuthError('The sync session was rejected.');
    }
    if (resp.statusCode == 403) {
      // RLS said no. This is a bug or a race (e.g. removed from a workspace),
      // not something a retry fixes.
      throw SyncPermanentError('Sync permission denied (${resp.statusCode}).');
    }
    if (resp.statusCode >= 500) {
      throw SyncTransientError('Sync server error (${resp.statusCode}).');
    }
    if (resp.statusCode >= 400) {
      throw SyncPermanentError(
          'Sync request rejected (${resp.statusCode}): '
          '${resp.body.length > 200 ? resp.body.substring(0, 200) : resp.body}');
    }
    return resp;
  }
}

/// Retryable: offline, timeout, 5xx. The outbox keeps the change and tries again.
class SyncTransientError implements Exception {
  const SyncTransientError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The JWT was rejected — re-mint or re-login, do not spin.
class SyncAuthError implements Exception {
  const SyncAuthError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Not retryable: 4xx other than 401. Retrying sends the same bad request.
class SyncPermanentError implements Exception {
  const SyncPermanentError(this.message);
  final String message;
  @override
  String toString() => message;
}
