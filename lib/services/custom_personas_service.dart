import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../billing/persona.dart';
import '../billing/tier.dart';

/// Power-tier custom persona prompts. Stored as a JSON array in
/// SharedPreferences (small data, single user, no need for a Drift table).
class CustomPersonasService extends ChangeNotifier {
  static const _kKey = 'custom_personas';
  late SharedPreferences _prefs;
  List<Persona> _personas = const [];

  List<Persona> get personas => List.unmodifiable(_personas);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) {
      _personas = const [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _personas = list
          .map((e) {
            final m = e as Map<String, dynamic>;
            return Persona(
              style: SummaryStyle.basic, // custom personas all use basic gate
              key: 'custom:${m['id']}',
              displayName: m['name'] as String,
              emoji: m['emoji'] as String? ?? '✨',
              prompt: m['prompt'] as String,
            );
          })
          .toList(growable: false);
    } catch (_) {
      _personas = const [];
    }
  }

  Future<void> _save() async {
    final list = _personas
        .map((p) => {
              'id': p.key.replaceFirst('custom:', ''),
              'name': p.displayName,
              'emoji': p.emoji,
              'prompt': p.prompt,
            })
        .toList();
    await _prefs.setString(_kKey, jsonEncode(list));
    notifyListeners();
  }

  Future<void> add({
    required String name,
    required String prompt,
    String emoji = '✨',
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _personas = [
      ..._personas,
      Persona(
        style: SummaryStyle.basic,
        key: 'custom:$id',
        displayName: name,
        emoji: emoji,
        prompt: prompt,
      ),
    ];
    await _save();
  }

  Future<void> update(String key, {String? name, String? prompt}) async {
    _personas = _personas.map((p) {
      if (p.key != key) return p;
      return Persona(
        style: p.style,
        key: p.key,
        displayName: name ?? p.displayName,
        emoji: p.emoji,
        prompt: prompt ?? p.prompt,
      );
    }).toList(growable: false);
    await _save();
  }

  Future<void> remove(String key) async {
    _personas = _personas.where((p) => p.key != key).toList(growable: false);
    await _save();
  }

  /// Helper: whether the current tier may use these. Power-only.
  static bool isAvailableFor(Tier tier) => tier == Tier.power;
}
