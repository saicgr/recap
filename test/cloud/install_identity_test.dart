import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recap/services/cloud/cloud_proxy.dart';
import 'package:recap/services/cloud/install_identity.dart';

/// In-memory [SecretStore]. Can be told to fail, because keychain reads DO fail
/// in the wild (an Android Keystore key does not survive a restore onto a new
/// device, so the blob decrypts to garbage and throws).
class FakeStore implements SecretStore {
  FakeStore([Map<String, String>? seed]) : data = {...?seed};

  final Map<String, String> data;
  bool failReads = false;

  @override
  Future<String?> read(String key) async {
    if (failReads) throw Exception('keystore unreadable');
    return data[key];
  }

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  const base = 'https://recap-proxy.onrender.com';

  InstallIdentity build(
    FakeStore store,
    http.Client client, {
    String url = base,
  }) =>
      InstallIdentity(
        proxyUrlProvider: () => url,
        store: store,
        client: client,
      );

  group('install id', () {
    test('mints a stable id matching the server contract', () async {
      final store = FakeStore();
      var registers = 0;
      final id = build(store, MockClient((_) async {
        registers++;
        return http.Response(jsonEncode({'token': 'tok'}), 200);
      }));

      final a = await id.installId();
      final b = await id.installId();
      expect(a, b, reason: 'the id must be stable across calls');
      // The server validates /^[A-Za-z0-9_-]{16,128}$/ — an id it would reject
      // makes every cloud call 401 forever.
      expect(RegExp(r'^[A-Za-z0-9_-]{16,128}$').hasMatch(a), isTrue);
      expect(registers, 0, reason: 'minting an id must not touch the network');
    });

    test('adopts the legacy Worker token as the install id, then deletes it',
        () async {
      final legacy = 'a' * 64; // the old locally-generated random hex
      final store = FakeStore({InstallIdentity.kLegacyTokenKey: legacy});
      final id = build(store, MockClient((_) async => http.Response('{}', 500)));

      expect(await id.installId(), legacy,
          reason: 'reusing it keeps the rate-limit bucket stable');
      // It is NOT a valid Render token (the server would 401 it), so it must not
      // survive where something could send it as one.
      expect(store.data.containsKey(InstallIdentity.kLegacyTokenKey), isFalse);
      expect(store.data[InstallIdentity.kInstallIdKey], legacy);
    });

    test('a keychain read failure surfaces instead of silently re-minting',
        () async {
      // Silently minting a new identity would quietly reset the user's quota
      // bucket and hide a real device problem.
      final store = FakeStore()..failReads = true;
      final id = build(store, MockClient((_) async => http.Response('{}', 200)));
      await expectLater(
        id.installId(),
        throwsA(isA<CloudError>()
            .having((e) => e.kind, 'kind', CloudFailureKind.server)),
      );
    });
  });

  group('registration', () {
    test('registers once and caches the token', () async {
      final store = FakeStore();
      var calls = 0;
      final id = build(store, MockClient((req) async {
        calls++;
        expect(req.url.path, '/v1/register');
        return http.Response(jsonEncode({'token': 'server-issued'}), 200);
      }));

      expect(await id.token(), 'server-issued');
      expect(await id.token(), 'server-issued');
      expect(calls, 1, reason: 'the token must be cached, not re-fetched');
      expect(store.data[InstallIdentity.kTokenKey], 'server-issued');
    });

    test('concurrent callers trigger only ONE registration', () async {
      // /v1/register is per-IP rate limited; two simultaneous cloud summaries
      // must not both register.
      final store = FakeStore();
      var calls = 0;
      final id = build(store, MockClient((_) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response(jsonEncode({'token': 'once'}), 200);
      }));

      final results = await Future.wait([id.token(), id.token(), id.token()]);
      expect(results, ['once', 'once', 'once']);
      expect(calls, 1, reason: 'registration must be single-flighted');
    });

    test('authHeaders sends BOTH the bearer and X-Install-Id', () async {
      // Render 401s a request missing either one.
      final store = FakeStore();
      final id = build(store,
          MockClient((_) async => http.Response(jsonEncode({'token': 't'}), 200)));

      final h = await id.authHeaders();
      expect(h['Authorization'], 'Bearer t');
      expect(h['X-Install-Id'], isNotEmpty);
    });

    test('a 429 on register is reported as rate-limited, not a generic error',
        () async {
      final id = build(FakeStore(),
          MockClient((_) async => http.Response('{"error":"rate limited"}', 429)));
      await expectLater(
        id.token(),
        throwsA(isA<CloudError>()
            .having((e) => e.kind, 'kind', CloudFailureKind.rateLimited)),
      );
    });

    test('an empty token body is rejected rather than cached', () async {
      final store = FakeStore();
      final id = build(store,
          MockClient((_) async => http.Response(jsonEncode({'token': ''}), 200)));
      await expectLater(
        id.token(),
        throwsA(isA<CloudError>()
            .having((e) => e.kind, 'kind', CloudFailureKind.emptyResponse)),
      );
      expect(store.data.containsKey(InstallIdentity.kTokenKey), isFalse);
    });
  });

  group('proxy url', () {
    test('an unconfigured url throws instead of dialling a dead host', () {
      expect(() => requireConfiguredProxyUrl(''),
          throwsA(isA<CloudError>()
              .having((e) => e.kind, 'kind', CloudFailureKind.notConfigured)));
      expect(() => requireConfiguredProxyUrl(kPlaceholderProxyUrl),
          throwsA(isA<CloudError>()));
    });

    test('a trailing slash cannot produce a double slash', () {
      expect(requireConfiguredProxyUrl('$base/'), base);
    });
  });
}
