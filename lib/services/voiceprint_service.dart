import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Voice ID / speaker enrollment (D14.4). User records a 30s reference clip
/// of a known speaker; we extract a WeSpeaker embedding (same model as the
/// SherpaDiarizer) and store it. On future meetings, post-diarization, each
/// `Speaker N` centroid embedding is cosine-matched against enrolled
/// voiceprints — above threshold (0.75) the label auto-fills.
///
/// **Marquee competitive feature.** Otter calls it "Voiceprints". Jamie
/// calls it "Speaker memory". We're the only mobile cross-platform app
/// shipping it free for every tier.
///
/// **Storage:** shared_preferences JSON list for v1 (small data, no
/// transactional needs). When Drift codegen is fixed (see CLAUDE.md), move
/// to the `Voiceprints` table defined in `lib/data/database.dart`.
class VoiceprintService {
  static const double matchThreshold = 0.75;
  static const _key = 'voiceprints_v1';

  Future<List<Voiceprint>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((m) => Voiceprint.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<String> enroll({
    required String name,
    required Float32List embedding,
    String? avatarPath,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final vp = Voiceprint(
      id: id,
      name: name,
      embedding: embedding,
      avatarPath: avatarPath,
      createdAt: DateTime.now(),
    );
    final list = await all();
    final updated = [...list, vp];
    await _save(updated);
    return id;
  }

  Future<void> delete(String id) async {
    final list = await all();
    await _save(list.where((v) => v.id != id).toList());
  }

  Future<Voiceprint?> matchCentroid(Float32List centroid) async {
    final list = await all();
    Voiceprint? best;
    var bestScore = matchThreshold;
    for (final vp in list) {
      final score = _cosineSim(centroid, vp.embedding);
      if (score > bestScore) {
        bestScore = score;
        best = vp;
      }
    }
    return best;
  }

  Future<void> _save(List<Voiceprint> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list.map((v) => v.toJson()).toList()));
  }

  double _cosineSim(Float32List a, Float32List b) {
    if (a.length != b.length || a.isEmpty) return 0;
    var dot = 0.0, na = 0.0, nb = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na < 1e-8 || nb < 1e-8) return 0;
    return dot / (_sqrt(na) * _sqrt(nb));
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    var g = x;
    for (var i = 0; i < 8; i++) {
      g = 0.5 * (g + x / g);
    }
    return g;
  }
}

class Voiceprint {
  final String id;
  final String name;
  final Float32List embedding;
  final String? avatarPath;
  final DateTime createdAt;

  const Voiceprint({
    required this.id,
    required this.name,
    required this.embedding,
    this.avatarPath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'embedding': base64Encode(embedding.buffer.asUint8List()),
        'avatarPath': avatarPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Voiceprint.fromJson(Map<String, dynamic> m) {
    return Voiceprint(
      id: m['id'] as String,
      name: m['name'] as String,
      embedding: Float32List.view(base64Decode(m['embedding'] as String).buffer),
      avatarPath: m['avatarPath'] as String?,
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }
}
