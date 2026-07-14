import 'tier.dart';

/// A persona template = a stable prompt that instructs the summarizer how to
/// structure output for a specific kind of meeting. Free tier gets `basic`
/// only; Starter unlocks 3; Pro+/Privacy unlocks all.
class Persona {
  final SummaryStyle style;
  final String key;
  final String displayName;
  final String emoji;
  final String prompt;

  const Persona({
    required this.style,
    required this.key,
    required this.displayName,
    required this.emoji,
    required this.prompt,
  });
}

/// The full prompt library. Keys are stable; safe to persist in the DB.
const personas = <Persona>[
  Persona(
    style: SummaryStyle.basic,
    key: 'basic',
    displayName: 'Meeting notes',
    emoji: '📝',
    prompt: '''
Summarize this meeting transcript. Output sections:
- Overview (2-3 sentences)
- Key points (bullets)
- Decisions made (bullets, or "none")
- Action items (bullets with assignee in [brackets] when clear from the transcript)

Stay faithful to what was said. Do not invent attendees, decisions, or commitments. If something is unclear or speculative, say so.
''',
  ),
  Persona(
    style: SummaryStyle.oneOnOne,
    key: 'one_on_one',
    displayName: '1:1',
    emoji: '🤝',
    prompt: '''
Summarize this 1:1 conversation. Output sections:
- Topics discussed (bullets)
- Wins / progress (bullets)
- Concerns / blockers (bullets)
- Action items for each person (clearly attributed)
- Follow-ups for next 1:1

Tone: neutral, factual. Do not add coaching advice or interpretation that wasn't in the conversation.
''',
  ),
  Persona(
    style: SummaryStyle.standup,
    key: 'standup',
    displayName: 'Standup',
    emoji: '🏃',
    prompt: '''
Summarize this standup. Output as a table per person:

**[Name]**
- Yesterday: ...
- Today: ...
- Blockers: ...

End with a "Team blockers" section listing anything cross-cutting.

If a person didn't speak, omit them. Do not invent updates.
''',
  ),
  Persona(
    style: SummaryStyle.salesCall,
    key: 'sales_call',
    displayName: 'Sales call',
    emoji: '💼',
    prompt: '''
Summarize this sales call as a CRM-ready entry. Output:
- Account / prospect name (from transcript or "unknown")
- Attendees (name + role if mentioned)
- Pain points raised
- Use cases discussed
- Objections + how they were addressed
- Budget / timeline signals (only if explicitly stated)
- Next steps (with owner + date when mentioned)
- Risk flags (anything that suggests the deal is in trouble)

Be strict about not inventing budget numbers, timelines, or commitments.
''',
  ),
  Persona(
    style: SummaryStyle.interview,
    key: 'interview',
    displayName: 'Interview',
    emoji: '🎤',
    prompt: '''
Summarize this interview. Output:
- Candidate (or interviewee) name
- Key topics covered
- Notable answers (quote-style when distinctive)
- Strengths demonstrated
- Concerns / gaps
- Open questions for next round
- Recommendation cues from the interviewer (if any)

Do not score the candidate. Surface evidence, not judgment.
''',
  ),
  Persona(
    style: SummaryStyle.lecture,
    key: 'lecture',
    displayName: 'Lecture notes',
    emoji: '🎓',
    prompt: '''
Convert this lecture into study notes. Output:
- Topic + lecturer (if introduced)
- Core concepts (with definitions in your own words)
- Examples given
- Equations / formulas (preserve original form)
- Things flagged as "important" / "on the exam" / "remember this"
- Questions raised by students (and how they were answered)
- Suggested follow-up readings (if mentioned)

Format with clear headings. Use markdown.
''',
  ),
  Persona(
    style: SummaryStyle.doctorVisit,
    key: 'doctor_visit',
    displayName: 'Doctor visit',
    emoji: '🩺',
    prompt: '''
Summarize this medical appointment for the patient's own records (not a medical record). Output:
- Reason for visit
- Symptoms discussed
- Doctor's assessment (as stated)
- Recommended tests or referrals
- Medications mentioned (name, dosage, frequency — only as stated)
- Next steps + follow-up date
- Questions the patient asked + answers

⚠️ This is a personal note, not a medical record. Do not interpret beyond what was explicitly said. Flag anything ambiguous as "unclear — ask doctor to confirm."
''',
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
final Map<String, Persona> personasByKey = {
  for (final p in personas) p.key: p,
};

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
