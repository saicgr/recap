import 'tier.dart';

/// A persona = a LENS, not a template.
///
/// Personas used to be whole prompts ("Output sections: Overview / Key points /
/// Decisions / Action items"), which meant every meeting got the same four
/// buckets regardless of what was said — the single biggest cap on summary
/// quality, and the thing Granola beats us on. The shared contract now lives in
/// `lib/services/summarizer/prompts.dart` (topic sections derived from content,
/// [mm:ss] citations, mandatory People & continuity, mandatory Low confidence);
/// [prompt] is appended to it and may only ADD a lens and extra sections on top.
///
/// A persona must never redefine the base sections, and must never relax the
/// anti-hallucination rules.
///
/// [key] and [style] are persisted (`summaries.personaKey`) and gated by
/// `tier.dart` — they are frozen. Only [prompt] is free to change.
class Persona {
  final SummaryStyle style;
  final String key;
  final String displayName;
  final String emoji;

  /// The lens, appended verbatim to the shared reduce/single-pass contract.
  final String prompt;

  const Persona({
    required this.style,
    required this.key,
    required this.displayName,
    required this.emoji,
    required this.prompt,
  });
}

/// The full lens library. Keys are stable; safe to persist in the DB.
const personas = <Persona>[
  Persona(
    style: SummaryStyle.basic,
    key: 'basic',
    displayName: 'Meeting notes',
    emoji: '📝',
    prompt: '''
LENS: general meeting notes. Add no extra sections beyond the shape above.''',
  ),
  Persona(
    style: SummaryStyle.oneOnOne,
    key: 'one_on_one',
    displayName: '1:1',
    emoji: '🤝',
    prompt: '''
LENS: a 1:1. ALSO add, before "## Next steps":

## Wins & blockers
- Progress claimed, and blockers raised — each attributed to the person who said
  it [mm:ss]

Under "## Next steps", attribute every action to a specific person; a 1:1 with
unowned actions is a 1:1 that produced nothing. Stay neutral and factual: add no
coaching, no interpretation, and no advice that was not spoken.''',
  ),
  Persona(
    style: SummaryStyle.standup,
    key: 'standup',
    displayName: 'Standup',
    emoji: '🏃',
    prompt: '''
LENS: a standup. ALSO add, in place of the topic sections:

## <Person>
- Yesterday: ... [mm:ss]
- Today: ... [mm:ss]
- Blockers: ... [mm:ss]
(One per person who actually spoke. Omit anyone who did not, and omit any of the
three lines they did not give. Never invent an update.)

Cross-cutting blockers — anything blocking more than one person — go under
"## Next steps" with an owner.''',
  ),
  Persona(
    style: SummaryStyle.salesCall,
    key: 'sales_call',
    displayName: 'Sales call',
    emoji: '💼',
    prompt: '''
LENS: a sales call, written to be pasted into a CRM. ALSO add, before
"## Next steps":

## Deal signals
- Pain points raised, in the prospect's own words [mm:ss]
- Objections, and exactly how each was handled (or that it was not) [mm:ss]
- Budget / timeline signals — ONLY if explicitly stated [mm:ss]
- Risk flags: anything suggesting the deal is in trouble [mm:ss]

Never infer a budget number, a close date, or a commitment. An enthusiastic noise
is not a commitment. Name the account and the attendees only if the transcript
does.''',
  ),
  Persona(
    style: SummaryStyle.interview,
    key: 'interview',
    displayName: 'Interview',
    emoji: '🎤',
    prompt: '''
LENS: an interview. ALSO add, before "## Next steps":

## Evidence
- Notable answers, quoted as heard [mm:ss]
- Strengths actually demonstrated (with the answer that demonstrates them) [mm:ss]
- Gaps and unanswered probes [mm:ss]

Surface evidence, not judgment. Do not score the candidate and do not recommend an
outcome unless the interviewer explicitly stated one — in which case attribute it
to them.''',
  ),
  Persona(
    style: SummaryStyle.lecture,
    key: 'lecture',
    displayName: 'Lecture notes',
    emoji: '🎓',
    prompt: '''
LENS: a lecture, written as study notes. ALSO add, before "## Next steps":

## Concepts
- Term — the definition as given [mm:ss]
  - the example used, if one was [mm:ss]

## Flagged as important
- Anything called out as "on the exam" / "remember this" / "important" [mm:ss]

Preserve equations, formulas and notation in their original form — an ASR-mangled
formula goes to Low confidence as heard, never "corrected" into a plausible one.
Student questions and the answers given belong under "## Open questions".''',
  ),
  Persona(
    style: SummaryStyle.doctorVisit,
    key: 'doctor_visit',
    displayName: 'Doctor visit',
    emoji: '🩺',
    prompt: '''
LENS: a medical appointment, written for the patient's own records. ALSO add,
before "## Next steps":

## Medications & tests
- Medication — dosage — frequency, EXACTLY as stated (never normalized, never
  completed from your own knowledge) [mm:ss]
- Tests, referrals and imaging ordered [mm:ss]

⚠️ These are personal notes, not a medical record. Do not interpret, diagnose, or
extend beyond what was explicitly said. Anything ambiguous — a drug name, a dose, a
number — goes to "## ⚠️ Low confidence" as heard, phrased as "unclear — ask the
doctor to confirm". A wrong dose here is the most dangerous line this app can
produce; when in doubt, mark it uncertain.''',
  ),
];

/// The 7 built-ins, by key. **Does not contain custom templates.**
///
/// Reaching for this directly to render a name is a bug — a summary made with a
/// custom template has a `custom:<id>` key that is not in here, so the lookup
/// misses and you either print the raw key or silently mislabel it. Use
/// [resolvePersona]. (Both mistakes shipped: the summary header rendered
/// "OVERVIEW · custom:1752438…", and the persona chip claimed "Meeting notes"
/// while a custom template was selected.)
final Map<String, Persona> personasByKey = {for (final p in personas) p.key: p};

Persona personaForStyle(SummaryStyle style) =>
    personas.firstWhere((p) => p.style == style);

/// Resolve any persona key — built-in or `custom:<id>` — to a [Persona].
///
/// The single source of truth for key -> Persona. Anything that displays or
/// exports a persona name must go through here, passing the user's custom
/// templates.
Persona resolvePersona(String key, Iterable<Persona> customs) {
  if (key.startsWith('custom:')) {
    for (final p in customs) {
      if (p.key == key) return p;
    }
  }
  return personasByKey[key] ?? personaForStyle(SummaryStyle.basic);
}
