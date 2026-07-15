/// Hybrid Logical Clock.
///
/// Sync needs a total order over edits made on devices that may be offline, and
/// whose wall clocks disagree. Wall-clock timestamps alone are not enough: a
/// phone whose clock is 10 minutes fast would win every conflict forever, and a
/// phone whose clock is behind would find its edits silently discarded. Users do
/// set their clocks wrong, and time zones and DST change under you.
///
/// An HLC keeps the physical clock (so ordering roughly matches reality and is
/// human-explicable) but adds a logical counter that breaks ties and, critically,
/// only ever moves forward. Seeing a remote timestamp from the future drags our
/// logical clock up to meet it, so subsequent local edits still sort after the
/// thing they were reacting to — even if our own clock is behind.
///
/// Wire format: `<millis>-<counter>-<nodeId>`, zero-padded so a plain STRING
/// comparison is the same as a semantic comparison. That matters: it means the
/// server can `ORDER BY hlc` and the sync engine can compare without parsing.
class Hlc implements Comparable<Hlc> {
  const Hlc({
    required this.millis,
    required this.counter,
    required this.nodeId,
  });

  final int millis;
  final int counter;

  /// Stable per-install id. Breaks ties between two devices that produced the
  /// same (millis, counter) — without it, two concurrent edits could compare
  /// equal and the merge would be non-deterministic across peers.
  final String nodeId;

  /// Guard against a wildly wrong remote clock. Accepting a timestamp years in
  /// the future would poison our clock permanently: every later local edit would
  /// be forced past it, and nothing could ever be edited "after" that row again.
  static const maxDriftMs = 60 * 60 * 1000; // 1 hour

  static Hlc zero(String nodeId) => Hlc(millis: 0, counter: 0, nodeId: nodeId);

  /// Local event. Physical time normally advances; if it has not (two edits in
  /// the same millisecond, or the clock went backwards), the counter carries the
  /// ordering.
  Hlc tick({required int nowMs}) {
    if (nowMs > millis) return Hlc(millis: nowMs, counter: 0, nodeId: nodeId);
    return Hlc(millis: millis, counter: counter + 1, nodeId: nodeId);
  }

  /// Merge a timestamp observed from a peer.
  ///
  /// Throws when the remote clock is beyond [maxDriftMs] in the future — a
  /// broken peer must not be allowed to poison our clock permanently.
  Hlc receive(Hlc remote, {required int nowMs}) {
    if (remote.millis > nowMs + maxDriftMs) {
      throw StateError(
        'Remote HLC is ${remote.millis - nowMs}ms in the future (max '
        '$maxDriftMs). Refusing it: accepting would drag our clock forward '
        'permanently and no later edit could ever sort after it.',
      );
    }

    final maxMs = [
      millis,
      remote.millis,
      nowMs,
    ].reduce((a, b) => a > b ? a : b);

    if (maxMs == millis && maxMs == remote.millis) {
      final c = (counter > remote.counter ? counter : remote.counter) + 1;
      return Hlc(millis: maxMs, counter: c, nodeId: nodeId);
    }
    if (maxMs == millis) {
      return Hlc(millis: maxMs, counter: counter + 1, nodeId: nodeId);
    }
    if (maxMs == remote.millis) {
      return Hlc(millis: maxMs, counter: remote.counter + 1, nodeId: nodeId);
    }
    // Our physical clock has moved past both — reset the counter.
    return Hlc(millis: maxMs, counter: 0, nodeId: nodeId);
  }

  /// `millis-counter-nodeId`, zero-padded so lexicographic order == chronological
  /// order. Do not "simplify" the padding away: the sort would then be wrong for
  /// any value with fewer digits.
  @override
  String toString() =>
      '${millis.toString().padLeft(15, '0')}-'
      '${counter.toString().padLeft(5, '0')}-$nodeId';

  static Hlc parse(String s) {
    final parts = s.split('-');
    if (parts.length < 3) {
      throw FormatException('Not an HLC: $s');
    }
    return Hlc(
      millis: int.parse(parts[0]),
      counter: int.parse(parts[1]),
      // A nodeId may itself contain '-' (it is a uuid), so rejoin the tail.
      nodeId: parts.sublist(2).join('-'),
    );
  }

  @override
  int compareTo(Hlc other) {
    final m = millis.compareTo(other.millis);
    if (m != 0) return m;
    final c = counter.compareTo(other.counter);
    if (c != 0) return c;
    return nodeId.compareTo(other.nodeId);
  }

  bool operator >(Hlc other) => compareTo(other) > 0;
  bool operator <(Hlc other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is Hlc &&
      other.millis == millis &&
      other.counter == counter &&
      other.nodeId == nodeId;

  @override
  int get hashCode => Object.hash(millis, counter, nodeId);
}
