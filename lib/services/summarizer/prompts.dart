import '../../billing/persona.dart';
import 'chunker.dart';

/// The prompts ARE the product. Everything else in this folder is plumbing.
///
/// The bar is Granola. It gets speaker attribution, silent ASR repair and
/// topic-clustered sections right, and we must match all three. It also, on a
/// real garbled meeting: invented a "44-pack" out of "for 4 back"; silently
/// hardened a spoken "6 5 7 6 6" into promo ID 65766 with no uncertainty marker;
/// and dropped the one thing everyone in the room actually needed (a speaker is
/// out for surgery — contact Lisa instead). The three answers below are the
/// Low-confidence section, the heard-not-verified marker, and the mandatory
/// People & continuity section. [mm:ss] citations on every claim are the fourth:
/// Granola has none, they suppress hallucination by forcing each line to point at
/// a real transcript line, and they pair with our tap-to-seek transcript UI.
///
/// The rules below are not decoration — each numbered clause exists because a
/// run on the reference transcript produced the failure it forbids:
///  * rule 1's "a context-only repair is disclosed" — we shipped "prior Marlboro
///    smokers" out of a garbled "marboro" said as a guess, and were *less*
///    conservative than Granola.
///  * rule 2's pack-configuration clause — we read "must buy for 4 back" as a
///    clean "4-pack" with no marker. Granola read it as a "44-pack". Both are
///    guesses; only the marker distinguishes us.
///  * rule 4's gender/deixis clauses — we invented "she" for two speakers the
///    transcript never genders, and flipped "sum that up for YOUR team" (said BY
///    Speaker 2, TO Speaker 1) onto Speaker 2's team.
///  * rule 8 — "Maybe I can send the list after this" became a Next step with an
///    owner. A manufactured commitment is the worst possible error in a section
///    people execute from.

/// Kept DELIBERATELY TERSE. This block is prepended to every map, fold, reduce
/// and critic call, so a word here is paid 4-8 times per summary — and on a
/// 4096-token on-device window it is subtracted directly from the NOTES budget,
/// i.e. from the actual findings. An earlier draft of these rules cost 925 est.
/// tokens and left 374 for the notes. Rules are non-negotiable; adjectives are.
const String kSystemPreamble = '''
You are a meeting-notes engine reading an AUTOMATIC SPEECH RECOGNITION (ASR)
transcript: wrong homophones, mangled names, garbled digits, dropped words. Every
line is approximately — not exactly — what was said.

Rules. These beat any instinct to produce clean-looking prose:

1. REPAIR, DON'T GUESS. Repair SILENTLY only when the glossary has the term, or the
   transcript spells it cleanly on another line. A repair inferred from context
   alone: use it AND list it under Low confidence as "<as heard>" -> <term>. Cannot
   identify it at all: keep it as heard, in quotes, under Low confidence. Never swap
   a garbled term for a plausible clean one in silence.
2. NEVER FABRICATE SPECIFICS. Numbers, IDs, amounts, dates, pack and product names,
   people's names must exist in the transcript. Never round, complete or "fix" a
   number. Digits spoken one at a time ("6 5 7 6 6") may be joined ("65766") but are
   marked (heard, unverified). A pack size or must-buy quantity you read out of a
   garbled phrase is marked (heard, unverified) AND goes under Low confidence:
   "must buy for 4 back" is evidence of neither a 4-pack nor a 44-pack.
3. CITE. Every claim carries the [mm:ss] of the line it came from. Never hang one
   [mm:ss] on a sentence you assembled from two lines.
4. ATTRIBUTE. Speaker labels exactly as given; never rename, merge or invent one.
   Never give a speaker a gender, pronoun, title, team or role the transcript does
   not state — an unnamed speaker is "Speaker 1" and "they", never "she". "you" and
   "your" belong to the person ADDRESSED, not the speaker: "sum that up for your
   team", said BY Speaker 2, means SPEAKER 1's team.
5. PRESERVE CONTINUITY. Absence, leave, surgery, handoff, coverage ("reach out to X
   instead") and deadlines ALWAYS reach the notes — above all when they are social
   asides at the very end of the call.
6. NO PADDING. A bullet true of any meeting on this topic is noise, and so is a bare
   topic label ("JBP accounts vs broad market"). Every bullet makes a claim.
7. SURFACE CONFLICTS. A sheet says one thing and a person says another; two people
   contradict; someone calls their own answer an assumption — the disagreement IS
   the finding. Never smooth it, never pick a winner the room did not pick.
8. NEVER UPGRADE A HEDGE. "maybe I can send the list", "I guess we could try",
   "hopefully", "I think", "I'm assuming", "I don't know how that gets submitted" —
   the hedge is part of the claim. A hedge never becomes a flat fact, an offer never
   becomes an owned action, "I didn't look into it" never becomes a plan to.''';

/// [kSystemPreamble] plus the glossary block when we have one.
///
/// The glossary is the ONLY channel through which a repair may be made silently
/// (rule 1). It is frequently EMPTY — a garbled ASR transcript defeats the
/// capitalization heuristics that populate it, and a noisy glossary is worse than
/// none because the block below tells the model to snap near-misses onto its
/// terms. Rule 1 is written to hold with or without it: absent a glossary, every
/// context-only repair must be disclosed under Low confidence.
String buildSystemPrompt({List<String> glossary = const []}) {
  final terms = glossary
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList(growable: false);
  if (terms.isEmpty) return kSystemPreamble;
  return '$kSystemPreamble\n\n'
      'Known terms — prefer these exact spellings, and treat a near-miss in the '
      'transcript as a mis-transcription of one of them:\n'
      '${terms.join(', ')}';
}

/// The headings the map stage emits, in order. Shared with the pipeline so the
/// trim, the fold and the critic all agree on what a note looks like — there is
/// one source of truth for the note format and it is here.
const List<String> kNoteHeadings = [
  'FACTS',
  'BEHAVIOURS & LIMITS',
  'DECISIONS',
  'PROPOSED ACTIONS',
  'OPEN QUESTIONS',
  'SPECIFICS',
  'PEOPLE',
  'CONTINUITY',
  'LOW CONFIDENCE',
];

/// Which note lines the pipeline may throw away when the notes will not fit the
/// reduce window, worst-value first.
///
/// This list is the fix for the single biggest quality bug in the rebuild. The
/// notes used to be trimmed by DOCUMENT POSITION (keep the head and the tail,
/// elide the middle), which on a 25-minute meeting deletes the middle ten minutes
/// wholesale. Everything Granola beat us on lived there: "they always claim the
/// max", "the APTs are by promo by customer, so you can't find one retailer in
/// it", "one state could be PTC-driven, one funding-driven, within the same APT".
/// Those are BEHAVIOURS & LIMITS lines — the highest-value content in the notes —
/// and a positional trim is blind to that. FACTS (plain narration) is what may be
/// dropped; the specifics, behaviours, decisions, people, continuity and
/// low-confidence lines are what the reduce cannot rebuild from anything else.
const List<String> kNoteEvictionOrder = [
  'FACTS',
  'OPEN QUESTIONS',
  'PROPOSED ACTIONS',
  'BEHAVIOURS & LIMITS',
  'SPECIFICS',
  'DECISIONS',
  'PEOPLE',
  'CONTINUITY',
  'LOW CONFIDENCE',
];

/// The note classes the critic is authoritative for. Feeding it the full notes
/// plus a full draft cannot fit a 4096-token window on ANY meeting long enough to
/// have been map-reduced — i.e. the critic was structurally dead on exactly the
/// meetings it was written for. It only ever diffs invented specifics, dropped
/// markers, laundered uncertainty, un-decided decisions, upgraded hedges and
/// dropped continuity, so it does not need FACTS or OPEN QUESTIONS to do its job.
const List<String> kCriticLedgerHeadings = [
  'BEHAVIOURS & LIMITS',
  'DECISIONS',
  'PROPOSED ACTIONS',
  'SPECIFICS',
  'PEOPLE',
  'CONTINUITY',
  'LOW CONFIDENCE',
];

/// The map stage is EXTRACTION, not summary.
///
/// This is the whole reason on-device works: a 2B model asked to "summarize" a
/// chunk writes plausible prose and quietly drops the promo ID. The same model
/// asked to "copy out every number you see" is reliable. Synthesis is deferred to
/// one reduce call that sees only the extracted notes.
String mapInstruction() => '''
Extract structured notes from this SEGMENT of a longer meeting. You are not writing
a summary — you are pulling out what is there so a later pass can assemble the
notes. Do not summarize, smooth or editorialize. Copy, don't compose.

Use only these headings, in this order. OMIT a heading entirely when you have
nothing for it — never write "None" or "N/A".

FACTS — plain narration of what was stated.
BEHAVIOURS & LIMITS — how things work in practice ("they always claim the max") and
  stated limits of a system, sheet or report ("the APTs are by promo by customer, so
  you can't find one retailer in it"; "you can only link them by name"). Verbatim.
  These are what the next person needs and the first thing a summary loses.
DECISIONS — only what was actually settled. A preference, an assumption or an offer
  is not a decision.
PROPOSED ACTIONS — someone suggested doing something and nobody closed it ("I guess
  we could try to get data from Scan Apps on one of those fuel offers"). Say who
  suggested it, who would do it ONLY if stated, and keep their hedge word.
OPEN QUESTIONS — asked and unanswered, deferred to a named person, or blocked by a
  limitation.
SPECIFICS — verbatim numbers, IDs, amounts, percentages, dates, pack and product
  names, system, report and field names, exactly as spoken. Append
  (heard, unverified) to any digit string you assembled from digits spoken one at a
  time, and to any pack size you read out of a garbled phrase.
PEOPLE — Name — what they own or what they must be asked. Only what the transcript
  states: no gender, title or team you were not given.
CONTINUITY — absence, leave, surgery, handoff, coverage, deadline.
LOW CONFIDENCE — "<as heard>" — why it is unresolved, or what you repaired it to
  from context alone.

Every line ends with its [mm:ss]. If its source line has no [mm:ss], leave the
citation off rather than inventing one.''';

/// The Granola-beating contract. Sections are DERIVED from content, not a fixed
/// Overview/Key points/Decisions/Actions template — that template is what caps
/// the old summarizer's quality below every competitor.
///
/// **Output ORDER is a truncation policy.** A decoder-only model with no output
/// cap (MediaPipe/Gemma has none — see GemmaBackend) simply runs out of window and
/// stops. Whatever is last dies first. The old contract put Low confidence LAST,
/// so on the reference meeting all 21 uncertain terms were emitted as zero bytes
/// and the reader — per the contract's own "omit only if nothing was uncertain" —
/// correctly inferred that nothing was uncertain. We turned Granola's fabrication
/// into false certainty, which is worse. The mandatory, compact sections now come
/// first and the expandable topic sections come last, where a truncation costs
/// narration instead of the differentiator.
String reduceInstruction(Persona persona) => '''
You are given structured NOTES extracted from consecutive segments of ONE meeting.
Merge them into the final meeting notes.

Contract:
- EVERY line traces back to a note. Add nothing the notes do not support.
- Segments overlap: merge duplicate notes, keep the earliest [mm:ss].
- Keep every specific (number, ID, amount, pack size, field, system name) and every
  (heard, unverified) marker, attached to the point it belongs to.
- Every BEHAVIOURS & LIMITS note MUST reach the output. A stated limit of a system,
  and a rule of thumb about how people really behave, are what the next person
  cannot get anywhere else.
- A conflict or limitation is a finding: its own bullet, both sides named, left
  unresolved if the room left it unresolved.
- Preserve hedges. A hedged claim rendered as a flat fact is a fabrication.

Output markdown in exactly this shape, IN THIS ORDER. Everything above the topic
sections is mandatory and must be COMPLETE before you start them. Running short of
room: write FEWER topic sections — never leave the sections above unfinished.

## TL;DR
- Max 3 bullets — what someone who missed the meeting must know.

## Decisions
- What was settled and what it commits someone to [mm:ss]
(Nothing settled? Write exactly: None — nothing was decided.)

## Next steps
- **Action** — why it matters and what specifically to ask or check. (Owner, timing) [mm:ss]
(One owner, named in the transcript. Nobody accepted it -> "Owner: unassigned".
Never invent an owner, never write "A / B". A merely PROPOSED action goes here too,
tagged "(proposed — not accepted)". Timing only if stated — EXCEPT when the owner is
about to be absent or handing off, where the timing field MUST say so: "(Speaker 1 —
before next week, else Lisa)".)

## People & continuity
- Who is away, who covers, who owns what, what deadline binds whom [mm:ss]
(Omit ONLY if the notes hold nothing of the kind.)

## ⚠️ Low confidence
- "<as heard>" — unresolved, or repaired to <term> from context alone [mm:ss]
(Omit ONLY if nothing was uncertain. Never make an uncertain term disappear by
inventing a clean one, and never promote a (heard, unverified) value to a certain
one. Do NOT list a term the transcript spells plainly elsewhere — one clean
occurrence resolves every garbled one. A term listed here may not be asserted as
fact anywhere else in the output; cite it as heard, in quotes.)

## Open questions
- The question — who can answer it [mm:ss]

## <Topic name>
- Point [mm:ss]
  - supporting detail, number, or ID
(Repeat 2-6 times, each named from its content — never "Discussion" or "Key points".
The BEHAVIOURS & LIMITS lines belong here: a stated limit is a finding, not chatter.)

${persona.prompt.trim()}''';

/// The offline quality multiplier: a second cheap pass that only deletes.
///
/// Small models hallucinate on the way OUT of the reduce, not on the way in — the
/// notes are usually clean and the draft is where a "44-pack" appears. Asking the
/// same model to diff draft against notes catches most of it, and costs nothing on
/// device. Cloud gets the same check embedded in a single call (see
/// [singlePassInstruction]) so a cloud summary stays ONE metered request.
///
/// The deletion criteria are CLASS-SCOPED, not "anything absent from the notes",
/// for two reasons: (a) it is what the critic is actually good at, and (b) it lets
/// the pipeline hand over a LEDGER (see [kCriticLedgerHeadings]) when the full
/// notes plus the full draft cannot fit the window — which, on a 4096-token
/// on-device window, is every meeting long enough to have been map-reduced.
String criticInstruction() => '''
Below are NOTES — the specifics, behaviours, decisions, people, continuity items and
uncertain terms an extraction pass recorded — and a DRAFT written from them.

The NOTES may be a SUBSET of what the draft was written from, so do NOT delete a
DRAFT line merely because you cannot find it below. Check only what the NOTES are
authoritative for:

- A number, ID, amount, date, pack size or product configuration in the DRAFT that
  appears nowhere in the NOTES is INVENTED: delete it, or keep the claim without it.
- A (heard, unverified) marker the NOTES carry and the DRAFT dropped: restore it.
- A term the NOTES marked LOW CONFIDENCE but the DRAFT asserts confidently: move it
  to "## ⚠️ Low confidence" and quote it as heard wherever it is cited.
- A decision the NOTES did not record as settled: it was not decided. Delete it, or
  move it to Open questions.
- A hedge the NOTES kept ("maybe I can send the list", "I'm assuming") that the DRAFT
  turned into a flat fact or an owned action: restore the hedge, and tag a merely
  proposed action "(proposed — not accepted)".
- An owner, gender, pronoun, title, team or role on a person that the NOTES do not
  state: remove it. "Owner: unassigned" beats an invented owner.
- A continuity item (absence, handoff, coverage, deadline) in the NOTES but missing
  from the DRAFT: restore it.

Then output the corrected DRAFT and nothing else — no preamble, no list of changes.
Do not rewrite supported lines, do not add sections, do not improve the prose. If
every line passes, output the DRAFT unchanged.''';

/// Long-context backends (cloud, BYOK) read the transcript directly — summarizing
/// a summary loses detail, so we skip map-reduce when the window allows. The
/// self-check is embedded in this single prompt rather than issued as a second
/// call, because a cloud summary must remain ONE metered request against the
/// user's quota.
///
/// The section order matches [reduceInstruction] deliberately: the same meeting
/// must not render in a different shape depending on which backend ran it.
String singlePassInstruction(Persona persona) => '''
You are given the full ASR transcript of ONE meeting. Write the final meeting notes
from it.

Contract:
- Every line traces back to a transcript line and carries its [mm:ss].
- Keep every specific (number, ID, amount, pack size, field, report and system name)
  exactly as spoken. Mark a digit string assembled from digits spoken one at a time
  as (heard, unverified).
- A conflict or a stated limitation is a finding: its own bullet, both sides named,
  left unresolved if the room left it unresolved.
- Keep how-it-really-behaves statements ("they always claim the max") and stated
  limits of a system or report ("the APTs are by promo by customer, so you can't
  find one retailer in it"). They read like chatter; they are what the next person
  needs.
- Preserve hedges. A hedged claim rendered as a flat fact is a fabrication.

Output markdown in exactly this shape, IN THIS ORDER. Everything above the topic
sections is mandatory and must be COMPLETE before you start them. Running short of
room: write FEWER topic sections — never leave the sections above unfinished.

## TL;DR
- Max 3 bullets — what someone who missed the meeting must know.

## Decisions
- What was settled and what it commits someone to [mm:ss]
(Nothing settled? Write exactly: None — nothing was decided.)

## Next steps
- **Action** — why it matters and what specifically to ask or check. (Owner, timing) [mm:ss]
(One owner, named in the transcript. Nobody accepted it -> "Owner: unassigned".
Never invent an owner, never write "A / B". An action someone merely PROPOSED goes
here too, tagged "(proposed — not accepted)". Timing only if stated — EXCEPT when the
owner is about to be absent or handing off, where the timing field MUST say so:
"(Speaker 1 — before next week, else Lisa)".)

## People & continuity
- Who is away, who covers, who owns what, what deadline binds whom [mm:ss]
(Omit ONLY if the transcript holds nothing of the kind.)

## ⚠️ Low confidence
- "<as heard>" — unresolved, or repaired to <term> from context alone [mm:ss]
(Omit ONLY if nothing was uncertain. Do NOT list a term the transcript spells plainly
elsewhere — one clean occurrence resolves every garbled one. A term listed here may
not be asserted as fact anywhere else in the output; cite it as heard, in quotes.)

## Open questions
- The question — who can answer it [mm:ss]

## <Topic name>
- Point [mm:ss]
  - supporting detail, number, or ID
(Repeat 2-6 times, each named from its content — never "Discussion" or "Key points".)

SELF-CHECK — do this before emitting anything, and do not show your working. Re-verify
every number, ID, name, date and pack size against the transcript: what you cannot
point at a line for, delete, or move to Low confidence as heard. Check that you gave
no speaker a gender, title or team the transcript never stated, that no "maybe"/"I
guess" became a commitment, and that no owner was invented. Re-read the last two
minutes specifically: absences, handoffs and coverage are said as the call breaks up
and are the most commonly dropped item in the notes.

${persona.prompt.trim()}''';

/// Hierarchical reduce: when the map notes themselves overflow the window, fold
/// them in batches back into the SAME notes format and reduce again.
///
/// The lossless list must stay in sync with [kNoteEvictionOrder] — the fold and
/// the trim are two ways of shedding tokens and they must shed the SAME thing, or
/// the fold's promise ("carried through losslessly") is a lie the trim tells.
String foldInstruction() => '''
You are given NOTES extracted from several consecutive segments of ONE meeting.
Condense them into a single set of notes in the SAME format, with the same headings
(FACTS / BEHAVIOURS & LIMITS / DECISIONS / PROPOSED ACTIONS / OPEN QUESTIONS /
SPECIFICS / PEOPLE / CONTINUITY / LOW CONFIDENCE), for a later merge pass.

- Merge duplicate lines; keep the earliest [mm:ss].
- BEHAVIOURS & LIMITS, SPECIFICS, DECISIONS, PROPOSED ACTIONS, PEOPLE, CONTINUITY
  and LOW CONFIDENCE are carried through LOSSLESSLY — the final notes cannot be
  rebuilt from anything else. Compress FACTS, and only FACTS.
- Invent nothing. Every line must already exist above.''';

/// Appended (visibly) when even hierarchical folding could not preserve
/// everything. CLAUDE.md: never truncate silently — the user is told what
/// happened and pointed at the transcript.
const String kCompressionNotice =
    '\n\n> ⚠️ This meeting was long enough that some detail was compressed. '
    'Open the transcript for anything not covered here.';

/// Appended when the notes carried uncertain terms and the final document has no
/// Low-confidence section — the model dropped it, or ran out of window before
/// reaching it. Silence there does not read as "detail was lost", it reads as
/// "nothing was uncertain", which is exactly the false certainty this design
/// exists to prevent. CLAUDE.md: no silent degradation.
const String kLowConfidenceDroppedNotice =
    '\n\n> ⚠️ This transcript contained terms that could not be resolved, but they '
    'are not listed above. Treat any unusual name, number, ID or pack size here as '
    'heard, not verified — check it against the transcript.';

/// The map prompt for one chunk. The part-of-N framing matters: it tells the
/// model it is allowed to see an unresolved thread and NOT tie it off.
String buildMapPrompt({
  required TranscriptChunk chunk,
  required String meetingTitle,
}) =>
    '''
${mapInstruction()}

Meeting: ${_title(meetingTitle)}
Part ${chunk.index + 1} of ${chunk.total}.

TRANSCRIPT SEGMENT:
${chunk.text}''';

String buildFoldPrompt({required String notes}) => '''
${foldInstruction()}

NOTES:
$notes''';

String buildReducePrompt({
  required Persona persona,
  required String notes,
  required String meetingTitle,
}) =>
    '''
${reduceInstruction(persona)}

Meeting: ${_title(meetingTitle)}

NOTES:
$notes''';

String buildCriticPrompt({required String notes, required String draft}) => '''
${criticInstruction()}

NOTES:
$notes

DRAFT:
$draft''';

String buildSinglePassPrompt({
  required Persona persona,
  required String transcript,
  required String meetingTitle,
}) =>
    '''
${singlePassInstruction(persona)}

Meeting: ${_title(meetingTitle)}

TRANSCRIPT:
$transcript''';

/// An untitled meeting must not become a hallucination seed — an empty title
/// invites the model to name the meeting from thin air.
String _title(String t) {
  final trimmed = t.trim();
  return trimmed.isEmpty ? '(untitled)' : trimmed;
}
