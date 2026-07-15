import 'package:flutter_test/flutter_test.dart';
import 'package:recap/billing/persona.dart';
import 'package:recap/services/summarizer/prompts.dart';
import 'package:recap/services/summarizer/summary_backend.dart';
import 'package:recap/services/summarizer/summary_pipeline.dart';
import 'package:recap/services/summarizer/summary_types.dart';
import 'package:recap/services/summarizer/token_estimator.dart';

/// The pipeline is where the P0 actually gets fixed: backends are dumb, and this
/// is the only thing that knows a 25-minute meeting does not fit in Gemma's
/// 4096-token COMBINED window. A fake backend records every prompt it is handed,
/// so these tests assert on the SHAPE of the conversation with the model —
/// one call when it fits, map → reduce → critic when it doesn't, and the
/// anti-hallucination preamble present on every single call.
void main() {
  final persona = personasByKey['basic']!;

  group('single pass — it fits', () {
    test('a transcript that fits makes EXACTLY ONE generate call', () async {
      final backend = FakeBackend(
        // Cloud-shaped: 1M context. Everything fits.
        caps: const BackendCapabilities(
          contextTokens: 1000000,
          maxOutputTokens: 8192,
        ),
      );

      final result = await const SummaryPipeline().run(
        backend: backend,
        input: SummaryInput(
          segments: _segments(count: 40, tokensEach: 50),
          meetingTitle: 'RGM sync',
        ),
        persona: persona,
      );

      expect(
        backend.calls.length,
        1,
        reason:
            'summarizing a summary loses detail — when the transcript '
            'fits, map-reduce must be skipped entirely',
      );
      expect(backend.calls.single.stage, Stage.singlePass);
      expect(result.text, isNotEmpty);
      expect(result.modelId, 'fake');
    });

    test(
      'the single-pass call carries the whole transcript and the self-check',
      () async {
        final backend = FakeBackend(
          caps: const BackendCapabilities(
            contextTokens: 1000000,
            maxOutputTokens: 8192,
          ),
        );
        final segs = _segments(count: 10, tokensEach: 40);

        await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(segments: segs, meetingTitle: 'RGM sync'),
          persona: persona,
        );

        final call = backend.calls.single;
        for (final s in segs) {
          expect(
            call.prompt,
            contains(s.text),
            reason: 'the single pass must read the real transcript',
          );
        }
        expect(
          call.prompt,
          contains('SELF-CHECK'),
          reason: 'cloud stays ONE metered call, so the critic is embedded',
        );
        expect(call.prompt, contains('RGM sync'));
      },
    );

    test(
      'an on-device backend takes the single-pass path for a SHORT meeting',
      () async {
        final backend = FakeBackend(caps: _gemma);
        await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 3, tokensEach: 30),
            meetingTitle: 'Standup',
          ),
          persona: persona,
        );
        expect(backend.calls.length, 1);
        expect(backend.calls.single.stage, Stage.singlePass);
      },
    );

    test(
      'an empty model response is a StateError, never a blank summary',
      () async {
        final backend = FakeBackend(
          caps: const BackendCapabilities(
            contextTokens: 1000000,
            maxOutputTokens: 8192,
          ),
          respond: (_) => '   ',
        );

        // CLAUDE.md: no silent degradation — never return "" pretending success.
        expect(
          () => const SummaryPipeline().run(
            backend: backend,
            input: SummaryInput(
              segments: _segments(count: 5, tokensEach: 40),
              meetingTitle: 'RGM sync',
            ),
            persona: persona,
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('map-reduce — it does not fit', () {
    test(
      'runs N map calls, then a reduce, then a critic — in that order',
      () async {
        final backend = FakeBackend(caps: _gemma);

        final result = await const SummaryPipeline().run(
          backend: backend,
          // ~3,600 est. tokens — a real 25-minute meeting, and far past Gemma's
          // 3,072-token input budget.
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'RGM sync',
          ),
          persona: persona,
        );

        final stages = backend.calls.map((c) => c.stage).toList();
        final mapCount = stages.where((s) => s == Stage.map).length;

        expect(
          mapCount,
          greaterThan(1),
          reason: 'a 25-minute meeting must be chunked, not truncated',
        );
        expect(stages.where((s) => s == Stage.singlePass), isEmpty);

        // Order: every map precedes the reduce, which precedes the critic.
        final reduceAt = stages.indexOf(Stage.reduce);
        final criticAt = stages.indexOf(Stage.critic);
        expect(reduceAt, isNot(-1), reason: 'no reduce call was made');
        expect(criticAt, isNot(-1), reason: 'no critic call was made');
        expect(criticAt, greaterThan(reduceAt));
        for (var i = 0; i < stages.length; i++) {
          if (stages[i] == Stage.map) {
            expect(i, lessThan(reduceAt), reason: 'a map ran after the reduce');
          }
        }
        expect(stages.last, Stage.critic);
        expect(
          result.text,
          contains('checked'),
          reason: 'the critic output is what ships, not the raw draft',
        );
      },
    );

    test('no map call ever exceeds the backend input budget', () async {
      final backend = FakeBackend(caps: _gemma);
      await const SummaryPipeline().run(
        backend: backend,
        input: SummaryInput(
          segments: _segments(count: 80, tokensEach: 60),
          meetingTitle: 'RGM sync',
        ),
        persona: persona,
      );

      // This is the whole P0, restated as an assertion.
      for (final c in backend.calls) {
        final total = estimateTokens(c.system ?? '') + estimateTokens(c.prompt);
        expect(
          total,
          lessThanOrEqualTo(_gemma.maxInputTokens),
          reason:
              '${c.stage.name} call is $total est. tokens, over the '
              '${_gemma.maxInputTokens}-token input budget '
              '(${_gemma.contextTokens} context - ${_gemma.maxOutputTokens} '
              'reserved for the answer). This is the overflow bug.',
        );
      }
    });

    test(
      'every chunk of the transcript reaches a map call — nothing is lost',
      () async {
        final backend = FakeBackend(caps: _gemma);
        final segs = _segments(count: 60, tokensEach: 60);

        await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(segments: segs, meetingTitle: 'RGM sync'),
          persona: persona,
        );

        final mapped = backend.calls
            .where((c) => c.stage == Stage.map)
            .map((c) => c.prompt)
            .join('\n');
        for (final s in segs) {
          expect(
            mapped,
            contains(s.text),
            reason:
                'segment at ${s.startMs}ms never reached the model — the '
                'tail of a meeting is exactly where the surgery/handoff line '
                'lives',
          );
        }
      },
    );

    test(
      'map runs at a low temperature (extraction), reduce higher (prose)',
      () async {
        final backend = FakeBackend(caps: _gemma);
        await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'RGM sync',
          ),
          persona: persona,
        );

        final map = backend.calls.firstWhere((c) => c.stage == Stage.map);
        final reduce = backend.calls.firstWhere((c) => c.stage == Stage.reduce);
        final critic = backend.calls.firstWhere((c) => c.stage == Stage.critic);

        expect(map.temperature, lessThan(reduce.temperature));
        expect(
          critic.temperature,
          lessThanOrEqualTo(map.temperature),
          reason: 'the critic must be the most literal pass of all',
        );
      },
    );

    test('a single empty chunk note is dropped, not fatal', () async {
      var n = 0;
      final backend = FakeBackend(
        caps: _gemma,
        respond: (call) {
          if (call.stage == Stage.map) return (n++ == 0) ? '' : 'FACTS\n- x';
          return _defaultResponse(call);
        },
      );

      final result = await const SummaryPipeline().run(
        backend: backend,
        input: SummaryInput(
          segments: _segments(count: 60, tokensEach: 60),
          meetingTitle: 'RGM sync',
        ),
        persona: persona,
      );
      expect(result.text, isNotEmpty);
    });

    test('EVERY chunk coming back empty is a StateError — a broken backend is '
        'not an empty meeting', () async {
      final backend = FakeBackend(
        caps: _gemma,
        respond: (call) =>
            call.stage == Stage.map ? '' : _defaultResponse(call),
      );

      expect(
        () => const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'RGM sync',
          ),
          persona: persona,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('hierarchical reduce', () {
    test('folds when the notes themselves overflow the window', () async {
      final backend = FakeBackend(
        caps: _gemma,
        respond: (call) {
          // Fat notes: each chunk extracts ~900 tokens, so the joined notes blow
          // past the reduce window and must be folded.
          if (call.stage == Stage.map) return _sized(900, 'note');
          if (call.stage == Stage.fold) return _sized(120, 'folded');
          return _defaultResponse(call);
        },
      );

      final result = await const SummaryPipeline().run(
        backend: backend,
        input: SummaryInput(
          segments: _segments(count: 60, tokensEach: 60),
          meetingTitle: 'RGM sync',
        ),
        persona: persona,
      );

      final folds = backend.calls.where((c) => c.stage == Stage.fold);
      expect(
        folds,
        isNotEmpty,
        reason: 'notes over the window must be folded, not truncated',
      );
      for (final f in folds) {
        expect(f.prompt, contains('NOTES:'));
      }
      // The fold shrank the notes enough, so nothing was lost.
      expect(result.text, isNot(contains('compressed')));
    });

    test('a fold that cannot shrink the notes yields the VISIBLE compression '
        'warning', () async {
      final backend = FakeBackend(
        caps: _gemma,
        respond: (call) {
          if (call.stage == Stage.map) return _sized(900, 'note');
          // A fold that refuses to shrink — the model padded instead of
          // condensing. The pipeline must stop folding, trim visibly, and TELL
          // THE USER. Silent truncation is forbidden by CLAUDE.md.
          if (call.stage == Stage.fold) return _sized(1800, 'padded');
          return _defaultResponse(call);
        },
      );

      final result = await const SummaryPipeline().run(
        backend: backend,
        input: SummaryInput(
          segments: _segments(count: 60, tokensEach: 60),
          meetingTitle: 'RGM sync',
        ),
        persona: persona,
      );

      expect(backend.calls.any((c) => c.stage == Stage.fold), isTrue);
      expect(
        result.text,
        contains(kCompressionNotice.trim()),
        reason: 'detail was dropped and the user was not told',
      );
      expect(result.text.toLowerCase(), contains('compressed'));
    });

    test(
      'the fold loop terminates — it never spins on a non-shrinking model',
      () async {
        final backend = FakeBackend(
          caps: _gemma,
          respond: (call) {
            if (call.stage == Stage.map) return _sized(900, 'note');
            if (call.stage == Stage.fold) return _sized(1800, 'padded');
            return _defaultResponse(call);
          },
        );

        await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'RGM sync',
          ),
          persona: persona,
        );

        // A runaway fold would be minutes of GPU time on device.
        expect(
          backend.calls.where((c) => c.stage == Stage.fold).length,
          lessThanOrEqualTo(8),
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test(
      'the reduce prompt never exceeds the window, even after folding',
      () async {
        final backend = FakeBackend(
          caps: _gemma,
          respond: (call) {
            if (call.stage == Stage.map) return _sized(900, 'note');
            if (call.stage == Stage.fold) return _sized(1800, 'padded');
            return _defaultResponse(call);
          },
        );

        await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'RGM sync',
          ),
          persona: persona,
        );

        final reduce = backend.calls.firstWhere((c) => c.stage == Stage.reduce);
        final total =
            estimateTokens(reduce.system ?? '') + estimateTokens(reduce.prompt);
        expect(total, lessThanOrEqualTo(_gemma.maxInputTokens));
      },
    );
  });

  group('critic', () {
    test('is SKIPPED, not fatal, when notes + draft will not fit', () async {
      final hugeDraft = _sized(2500, 'draft');
      final backend = FakeBackend(
        caps: _gemma,
        respond: (call) {
          if (call.stage == Stage.map) return 'FACTS\n- a fact [00:10]';
          if (call.stage == Stage.reduce) return hugeDraft;
          return _defaultResponse(call);
        },
      );

      final result = await const SummaryPipeline().run(
        backend: backend,
        input: SummaryInput(
          segments: _segments(count: 60, tokensEach: 60),
          meetingTitle: 'RGM sync',
        ),
        persona: persona,
      );

      expect(
        backend.calls.where((c) => c.stage == Stage.critic),
        isEmpty,
        reason: 'the critic prompt does not fit and must be skipped',
      );
      expect(
        result.text,
        hugeDraft,
        reason:
            'a skipped critic keeps the draft — it must never fail the '
            'summary or return blank',
      );
    });

    test(
      'a critic returning nothing keeps the draft rather than blanking it',
      () async {
        final backend = FakeBackend(
          caps: _gemma,
          respond: (call) {
            if (call.stage == Stage.map) return 'FACTS\n- a fact [00:10]';
            if (call.stage == Stage.reduce) return '## TL;DR\n- the real draft';
            if (call.stage == Stage.critic) return '';
            return _defaultResponse(call);
          },
        );

        final result = await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'RGM sync',
          ),
          persona: persona,
        );
        expect(result.text, '## TL;DR\n- the real draft');
      },
    );

    test(
      'the critic sees BOTH the notes and the draft — it cannot diff one',
      () async {
        final backend = FakeBackend(caps: _gemma);
        await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'RGM sync',
          ),
          persona: persona,
        );

        final critic = backend.calls.firstWhere((c) => c.stage == Stage.critic);
        expect(critic.prompt, contains('NOTES:'));
        expect(critic.prompt, contains('DRAFT:'));
        expect(
          critic.prompt,
          contains('Low confidence'),
          reason:
              'the critic must be able to MOVE an uncertain term rather '
              'than delete it',
        );
        expect(
          critic.prompt.toLowerCase(),
          contains('restore'),
          reason:
              'a delete-only critic cannot fix the dropped-continuity '
              'failure (Granola bug #3)',
        );
      },
    );
  });

  group('the prompts that actually reach the model', () {
    const glossary = ['Scan Apps', 'RGM', 'PTC-driven', 'must-buy', 'loyalty'];

    test('the generating stages carry the full ASR-repair rules; the critic '
        'carries the lighter verify-only system so it fits the window', () async {
      final backend = FakeBackend(caps: _gemma);
      await const SummaryPipeline().run(
        backend: backend,
        input: SummaryInput(
          segments: _segments(count: 60, tokensEach: 60),
          meetingTitle: 'RGM sync',
          glossary: glossary,
        ),
        persona: persona,
      );

      expect(backend.calls.length, greaterThan(2));
      for (final c in backend.calls) {
        expect(
          c.system,
          isNotNull,
          reason:
              '${c.stage.name} was sent with no system prompt — that '
              'call has NO guardrails at all',
        );
        if (c.stage == Stage.critic) {
          // The critic reads notes + a draft, not the transcript, and must NOT
          // repair terms — so it gets kCriticSystem, not the full 8-rule
          // preamble. That ~565-token saving is exactly what lets the critic fit
          // a 4096-token window and actually run on a map-reduced meeting; with
          // the full preamble it was structurally skipped. The safety-relevant
          // invariant (never add info, only remove/flag) is still present.
          expect(c.system, kCriticSystem);
          expect(c.system!.toLowerCase(), contains('never add information'));
        } else {
          // Every stage that GENERATES content still carries all the rules.
          expect(c.system!, contains("REPAIR, DON'T GUESS"));
          expect(c.system!, contains('NEVER FABRICATE SPECIFICS'));
          expect(c.system!, contains('PRESERVE CONTINUITY'));
          expect(c.system!, contains('ATTRIBUTE'));
        }
      }
    });

    test(
      'the map prompt is fed the glossary terms so ASR repair can happen',
      () async {
        final backend = FakeBackend(caps: _gemma);
        await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'RGM sync',
            glossary: glossary,
          ),
          persona: persona,
        );

        final map = backend.calls.firstWhere((c) => c.stage == Stage.map);
        // The glossary is what turns "skin apps" into Scan Apps.
        for (final term in glossary) {
          expect(
            map.system!,
            contains(term),
            reason: 'glossary term "$term" never reached the map call',
          );
        }
        expect(map.prompt, contains('TRANSCRIPT SEGMENT:'));
        expect(map.prompt, contains('Extract structured notes'));
        expect(
          map.prompt,
          contains('LOW CONFIDENCE'),
          reason:
              'the uncertainty channel must exist at extraction time, or '
              'there is nothing left to mark uncertain later',
        );
        expect(map.prompt, contains('CONTINUITY'));
        expect(map.prompt, contains('RGM sync'));
      },
    );

    test(
      'map prompts are part-numbered so the model may leave a thread open',
      () async {
        final backend = FakeBackend(caps: _gemma);
        await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'RGM sync',
          ),
          persona: persona,
        );

        final maps = backend.calls.where((c) => c.stage == Stage.map).toList();
        for (var i = 0; i < maps.length; i++) {
          expect(maps[i].prompt, contains('Part ${i + 1} of ${maps.length}'));
        }
      },
    );

    test(
      'the reduce prompt carries the persona lens and the mandatory sections',
      () async {
        final backend = FakeBackend(caps: _gemma);
        final sales = personasByKey['sales_call']!;

        await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'RGM sync',
          ),
          persona: sales,
        );

        final reduce = backend.calls.firstWhere((c) => c.stage == Stage.reduce);
        expect(reduce.prompt, contains('## People & continuity'));
        expect(reduce.prompt, contains('Low confidence'));
        expect(
          reduce.prompt,
          contains(sales.prompt.trim()),
          reason: 'the persona is a LENS appended to the shared contract',
        );
      },
    );

    test('an untitled meeting is never a hallucination seed', () async {
      final backend = FakeBackend(caps: _gemma);
      await const SummaryPipeline().run(
        backend: backend,
        input: SummaryInput(
          segments: _segments(count: 60, tokensEach: 60),
          meetingTitle: '   ',
        ),
        persona: persona,
      );
      final map = backend.calls.firstWhere((c) => c.stage == Stage.map);
      expect(map.prompt, contains('(untitled)'));
    });
  });

  group('cancellation', () {
    test(
      'cancelling BETWEEN chunks throws SummaryCancelled and stops the work',
      () async {
        final cancel = CancelToken();
        final backend = FakeBackend(
          caps: _gemma,
          onCall: (call) {
            // The user hits Cancel while chunk 1 is in flight.
            if (call.stage == Stage.map && call.index == 0) cancel.cancel();
          },
        );

        await expectLater(
          const SummaryPipeline().run(
            backend: backend,
            input: SummaryInput(
              segments: _segments(count: 80, tokensEach: 60),
              meetingTitle: 'RGM sync',
            ),
            persona: persona,
            cancel: cancel,
          ),
          throwsA(isA<SummaryCancelled>()),
        );

        final maps = backend.calls.where((c) => c.stage == Stage.map).length;
        expect(
          maps,
          1,
          reason:
              'the pipeline kept mapping after the user cancelled — '
              'on device that is minutes of wasted GPU time',
        );
        expect(backend.calls.any((c) => c.stage == Stage.reduce), isFalse);
      },
    );

    test('a token cancelled up front does no work at all', () async {
      final cancel = CancelToken()..cancel();
      final backend = FakeBackend(caps: _gemma);

      await expectLater(
        const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'RGM sync',
          ),
          persona: persona,
          cancel: cancel,
        ),
        throwsA(isA<SummaryCancelled>()),
      );
      expect(backend.calls, isEmpty);
    });

    test(
      'the CancelToken is handed to the backend so it can abort mid-flight',
      () async {
        final cancel = CancelToken();
        final backend = FakeBackend(caps: _gemma);

        await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'RGM sync',
          ),
          persona: persona,
          cancel: cancel,
        );

        for (final c in backend.calls) {
          expect(
            c.sawCancelToken,
            isTrue,
            reason:
                '${c.stage.name} cannot be interrupted — Gemma exposes '
                'stopGeneration() and the pipeline must pass the token down',
          );
        }
      },
    );

    test('cancelling during the single pass throws SummaryCancelled', () async {
      final cancel = CancelToken();
      final backend = FakeBackend(
        caps: const BackendCapabilities(
          contextTokens: 1000000,
          maxOutputTokens: 8192,
        ),
        onCall: (_) => cancel.cancel(),
      );

      await expectLater(
        const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: _segments(count: 10, tokensEach: 40),
            meetingTitle: 'RGM sync',
          ),
          persona: persona,
          cancel: cancel,
        ),
        throwsA(isA<SummaryCancelled>()),
      );
    });
  });

  group('empty transcript', () {
    test('no segments throws StateError', () async {
      expect(
        () => const SummaryPipeline().run(
          backend: FakeBackend(caps: _gemma),
          input: const SummaryInput(segments: [], meetingTitle: 'RGM sync'),
          persona: persona,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'segments that render blank throws StateError, never a blank summary',
      () async {
        final backend = FakeBackend(caps: _gemma);
        expect(
          () => const SummaryPipeline().run(
            backend: backend,
            input: const SummaryInput(
              segments: [
                PromptSegment(text: '   '),
                PromptSegment(text: '\n'),
              ],
              meetingTitle: 'RGM sync',
            ),
            persona: persona,
          ),
          throwsA(isA<StateError>()),
        );
        expect(backend.calls, isEmpty, reason: 'do not burn a call on nothing');
      },
    );

    test('the StateError names the meeting, per CLAUDE.md', () async {
      try {
        await const SummaryPipeline().run(
          backend: FakeBackend(caps: _gemma),
          input: const SummaryInput(segments: [], meetingTitle: 'RGM sync'),
          persona: persona,
        );
        fail('expected a StateError');
      } on StateError catch (e) {
        expect(e.message, contains('RGM sync'));
      }
    });
  });

  group('progress', () {
    test('reports monotonic progress and ends at done/1.0', () async {
      final seen = <SummaryProgress>[];
      final backend = FakeBackend(caps: _gemma);

      await const SummaryPipeline().run(
        backend: backend,
        input: SummaryInput(
          segments: _segments(count: 60, tokensEach: 60),
          meetingTitle: 'RGM sync',
        ),
        persona: persona,
        onProgress: seen.add,
      );

      expect(seen, isNotEmpty);
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i].step, greaterThanOrEqualTo(seen[i - 1].step));
        expect(
          seen[i].step,
          lessThanOrEqualTo(seen[i].totalSteps),
          reason: 'the UI would render "part 9 of 7"',
        );
        expect(seen[i].fraction, inInclusiveRange(0, 1));
      }
      expect(seen.last.stage, SummaryStage.done);
      expect(seen.last.fraction, 1.0);

      final stages = seen.map((p) => p.stage).toSet();
      expect(stages, contains(SummaryStage.mapping));
      expect(stages, contains(SummaryStage.reducing));
      expect(stages, contains(SummaryStage.checking));

      // The label the user actually reads.
      expect(seen.any((p) => p.label.contains('Reading part 1 of')), isTrue);
    });
  });

  group('mechanical safety net — deterministic, no model judgment', () {
    test(
      'injects a dropped figure, a dictated ID, and an end handoff',
      () async {
        final segs = [
          const PromptSegment(
            speaker: 'Ana',
            startMs: 0,
            text: 'Revenue came in at 4.2 million for the quarter, up nicely.',
          ),
          const PromptSegment(
            speaker: 'Ben',
            startMs: 5000,
            text: 'The incident ticket is 7 3 0 2 if anyone needs it.',
          ),
          const PromptSegment(
            speaker: 'Ana',
            startMs: 10000,
            text:
                "I'm having surgery next week, so reach out to Lisa for "
                'anything urgent while I am out.',
          ),
        ];
        // A backend that writes a THIN summary, dropping all three — the safety
        // net must restore them regardless of what the model chose to keep.
        final backend = FakeBackend(
          caps: const BackendCapabilities(
            contextTokens: 1000000,
            maxOutputTokens: 8192,
          ),
          respond: (_) => '## TL;DR\n- The team met and discussed the quarter.',
        );
        final r = await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(segments: segs, meetingTitle: 'Q review'),
          persona: personasByKey['basic']!,
        );
        final t = r.text.toLowerCase();
        expect(
          t,
          contains('4.2 million'),
          reason: 'figure sweep must restore a figure the model dropped',
        );
        expect(
          t,
          contains('7302'),
          reason: 'digit detection must join the dictated ID 7 3 0 2 -> 7302',
        );
        expect(
          t,
          contains('lisa'),
          reason: 'continuity detection must restore the surgery handoff',
        );
      },
    );

    test(
      'does not fabricate — a clean meeting gets no injected junk',
      () async {
        final segs = [
          const PromptSegment(
            speaker: 'Ana',
            startMs: 0,
            text: 'Good morning, quick sync.',
          ),
          const PromptSegment(
            speaker: 'Ben',
            startMs: 4000,
            text: 'All green on my side, nothing to report.',
          ),
        ];
        final backend = FakeBackend(
          caps: const BackendCapabilities(
            contextTokens: 1000000,
            maxOutputTokens: 8192,
          ),
          respond: (_) =>
              '## TL;DR\n- Quick sync, all green.\n\n## Decisions\n- None.',
        );
        final r = await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(segments: segs, meetingTitle: 'Sync'),
          persona: personasByKey['basic']!,
        );
        // No figures/digits/handoffs in the transcript -> no injected sections.
        expect(r.text.contains('Other key details'), isFalse);
        expect(r.text.toLowerCase(), isNot(contains('heard, unverified')));
      },
    );
  });

  _planForTests();
}

// ---------------------------------------------------------------------------
// Fake backend
// ---------------------------------------------------------------------------

/// Gemma's real window: 4096 COMBINED input+output, so 3,072 tokens of input.
/// This is the exact budget the P0 overflowed.
const _gemma = BackendCapabilities(
  contextTokens: 4096,
  maxOutputTokens: 1024,
  supportsSystemPrompt: false,
);

void _planForTests() {
  group('planFor — the long-meeting escalation signal', () {
    test('a short meeting is not flagged for map-reduce', () {
      final plan = SummaryPipeline.planFor(
        input: SummaryInput(
          segments: _segments(count: 3, tokensEach: 30),
          meetingTitle: 'Standup',
        ),
        caps: _gemma,
      );
      expect(plan.willMapReduce, isFalse);
      expect(plan.isLong, isFalse);
      expect(plan.chunkCount, 1);
    });

    test(
      'a long meeting IS flagged, with >1 chunk — the UI would offer cloud',
      () {
        final plan = SummaryPipeline.planFor(
          input: SummaryInput(
            segments: _segments(count: 60, tokensEach: 60),
            meetingTitle: 'Q3 board',
          ),
          caps: _gemma,
        );
        expect(plan.willMapReduce, isTrue);
        expect(plan.isLong, isTrue);
        expect(plan.chunkCount, greaterThan(1));
      },
    );

    test('the SAME meeting fits single-pass on a big (cloud) window', () {
      final input = SummaryInput(
        segments: _segments(count: 60, tokensEach: 60),
        meetingTitle: 'Q3 board',
      );
      expect(
        SummaryPipeline.planFor(input: input, caps: _gemma).willMapReduce,
        isTrue,
      );
      expect(
        SummaryPipeline.planFor(
          input: input,
          caps: const BackendCapabilities(
            contextTokens: 1000000,
            maxOutputTokens: 8192,
          ),
        ).willMapReduce,
        isFalse,
        reason:
            'a bigger window is exactly why cloud escapes the fold — the '
            'preview must reflect that so the offer is honest',
      );
    });

    test('the preview matches what run() actually does', () async {
      final input = SummaryInput(
        segments: _segments(count: 60, tokensEach: 60),
        meetingTitle: 'Q3 board',
      );
      final plan = SummaryPipeline.planFor(input: input, caps: _gemma);
      final backend = FakeBackend(caps: _gemma);
      await const SummaryPipeline().run(
        backend: backend,
        input: input,
        persona: personasByKey['basic']!,
      );
      final mapCalls = backend.calls.where((c) => c.stage == Stage.map).length;
      expect(plan.willMapReduce, mapCalls > 0);
      expect(
        plan.chunkCount,
        mapCalls,
        reason: 'planFor must predict the exact chunk count run() produces',
      );
    });
  });
}

enum Stage { singlePass, map, fold, reduce, critic, unknown }

class Call {
  Call({
    required this.index,
    required this.prompt,
    required this.system,
    required this.temperature,
    required this.sawCancelToken,
  });

  final int index;
  final String prompt;
  final String? system;
  final double temperature;
  final bool sawCancelToken;

  /// Which pipeline stage this prompt came from, keyed off the composers in
  /// `prompts.dart`. Order matters: the critic prompt also contains "NOTES:".
  Stage get stage {
    if (prompt.contains('TRANSCRIPT SEGMENT:')) return Stage.map;
    if (prompt.contains('DRAFT:')) return Stage.critic;
    if (prompt.contains('Condense them into a single set of notes')) {
      return Stage.fold;
    }
    if (prompt.contains('You are given structured NOTES')) return Stage.reduce;
    if (prompt.contains('SELF-CHECK')) return Stage.singlePass;
    return Stage.unknown;
  }
}

/// Records every prompt the pipeline hands it. The pipeline is the unit under
/// test; the model is not.
class FakeBackend implements SummaryBackend {
  FakeBackend({
    required BackendCapabilities caps,
    String Function(Call call)? respond,
    void Function(Call call)? onCall,
    // `caps`/`onCall` are public named params (call sites pass them);
    // this._caps would rename them, so the initializing-formal lint can't apply.
    // ignore: prefer_initializing_formals
  }) : _caps = caps,
       _respond = respond ?? _defaultResponse,
       // ignore: prefer_initializing_formals
       _onCall = onCall;

  final BackendCapabilities _caps;
  final String Function(Call) _respond;
  final void Function(Call)? _onCall;

  final List<Call> calls = <Call>[];

  @override
  String get modelId => 'fake';

  @override
  BackendCapabilities get capabilities => _caps;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> generate({
    required String prompt,
    String? system,
    double temperature = 0.4,
    int? maxOutputTokens,
    CancelToken? cancel,
  }) async {
    final call = Call(
      index: calls.where((c) => c.stage == Stage.map).length,
      prompt: prompt,
      system: system,
      temperature: temperature,
      sawCancelToken: cancel != null,
    );
    calls.add(call);
    _onCall?.call(call);
    return _respond(call);
  }
}

String _defaultResponse(Call call) {
  switch (call.stage) {
    case Stage.map:
      return 'FACTS\n- a stated fact [00:10]\nSPECIFICS\n- 65766 '
          '(heard, unverified) [07:11]';
    case Stage.fold:
      return 'FACTS\n- a folded fact [00:10]';
    case Stage.reduce:
      return '## TL;DR\n- the draft [00:10]';
    case Stage.critic:
      return '## TL;DR\n- the checked draft [00:10]';
    case Stage.singlePass:
      return '## TL;DR\n- the single-pass notes [00:10]';
    case Stage.unknown:
      return 'unclassified prompt: ${call.prompt.substring(0, 80)}';
  }
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// A synthetic transcript of [count] alternating-speaker segments of roughly
/// [tokensEach] estimated tokens each.
List<PromptSegment> _segments({required int count, required int tokensEach}) =>
    [
      for (var i = 0; i < count; i++)
        PromptSegment(
          startMs: i * 5000,
          endMs: i * 5000 + 4000,
          speaker: 'Speaker ${(i % 2) + 1}',
          text: _sized(tokensEach, 'seg$i'),
        ),
    ];

/// Text of approximately [tokens] estimated tokens, uniquely tagged so a
/// `contains` assertion cannot pass by accident.
String _sized(int tokens, String tag) {
  final chars = (tokens * 3.6).round();
  final b = StringBuffer();
  var n = 0;
  while (b.length < chars) {
    b.write('$tag-$n ');
    n++;
  }
  return b.toString().trim();
}
