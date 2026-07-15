import 'package:flutter_test/flutter_test.dart';
import 'package:recap/billing/persona.dart';
import 'package:recap/billing/tier.dart';

/// Two bugs shipped because the UI reached for `personasByKey` — which holds
/// ONLY the 7 built-ins — instead of resolving the key properly:
///
///   * the summary header rendered "OVERVIEW · custom:1752438…" (the raw key)
///   * the persona chip fell back to the label "Meeting notes", telling the
///     user they had selected a persona they had not selected
///
/// resolvePersona is now the single source of truth. These tests exist so a
/// future `personasByKey[key]` shortcut fails here first.
void main() {
  const mine = Persona(
    style: SummaryStyle.basic,
    key: 'custom:1752438000000',
    displayName: 'Board Prep',
    emoji: '📋',
    prompt: 'Summarize for the board.',
  );

  group('resolvePersona', () {
    test('resolves a custom key to the custom template, not a fallback', () {
      final p = resolvePersona('custom:1752438000000', const [mine]);
      expect(p.displayName, 'Board Prep');
      expect(p.key, 'custom:1752438000000');
    });

    test('a custom key is NOT findable in personasByKey', () {
      // This is the trap. If this ever starts passing, the shortcut is safe —
      // and until then, anything using personasByKey to render a name is a bug.
      expect(personasByKey['custom:1752438000000'], isNull);
    });

    test('resolves each of the 7 built-ins by key', () {
      for (final builtin in personas) {
        expect(resolvePersona(builtin.key, const []).key, builtin.key);
      }
    });

    test('an unknown key falls back to basic — never renders the raw key', () {
      final p = resolvePersona('custom:deleted-template', const []);
      expect(p.style, SummaryStyle.basic);
      expect(
        p.displayName,
        isNot(contains('custom:')),
        reason: 'the raw key must never reach the UI',
      );
    });

    test('a garbage key still yields a usable persona', () {
      final p = resolvePersona('', const []);
      expect(p.displayName, isNotEmpty);
    });
  });

  group('tier persona gating', () {
    test('Free gets only the basic style; Pro+ gets all 7', () {
      expect(Tier.free.personaTemplates, [SummaryStyle.basic]);
      for (final t in [Tier.pro, Tier.privacy, Tier.power]) {
        expect(t.personaTemplates, SummaryStyle.values, reason: t.name);
      }
    });

    test('every built-in persona maps to a real SummaryStyle', () {
      // A persona whose style is not in SummaryStyle.values could never be
      // granted by any tier, and would be silently unreachable.
      for (final p in personas) {
        expect(SummaryStyle.values, contains(p.style));
      }
    });
  });
}
