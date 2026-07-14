import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recap/services/sync/crypto/invite.dart';
import 'package:recap/services/sync/crypto/key_wrap.dart';

/// The invite flow's security rests on splitting the token into two independent
/// HKDF outputs — the server sees `lookup`, never `kek`. These tests prove the
/// invitee can recover the key from the token while the server, holding only
/// what it is given, cannot.
void main() {
  test('a token round-trips the workspace key (inviter -> invitee)', () async {
    final kws = await KeyWrap.generateWorkspaceKey();
    final token = Invite.newToken();

    final wrapped = await Invite.wrapKey(token: token, workspaceKey: kws);
    final recovered = await Invite.unwrapKey(token: token, wrapped: wrapped);

    expect(await recovered.extractBytes(), await kws.extractBytes());
  });

  test('lookup and kek are independent — lookup cannot unwrap', () async {
    // If lookup could unwrap, the server (which holds lookup) would hold the
    // key. This is the whole point of the split.
    final kws = await KeyWrap.generateWorkspaceKey();
    final token = Invite.newToken();
    final wrapped = await Invite.wrapKey(token: token, workspaceKey: kws);

    final lookup = await Invite.lookup(token);
    // Treating the lookup value as if it were the token must NOT recover the key.
    await expectLater(
      Invite.unwrapKey(token: lookup, wrapped: wrapped),
      throwsA(isA<InviteError>()),
    );
  });

  test('a different token cannot unwrap', () async {
    final kws = await KeyWrap.generateWorkspaceKey();
    final wrapped =
        await Invite.wrapKey(token: Invite.newToken(), workspaceKey: kws);
    await expectLater(
      Invite.unwrapKey(token: Invite.newToken(), wrapped: wrapped),
      throwsA(isA<InviteError>()),
    );
  });

  test('lookup is deterministic for a token, and differs across tokens',
      () async {
    final t1 = Invite.newToken();
    final t2 = Invite.newToken();
    expect(await Invite.lookup(t1), await Invite.lookup(t1)); // stable
    expect(await Invite.lookup(t1), isNot(await Invite.lookup(t2)));
  });

  test('tokens are url-safe (they ride in a link fragment)', () {
    for (var i = 0; i < 50; i++) {
      final t = Invite.newToken();
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(t), isTrue, reason: t);
    }
  });

  test('a tampered wrapped blob is rejected, not silently mis-unwrapped',
      () async {
    final kws = await KeyWrap.generateWorkspaceKey();
    final token = Invite.newToken();
    final wrapped = await Invite.wrapKey(token: token, workspaceKey: kws);
    // Corrupt an actual ciphertext byte (past the 12-byte nonce), then re-encode
    // — a reliable tamper that AES-GCM's tag must catch.
    final raw = base64.decode(wrapped);
    raw[13] ^= 0x01;
    await expectLater(
      Invite.unwrapKey(token: token, wrapped: base64.encode(raw)),
      throwsA(isA<InviteError>()),
    );
  });
}
