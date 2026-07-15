import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recap/services/sync/account_store.dart';

/// In-memory FlutterSecureStorage stand-in.
class _MemStorage implements FlutterSecureStorage {
  final Map<String, String> data = {};

  @override
  Future<String?> read({
    required String key,
    dynamic iOptions,
    dynamic aOptions,
    dynamic lOptions,
    dynamic webOptions,
    dynamic mOptions,
    dynamic wOptions,
  }) async => data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    dynamic iOptions,
    dynamic aOptions,
    dynamic lOptions,
    dynamic webOptions,
    dynamic mOptions,
    dynamic wOptions,
  }) async {
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    dynamic iOptions,
    dynamic aOptions,
    dynamic lOptions,
    dynamic webOptions,
    dynamic mOptions,
    dynamic wOptions,
  }) async => data.remove(key);

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late AccountStore store;

  setUp(() => store = AccountStore(storage: _MemStorage()));

  const alice = Account(
    userId: 'u-alice',
    email: 'a@x.com',
    sessionToken: 'sess-a',
  );
  const bob = Account(
    userId: 'u-bob',
    email: 'b@x.com',
    sessionToken: 'sess-b',
  );

  test('two accounts coexist; second does not clobber first', () async {
    // The reason to namespace by userId from day one: single-account code would
    // overwrite alice's session when bob signs in.
    await store.upsert(alice);
    await store.upsert(bob);

    final accounts = await store.accounts();
    expect(accounts.map((a) => a.userId), containsAll(['u-alice', 'u-bob']));
    expect(
      (await store.active())!.userId,
      'u-bob',
      reason: 'the most recent sign-in is active',
    );
  });

  test('switching active account', () async {
    await store.upsert(alice);
    await store.upsert(bob);
    await store.setActive('u-alice');
    expect((await store.active())!.email, 'a@x.com');
  });

  test(
    're-signing an existing account updates its session, not a duplicate',
    () async {
      await store.upsert(alice);
      await store.upsert(
        const Account(
          userId: 'u-alice',
          email: 'a@x.com',
          sessionToken: 'sess-a2',
        ),
      );
      final accounts = await store.accounts();
      expect(accounts.length, 1);
      expect(accounts.single.sessionToken, 'sess-a2');
    },
  );

  test('removing the active account promotes another', () async {
    await store.upsert(alice);
    await store.upsert(bob); // bob active
    await store.remove('u-bob');
    expect((await store.active())!.userId, 'u-alice');
  });

  test('removing the last account leaves none active', () async {
    await store.upsert(alice);
    await store.remove('u-alice');
    expect(await store.active(), isNull);
    expect(await store.accounts(), isEmpty);
  });

  test('setActive on an unknown account throws', () async {
    await store.upsert(alice);
    expect(() => store.setActive('nobody'), throwsArgumentError);
  });
}
