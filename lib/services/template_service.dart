import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../billing/persona.dart';
import '../billing/tier.dart';
import '../data/database.dart';

/// User-created summary templates, backed by Drift.
///
/// Replaces CustomPersonasService, which kept a JSON array in SharedPreferences
/// and gated creation to the $99 Power tier. Granola gives custom templates away
/// on its FREE plan, so hiding ours behind the top SKU was the wrong call.
///
/// Tier limits (see [maxTemplatesFor]):
///   Free  -> 1
///   Pro   -> unlimited
///   Privacy -> unlimited (fully on-device; nothing about a template needs cloud)
///   Power -> unlimited (+ variables / auto-apply, later)
class TemplateService extends ChangeNotifier {
  TemplateService({required this.db, Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final AppDb db;
  final Uuid _uuid;

  static const _legacyKey = 'custom_personas';
  static const _migratedFlag = 'templates_migrated_to_drift_v1';

  List<Persona> _cache = const [];

  /// The user's templates as [Persona]s, ready for the summarizer.
  List<Persona> get personas => List.unmodifiable(_cache);

  /// null == unlimited.
  static int? maxTemplatesFor(Tier tier) => tier == Tier.free ? 1 : null;

  static bool canCreate(Tier tier, int existingCount) {
    final max = maxTemplatesFor(tier);
    return max == null || existingCount < max;
  }

  Future<void> init() async {
    await migrateFromPrefs();
    await refresh();
  }

  Future<void> refresh() async {
    final rows = await (db.select(db.templates)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    _cache = rows.map(_toPersona).toList(growable: false);
    notifyListeners();
  }

  /// Templates carry [SummaryStyle.basic] because the style enum drives the
  /// built-in tier gate; a user template's behaviour comes entirely from its
  /// prompt. [SummaryRouter] lets `custom:` keys through that gate for exactly
  /// this reason.
  Persona _toPersona(Template t) => Persona(
        style: SummaryStyle.basic,
        key: t.id,
        displayName: t.name,
        emoji: t.emoji,
        prompt: t.prompt,
      );

  Future<Persona> create({
    required String name,
    required String prompt,
    String emoji = '✨',
    String? builtinKey,
  }) async {
    final n = name.trim();
    final p = prompt.trim();
    if (n.isEmpty) throw ArgumentError('Template name cannot be empty');
    if (p.isEmpty) throw ArgumentError('Template prompt cannot be empty');

    final now = DateTime.now();
    final row = await db.into(db.templates).insertReturning(
          TemplatesCompanion.insert(
            // The `custom:` prefix is load-bearing: resolvePersona keys off it.
            id: 'custom:${_uuid.v4()}',
            name: n,
            prompt: p,
            emoji: Value(emoji),
            builtinKey: Value(builtinKey),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await refresh();
    return _toPersona(row);
  }

  /// Fork a built-in into an editable copy — the fastest path to a useful
  /// template is "the standup one, but ours".
  Future<Persona> duplicateBuiltin(Persona builtin) => create(
        name: '${builtin.displayName} (copy)',
        prompt: builtin.prompt,
        emoji: builtin.emoji,
        builtinKey: builtin.key,
      );

  Future<void> update(
    String id, {
    String? name,
    String? prompt,
    String? emoji,
  }) async {
    final n = name?.trim();
    final p = prompt?.trim();
    if (n != null && n.isEmpty) {
      throw ArgumentError('Template name cannot be empty');
    }
    if (p != null && p.isEmpty) {
      throw ArgumentError('Template prompt cannot be empty');
    }
    await (db.update(db.templates)..where((t) => t.id.equals(id))).write(
      TemplatesCompanion(
        name: n == null ? const Value.absent() : Value(n),
        prompt: p == null ? const Value.absent() : Value(p),
        emoji: emoji == null ? const Value.absent() : Value(emoji),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await refresh();
  }

  /// Delete a template.
  ///
  /// Summaries already generated with it keep their `personaKey`. That key will
  /// no longer resolve, and [resolvePersona] falls back to the basic persona
  /// rather than printing the raw `custom:<uuid>` — so old summaries degrade to
  /// a generic label instead of showing the user a database id.
  Future<void> remove(String id) async {
    await (db.delete(db.templates)..where((t) => t.id.equals(id))).go();
    await refresh();
  }

  Future<int> count() async => (await db.select(db.templates).get()).length;

  // -- migration ---------------------------------------------------------------

  /// Move CustomPersonasService's SharedPreferences JSON into Drift, once.
  ///
  /// Same shape as FolderService.migrateFromPrefs: transactional, idempotent,
  /// and the legacy key is cleared only AFTER the Drift write commits — killed
  /// halfway, the next launch replays from data that is still there.
  ///
  /// Legacy ids were `custom:<microsecondsSinceEpoch>`; they are preserved
  /// verbatim, because existing Summaries rows reference them by key.
  Future<void> migrateFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedFlag) ?? false) return;

    final raw = prefs.getString(_legacyKey);
    if (raw == null || raw.isEmpty) {
      await prefs.setBool(_migratedFlag, true);
      return;
    }

    final now = DateTime.now();
    await db.transaction(() async {
      for (final entry in jsonDecode(raw) as List<dynamic>) {
        final m = entry as Map<String, dynamic>;
        final legacyId = m['id'] as String?;
        if (legacyId == null || legacyId.isEmpty) continue;
        // Old ids were stored bare; the key used everywhere was 'custom:$id'.
        final id =
            legacyId.startsWith('custom:') ? legacyId : 'custom:$legacyId';
        final name = (m['name'] as String?)?.trim();
        final prompt = (m['prompt'] as String?)?.trim();
        if (name == null || name.isEmpty || prompt == null || prompt.isEmpty) {
          continue; // unusable row — do not resurrect a broken template
        }
        await db.into(db.templates).insert(
              TemplatesCompanion.insert(
                id: id,
                name: name,
                prompt: prompt,
                emoji: Value((m['emoji'] as String?) ?? '✨'),
                createdAt: now,
                updatedAt: now,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });

    await prefs.setBool(_migratedFlag, true);
    await prefs.remove(_legacyKey);
  }
}
