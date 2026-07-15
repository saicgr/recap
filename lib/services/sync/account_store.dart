import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// One signed-in account.
class Account {
  const Account({
    required this.userId,
    required this.email,
    required this.sessionToken,
  });

  final String userId;
  final String email;

  /// The Better Auth session token (opaque). The JWT is minted from it on
  /// demand and never persisted — a stored 15-minute JWT is stale almost
  /// immediately, whereas the session lasts.
  final String sessionToken;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'sessionToken': sessionToken,
  };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
    userId: j['userId'] as String,
    email: j['email'] as String,
    sessionToken: j['sessionToken'] as String,
  );
}

/// Stores every signed-in account, and which one is active.
///
/// "Multiple accounts signed in at once" is on the gap-list, so this is built
/// for it from the start rather than assuming one account and retrofitting.
/// Secrets are namespaced by `userId` from day one, so a second account can
/// never overwrite the first's session — the mistake that makes single-account
/// code painful to extend later.
///
/// Session tokens are the only thing persisted, and they live in the platform
/// keychain (flutter_secure_storage), not SharedPreferences.
class AccountStore {
  AccountStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accountsKey = 'sync_accounts_v1'; // json list
  static const _activeKey = 'sync_active_account_v1'; // userId

  Future<List<Account>> accounts() async {
    final raw = await _storage.read(key: _accountsKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Account?> active() async {
    final id = await _storage.read(key: _activeKey);
    if (id == null) return null;
    for (final a in await accounts()) {
      if (a.userId == id) return a;
    }
    return null;
  }

  /// Add or refresh an account, and make it active. Keyed by userId, so signing
  /// into an account already present just updates its session.
  Future<void> upsert(Account account) async {
    final list = (await accounts()).toList()
      ..removeWhere((a) => a.userId == account.userId)
      ..add(account);
    await _persist(list);
    await _storage.write(key: _activeKey, value: account.userId);
  }

  Future<void> setActive(String userId) async {
    final exists = (await accounts()).any((a) => a.userId == userId);
    if (!exists) {
      throw ArgumentError('No signed-in account with id $userId');
    }
    await _storage.write(key: _activeKey, value: userId);
  }

  /// Sign one account out. If it was active, the next remaining account becomes
  /// active (or none).
  Future<void> remove(String userId) async {
    final list = (await accounts()).where((a) => a.userId != userId).toList();
    await _persist(list);
    final activeId = await _storage.read(key: _activeKey);
    if (activeId == userId) {
      if (list.isEmpty) {
        await _storage.delete(key: _activeKey);
      } else {
        await _storage.write(key: _activeKey, value: list.first.userId);
      }
    }
  }

  Future<void> _persist(List<Account> list) async {
    if (list.isEmpty) {
      await _storage.delete(key: _accountsKey);
      return;
    }
    await _storage.write(
      key: _accountsKey,
      value: jsonEncode(list.map((a) => a.toJson()).toList()),
    );
  }
}
