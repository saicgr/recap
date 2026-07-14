import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recap/services/sync/crypto/envelope.dart';
import 'package:recap/services/sync/crypto/key_wrap.dart';
import 'package:recap/services/sync/hlc.dart';

/// The crypto core is the piece that must be right. Neon and R2 store ciphertext
/// only, and the operator must not be able to read user content — so these tests
/// attack the envelope, not just exercise it.
void main() {
  late SecretKey kws;

  setUp(() async {
    kws = await KeyWrap.generateWorkspaceKey();
  });

  Future<String> seal(
    String text, {
    String table = 'meetings',
    String rowId = 'row-1',
    String field = 'title',
    String hlc = '000000000000001-00000-node',
    String workspaceId = 'ws-1',
    int kid = 1,
    SecretKey? key,
  }) =>
      Envelope.seal(
        plaintext: text,
        workspaceKey: key ?? kws,
        kid: kid,
        workspaceId: workspaceId,
        table: table,
        rowId: rowId,
        field: field,
        hlc: hlc,
      );

  Future<String> open(
    String sealed, {
    String table = 'meetings',
    String rowId = 'row-1',
    String field = 'title',
    String hlc = '000000000000001-00000-node',
    String workspaceId = 'ws-1',
    SecretKey? key,
  }) =>
      Envelope.open(
        sealed: sealed,
        workspaceKey: key ?? kws,
        workspaceId: workspaceId,
        table: table,
        rowId: rowId,
        field: field,
        hlc: hlc,
      );

  group('envelope round-trip', () {
    test('seals and opens', () async {
      final s = await seal('Q3 board review');
      expect(await open(s), 'Q3 board review');
    });

    test('handles unicode and long text', () async {
      final text = '会議のメモ — café ☕️ ' * 200;
      expect(await open(await seal(text)), text);
    });

    test('the same plaintext seals to different bytes each time', () async {
      // Fresh salt+nonce per row. Otherwise an observer could tell that two rows
      // hold the same value just by comparing ciphertexts.
      final a = await seal('same');
      final b = await seal('same');
      expect(a, isNot(b));
    });

    test('kid is readable without the key', () async {
      final s = await seal('x', kid: 7);
      expect(Envelope.kidOf(s), 7);
    });
  });

  group('the operator cannot read or move ciphertext', () {
    test('a different workspace key cannot open it', () async {
      final s = await seal('secret');
      final other = await KeyWrap.generateWorkspaceKey();
      await expectLater(
          open(s, key: other), throwsA(isA<EnvelopeError>()));
    });

    test('a ciphertext replayed into a DIFFERENT ROW fails', () async {
      // Without the row in the AAD, the operator could copy your salary line
      // into someone else's meeting and it would decrypt cleanly.
      final s = await seal('secret', rowId: 'row-1');
      await expectLater(
          open(s, rowId: 'row-2'), throwsA(isA<EnvelopeError>()));
    });

    test('a ciphertext replayed into a different FIELD fails', () async {
      final s = await seal('secret', field: 'title');
      await expectLater(
          open(s, field: 'body'), throwsA(isA<EnvelopeError>()));
    });

    test('a ciphertext replayed into another WORKSPACE fails', () async {
      final s = await seal('secret', workspaceId: 'ws-1');
      await expectLater(
          open(s, workspaceId: 'ws-2'), throwsA(isA<EnvelopeError>()));
    });

    test('THE REPLAY ATTACK: an OLD ciphertext cannot be swapped back in',
        () async {
      // This is why the HLC is in the AAD. Without it the operator could serve
      // yesterday's version of a row: it is genuinely our ciphertext, it would
      // decrypt cleanly, and the user would silently see stale content with no
      // indication anything was wrong.
      final oldRow = await seal('old value', hlc: '000000000000001-00000-n');
      await expectLater(
        open(oldRow, hlc: '000000000000009-00000-n'),
        throwsA(isA<EnvelopeError>()),
      );
    });

    test('a flipped bit is detected, not silently decrypted', () async {
      final s = await seal('secret');
      final bytes = s.codeUnits.toList();
      bytes[bytes.length - 4] ^= 0x01; // corrupt near the tag
      await expectLater(
        open(String.fromCharCodes(bytes)),
        throwsA(isA<EnvelopeError>()),
      );
    });

    test('garbage input throws instead of returning empty', () async {
      // Returning "" would look like an empty note rather than a broken one, and
      // the user would think their data was lost rather than unreadable.
      await expectLater(open('not base64!!'), throwsA(isA<EnvelopeError>()));
      await expectLater(open('AAAA'), throwsA(isA<EnvelopeError>()));
    });
  });

  group('workspace key wrapping', () {
    test('a member can unwrap a key sealed to them', () async {
      final alice = await KeyWrap.generateIdentity();
      final wrapped = await KeyWrap.wrapFor(
        workspaceKey: kws,
        recipientPublicKey: await alice.extractPublicKey(),
      );
      final recovered =
          await KeyWrap.unwrap(wrapped: wrapped, myIdentity: alice);
      expect(await recovered.extractBytes(), await kws.extractBytes());
    });

    test('another member CANNOT unwrap a key sealed to someone else', () async {
      final alice = await KeyWrap.generateIdentity();
      final mallory = await KeyWrap.generateIdentity();
      final wrapped = await KeyWrap.wrapFor(
        workspaceKey: kws,
        recipientPublicKey: await alice.extractPublicKey(),
      );
      await expectLater(
        KeyWrap.unwrap(wrapped: wrapped, myIdentity: mallory),
        throwsA(isA<KeyWrapError>()),
      );
    });

    test('wrapping the same key twice yields different blobs', () async {
      // Ephemeral-static X25519: otherwise you could tell two members hold the
      // same workspace key just by comparing their wrapped rows.
      final alice = await KeyWrap.generateIdentity();
      final pub = await alice.extractPublicKey();
      final a = await KeyWrap.wrapFor(workspaceKey: kws, recipientPublicKey: pub);
      final b = await KeyWrap.wrapFor(workspaceKey: kws, recipientPublicKey: pub);
      expect(a, isNot(b));
    });

    test('ROTATION: a removed member cannot read the new generation', () async {
      // Deleting a membership row stops the SERVER serving them rows, but they
      // still hold the old K_ws — anything they already fetched stays readable.
      // Revocation without rotation is theatre. This proves rotation works.
      final removed = await KeyWrap.generateIdentity();
      final oldWrapped = await KeyWrap.wrapFor(
        workspaceKey: kws,
        recipientPublicKey: await removed.extractPublicKey(),
      );
      final oldKey =
          await KeyWrap.unwrap(wrapped: oldWrapped, myIdentity: removed);

      // Admin re-keys the workspace (kid 2) and does NOT wrap it for them.
      final kws2 = await KeyWrap.generateWorkspaceKey();
      final newRow = await seal('post-removal secret', kid: 2, key: kws2);

      await expectLater(
        open(newRow, key: oldKey),
        throwsA(isA<EnvelopeError>()),
        reason: 'the old key must not open the new generation',
      );
    });

    test('safety numbers differ per identity and are stable', () async {
      final a = await KeyWrap.generateIdentity();
      final b = await KeyWrap.generateIdentity();
      final fa = await KeyWrap.safetyNumber(await a.extractPublicKey());
      final fb = await KeyWrap.safetyNumber(await b.extractPublicKey());
      expect(fa, isNot(fb));
      expect(await KeyWrap.safetyNumber(await a.extractPublicKey()), fa);
    });
  });

  group('HLC', () {
    test('lexicographic order == chronological order', () async {
      // The padding is load-bearing: the server does ORDER BY hlc as a string.
      const a = Hlc(millis: 900, counter: 0, nodeId: 'n1');
      const b = Hlc(millis: 1000, counter: 0, nodeId: 'n1');
      expect(a.toString().compareTo(b.toString()) < 0, isTrue);
    });

    test('ticks forward even when the wall clock does not move', () {
      var h = Hlc.zero('n1');
      h = h.tick(nowMs: 1000);
      final h2 = h.tick(nowMs: 1000); // same millisecond
      expect(h2 > h, isTrue);
      expect(h2.counter, 1);
    });

    test('a device with a SLOW clock still sorts its reply after the message',
        () {
      // The whole point. Our clock says 500; a peer edited at 1000. Our next
      // edit must still sort AFTER theirs, or our reply would be silently
      // discarded as "older".
      var mine = Hlc.zero('slow-phone');
      const theirs = Hlc(millis: 1000, counter: 0, nodeId: 'fast');
      mine = mine.receive(theirs, nowMs: 500);
      final myReply = mine.tick(nowMs: 500);
      expect(myReply > theirs, isTrue);
    });

    test('refuses a wildly-future remote clock instead of poisoning ours', () {
      // Accepting it would drag our clock years forward, permanently: nothing
      // could ever be edited "after" that row again.
      final mine = Hlc.zero('n1');
      final broken = Hlc(
        millis: DateTime(2099).millisecondsSinceEpoch,
        counter: 0,
        nodeId: 'broken',
      );
      expect(
        () => mine.receive(broken, nowMs: DateTime(2026).millisecondsSinceEpoch),
        throwsStateError,
      );
    });

    test('round-trips through parse, including a uuid nodeId with hyphens', () {
      const h = Hlc(
        millis: 1752438000000,
        counter: 3,
        nodeId: 'a1b2-c3d4-e5f6',
      );
      expect(Hlc.parse(h.toString()), h);
    });

    test('nodeId breaks ties so peers agree deterministically', () {
      // Without this, two concurrent edits could compare equal and different
      // devices would merge them in different orders.
      const a = Hlc(millis: 1, counter: 1, nodeId: 'aaa');
      const b = Hlc(millis: 1, counter: 1, nodeId: 'bbb');
      expect(a < b, isTrue);
    });
  });
}
