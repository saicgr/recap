import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../main.dart';
import '../services/audio/mic_policy.dart';
import '../services/calendar_matcher.dart';
import '../services/live_captions.dart';
import '../services/wav_utils.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late final String _id;
  late final Directory _recordingsDir;
  // List of WAV chunk paths — one per pause/resume segment. Merged on Transcribe.
  final List<String> _chunkPaths = [];
  String _currentChunkPath = '';
  int _chunkIndex = 0;

  late final DateTime _start;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _paused = false;
  bool _starting = true;
  bool _switchingMic = false;
  String? _error;
  final String _persona = 'Meeting notes';

  /// Shown when we are forced to record through Bluetooth (user pinned it, or
  /// it is genuinely the only input). Never a silent quality loss.
  String? _micWarning;

  final List<LiveCaption> _captions = [];
  StreamSubscription<LiveCaption>? _captionSub;
  Duration? _cap;
  bool _flashBookmark = false;
  int _bookmarkCount = 0;

  @override
  void initState() {
    super.initState();
    _id = const Uuid().v4();
    _start = DateTime.now();
    _cap = entitlements.maxMeetingDuration;
    _begin();
  }

  String _chunkPath(int index) =>
      p.join(_recordingsDir.path, '${_id}__$index.wav');

  /// The calendar event this recording appears to be, if any. Resolved in the
  /// background while recording; read once at save time.
  CalendarMatch? _calendarMatch;

  Future<void> _matchCalendarEvent() async {
    try {
      final match = await calendarMatcher.matchNow();
      if (!mounted) return;
      if (match.eventTitle != null && match.eventTitle!.trim().isNotEmpty) {
        setState(() => _calendarMatch = match);
      }
    } catch (_) {
      // Permission denied, no calendars, or the plugin threw. The recording is
      // the product; a missing title is a cosmetic loss and must never surface
      // as an error mid-record.
    }
  }

  Future<void> _begin() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      _recordingsDir = Directory(p.join(docs.path, 'recordings'));
      if (!await _recordingsDir.exists()) {
        await _recordingsDir.create(recursive: true);
      }
      _currentChunkPath = _chunkPath(_chunkIndex);
      _chunkPaths.add(_currentChunkPath);

      // Usage counter is independent of the mic — fire and forget.
      unawaited(entitlements.recordMeetingStarted().catchError((_) {}));

      // Ask the device calendar what meeting is happening right now, so the
      // recording gets the event's real name instead of "Meeting on Jul 14".
      // Matched at START (that is when the meeting is actually on) and applied
      // at save. Purely local — the OS calendar API, no network — so it works
      // on the Privacy tier too. CalendarMatcher has existed, complete, since
      // the first commit and was never once called.
      //
      // Fire-and-forget: a calendar permission prompt must never delay or block
      // the mic. If it fails or the user declines, we keep the date-based title.
      unawaited(_matchCalendarEvent());

      // Critical path: open the mic (this is what triggers the runtime
      // permission prompt on Android first-run).
      // Records from the BUILT-IN mic even when AirPods are connected — see
      // MicPolicy. They keep playing audio over A2DP; we just refuse to capture
      // through their narrowband HFP microphone.
      final choice =
          await recorder.start(_currentChunkPath, pinnedDeviceId: settings.pinnedMicId);
      if (mounted && MicPolicy.shouldWarn(choice)) {
        setState(() => _micWarning = MicPolicy.warning);
      }

      // The Android foreground-service type=microphone requires RECORD_AUDIO
      // to already be granted. Only safe to start it after recorder.start()
      // returns successfully — at that point the mic permission has been
      // granted and Android will let us run a microphone FGS.
      unawaited(backgroundRecorder
          .startForeground(meetingTitle: 'Recording…')
          .catchError((_) {}));

      // Captions reader (depends on the WAV file existing — which it does
      // now that the recorder has started writing it).
      unawaited(_startCaptions(_currentChunkPath).catchError((_) {}));

      if (!mounted) return;
      setState(() => _starting = false);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_paused && mounted) {
          setState(() => _elapsed += const Duration(seconds: 1));
          if (_cap != null && _elapsed >= _cap!) _transcribe();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _startCaptions(String sourcePath) async {
    await _captionSub?.cancel();
    await liveCaptions.start(sourceWavPath: sourcePath);
    _captionSub = liveCaptions.captions.listen((c) {
      if (mounted) setState(() => _captions.add(c));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _captionSub?.cancel();
    liveCaptions.stop();
    backgroundRecorder.stopForeground();
    super.dispose();
  }

  Future<void> _togglePause() async {
    if (_switchingMic) return;
    _switchingMic = true;
    try {
      if (_paused) {
        // RESUME → start a fresh chunk file + acquire mic again.
        _chunkIndex++;
        _currentChunkPath = _chunkPath(_chunkIndex);
        _chunkPaths.add(_currentChunkPath);
        await recorder.start(_currentChunkPath, pinnedDeviceId: settings.pinnedMicId);
        await _startCaptions(_currentChunkPath);
      } else {
        // PAUSE → stop the recorder (closes file, releases mic, kills the
        // Android system green-dot indicator).
        await liveCaptions.stop();
        await recorder.stop();
      }
      if (!mounted) return;
      setState(() => _paused = !_paused);
    } finally {
      _switchingMic = false;
    }
  }

  Future<void> _discard() async {
    _timer?.cancel();
    await liveCaptions.stop();
    try {
      if (!_paused) await recorder.stop();
    } catch (_) {}
    await backgroundRecorder.stopForeground();
    for (final path in _chunkPaths) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _transcribe() async {
    if (!_starting && _timer == null) return;
    _timer?.cancel();
    _timer = null;

    // Best-effort: stop the mic + foreground service + captions in parallel
    // so we can pop ASAP. Errors are swallowed — at this point we've already
    // committed to leaving the screen, and the home list shows the meeting
    // either way.
    final stopOps = <Future<void>>[
      liveCaptions.stop(),
      if (!_paused) recorder.stop().then((_) {}).catchError((_) {}),
      backgroundRecorder.stopForeground(),
    ];

    final mergedPath = p.join(_recordingsDir.path, '$_id.wav');

    // 1. Insert the meeting row with "processing" status now, so the home
    //    list shows it immediately when we pop. The actual audio file
    //    doesn't exist on disk yet — the background worker creates it.
    // Prefer the calendar event's name. "Q3 Board Review" beats "Meeting on
    // Jul 14, 2:00 PM" — and Meetings.calendarEventId has existed since the
    // first commit without ever being written to.
    final calendarTitle = _calendarMatch?.eventTitle?.trim();
    final meeting = MeetingsCompanion.insert(
      id: _id,
      title: (calendarTitle != null && calendarTitle.isNotEmpty)
          ? calendarTitle
          : 'Meeting on ${DateFormat('MMM d, h:mm a').format(_start)}',
      audioPath: mergedPath,
      createdAt: _start,
      updatedAt: DateTime.now(),
      status: MeetingStatus.processing,
      durationMs: Value(_elapsed.inMilliseconds),
      language: const Value('en'),
      calendarEventId: Value(_calendarMatch?.eventId),
    );
    await db.into(db.meetings).insert(meeting);

    // 2. Snapshot what we need for background work (no more `this` access
    //    after pop — State will be disposed).
    final chunks = List<String>.of(_chunkPaths);
    final captions = List<LiveCaption>.of(_captions);
    final elapsed = _elapsed;
    final meetingId = _id;

    // 3. Pop immediately — user sees the home list.
    if (!mounted) return;
    Navigator.pop(context);

    // 4. Finish stop ops + merge + caption batch + transcription in the
    //    background, all off the UI critical path.
    unawaited(_finalizeInBackground(
      stopOps: stopOps,
      meetingId: meetingId,
      chunks: chunks,
      mergedPath: mergedPath,
      captions: captions,
      elapsed: elapsed,
    ));
  }

  Future<void> _finalizeInBackground({
    required List<Future<void>> stopOps,
    required String meetingId,
    required List<String> chunks,
    required String mergedPath,
    required List<LiveCaption> captions,
    required Duration elapsed,
  }) async {
    try {
      // Wait for recorder.stop() + captions.stop() to flush their last chunk.
      await Future.wait(stopOps).timeout(
        const Duration(seconds: 5),
        onTimeout: () => const <void>[],
      );

      // Streaming WAV merge — runs through 64 KB buffers, no big allocations.
      await WavUtils.mergeWavs(
        inputPaths: chunks,
        outputPath: mergedPath,
      );

      // Best-effort: delete the intermediate chunks now that the merge exists.
      for (final path in chunks) {
        if (path == mergedPath) continue;
        final f = File(path);
        if (await f.exists()) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }

      // Persist caption segments + bump usage counters off the UI thread.
      if (captions.isNotEmpty) {
        await db.batch((batch) {
          for (final c in captions) {
            batch.insert(
              db.transcriptSegments,
              TranscriptSegmentsCompanion.insert(
                id: const Uuid().v4(),
                meetingId: meetingId,
                startMs: c.startMs,
                endMs: c.endMs,
                body: c.text,
                isFinal: const Value(false),
              ),
            );
          }
        });
      }

      await entitlements.recordMeetingFinished(duration: elapsed);

      // Now the heavy step — Whisper transcription + diarization.
      await _runFinalTranscription(meetingId, mergedPath, elapsed);
    } catch (e) {
      await (db.update(db.meetings)..where((t) => t.id.equals(meetingId)))
          .write(MeetingsCompanion(
        status: const Value(MeetingStatus.failed),
        failureReason: Value(e.toString()),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  Future<void> _runFinalTranscription(
      String id, String path, Duration elapsed) async {
    try {
      // Route the final pass through AsrRouter instead of calling the Whisper
      // transcriber directly. By default the router resolves to Whisper (native
      // ASR is off until it has been device-tested), so this is a pure refactor:
      // the same engine transcribes, but the tier/preference/platform decision
      // now lives in the router rather than being hardcoded here — and the
      // Privacy tier's Whisper-only guarantee is enforced there.
      final engine = await asrRouter.pickFileEngine(approxDuration: elapsed);
      if (engine == null) {
        // Never a silent empty transcript. The audio is safe; surface it so the
        // user can retry rather than see a blank transcript and assume failure.
        throw StateError(
          'No transcription engine is available. Make sure the Whisper model '
          'has finished downloading, then retry.',
        );
      }

      // Whisper needs its model on disk; a native engine does not, so only gate
      // on the download when Whisper was actually chosen.
      if (engine.id == 'whisper') {
        final deadline = DateTime.now().add(const Duration(minutes: 2));
        while (!await transcriber.isModelInstalled) {
          if (DateTime.now().isAfter(deadline)) {
            throw StateError('Model still downloading after 2 minutes.');
          }
          await Future<void>.delayed(const Duration(seconds: 3));
        }
      }

      final text = await engine.transcribeFile(path);
      await db.into(db.transcripts).insertOnConflictUpdate(
            TranscriptsCompanion.insert(
              meetingId: id,
              body: text,
              modelId: engine.id == 'whisper'
                  ? transcriber.model.modelName
                  : engine.id,
              createdAt: DateTime.now(),
            ),
          );
      // Run diarization only if the user's tier allows speaker labels — no
      // point doing the work otherwise.
      if (entitlements.currentTier.speakerLabels) {
        await _runDiarization(id, path);
      }
      // Index for search + chat. After diarization, so speaker labels are on the
      // segments before they are embedded.
      await _indexEmbeddings(id);
      await (db.update(db.meetings)..where((t) => t.id.equals(id))).write(
        MeetingsCompanion(
          status: const Value(MeetingStatus.ready),
          durationMs: Value(elapsed.inMilliseconds),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      await (db.update(db.meetings)..where((t) => t.id.equals(id))).write(
        MeetingsCompanion(
          status: const Value(MeetingStatus.failed),
          failureReason: Value(e.toString()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Build the vector index for this meeting so it is searchable and
  /// chat-answerable.
  ///
  /// Runs AFTER diarization, so the speaker labels are already on the segments.
  /// Best-effort: the recording and its transcript are the product, and a
  /// missing optional embedding model must never fail a meeting the user just
  /// finished. Returns 0 silently when MiniLM is not installed.
  Future<void> _indexEmbeddings(String id) async {
    try {
      await embeddingIndexer.indexMeeting(id);
    } catch (_) {
      // Search degrades to keyword-only. Not worth surfacing.
    }
  }

  Future<void> _runDiarization(String id, String mergedWavPath) async {
    final segs = await db.segmentsFor(id);
    if (segs.isEmpty) return;
    final inputs = segs
        .map((s) => (startMs: s.startMs, endMs: s.endMs))
        .toList(growable: false);
    final labels = await diarizer.diarize(
      wavPath: mergedWavPath,
      segments: inputs,
    );
    if (labels.length != segs.length) return;
    await db.batch((batch) {
      for (var i = 0; i < segs.length; i++) {
        final label = labels[i];
        if (label == null) continue;
        batch.update(
          db.transcriptSegments,
          TranscriptSegmentsCompanion(speakerLabel: Value(label)),
          where: (t) => t.id.equals(segs[i].id),
        );
      }
    });
  }

  Future<void> _bookmark() async {
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(
          id: const Uuid().v4(),
          meetingId: _id,
          atMs: _elapsed.inMilliseconds,
          createdAt: DateTime.now(),
        ));
    if (!mounted) return;
    setState(() {
      _flashBookmark = true;
      _bookmarkCount++;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _flashBookmark = false);
    });
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hh = d.inHours;
    final mm = d.inMinutes.remainder(60);
    final ss = d.inSeconds.remainder(60);
    return hh > 0
        ? '${two(hh)}:${two(mm)}:${two(ss)}'
        : '${two(mm)}:${two(ss)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);

    if (_error != null) {
      return Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_off, size: 48, color: t.recordRed),
                  const SizedBox(height: 16),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: RT.body.copyWith(color: t.textPrimary)),
                  const SizedBox(height: 16),
                  Btn(
                      label: 'Back',
                      variant: BtnVariant.secondary,
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_starting) {
      return Scaffold(
        backgroundColor: t.bg,
        body: Center(
          child: CircularProgressIndicator(color: t.accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Recording through Bluetooth means narrowband call-quality audio
            // and a visibly worse transcript. The whole point of this feature is
            // that the user is TOLD, instead of silently getting a bad result
            // and never knowing why.
            if (_micWarning != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: t.recordRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: t.recordRed.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.bluetooth_audio,
                        size: 16, color: t.recordRed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_micWarning!,
                          style: RT.caption.copyWith(color: t.textPrimary)),
                    ),
                  ],
                ),
              ),
            // Status pill row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statusPill(t),
                  // Back button — leaves the recording screen (currently
                  // stops recording, since we don't have proper background
                  // recording yet).
                  IconBtn(
                    icon: Icons.close,
                    onPressed: () => _confirmExit(),
                  ),
                ],
              ),
            ),
            // Timer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 8),
              child: Center(
                child: Column(
                  children: [
                    Text(_fmt(_elapsed),
                        style: RT.timer.copyWith(color: t.textPrimary)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, size: 13, color: t.textMuted),
                        const SizedBox(width: 6),
                        Text(
                            'On-device · Whisper ${transcriber.model.modelName}',
                            style: RT.label.copyWith(color: t.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Waveform
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Center(
                child: Waveform(bars: 48, active: !_paused, height: 36),
              ),
            ),
            // Live captions card
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: t.surface,
                  border: Border.all(color: t.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Text('LIVE CAPTIONS',
                              style: RT.caption.copyWith(color: t.textMuted)),
                          if (_bookmarkCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: t.accentSoft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$_bookmarkCount bookmark${_bookmarkCount == 1 ? "" : "s"}',
                                style: RT.caption.copyWith(color: t.accent),
                              ),
                            ),
                          ],
                        ]),
                        _bookmarkBtn(t),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        reverse: true,
                        child: _captions.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Center(
                                  child: Text('Listening…',
                                      style:
                                          RT.body.copyWith(color: t.textMuted)),
                                ),
                              )
                            : Text(
                                _captions.map((c) => c.text).join(' '),
                                style: TextStyle(
                                  fontSize: 22,
                                  height: 32 / 22,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.33,
                                  color: t.textPrimary,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Controls — each is icon + label in a column so labels line
            // up with their icons regardless of icon size.
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _controlCol(
                    t,
                    label: 'Discard',
                    onTap: _discard,
                    child: _circleIcon(t, Icons.delete_outline),
                  ),
                  _controlCol(
                    t,
                    label: _paused ? 'Resume' : 'Pause',
                    onTap: _togglePause,
                    child: _bigToggleBtn(t),
                  ),
                  _controlCol(
                    t,
                    label: 'Stop',
                    onTap: _transcribe,
                    child: _circleIcon(t, Icons.stop),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(RecapTheme t, IconData icon) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.bgSubtle,
        border: Border.all(color: t.border),
      ),
      child: Icon(icon, size: 22, color: t.textSecondary),
    );
  }

  Widget _bigToggleBtn(RecapTheme t) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _paused ? t.accent : t.recordRed,
        boxShadow: [
          BoxShadow(
            color: (_paused ? t.accent : t.recordRed).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        _paused ? Icons.play_arrow : Icons.pause,
        size: 30,
        color: Colors.white,
      ),
    );
  }

  Widget _controlCol(
    RecapTheme t, {
    required String label,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: 8),
          Text(label.toUpperCase(),
              style: RT.caption.copyWith(color: t.textMuted)),
        ],
      ),
    );
  }

  Widget _statusPill(RecapTheme t) {
    // When recording → pulsing red dot. When paused → no dot (label says it).
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: t.bgSubtle,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_paused) ...[
            const RecDot(size: 7),
            const SizedBox(width: 6),
          ],
          Text(
            '${_paused ? "Paused" : "Recording"} · $_persona',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _paused ? t.textMuted : t.textSecondary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExit() async {
    final t = RecapThemeScope.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('Stop and discard?',
            style: RT.subtitle.copyWith(color: t.textPrimary)),
        content: Text(
          'Background recording isn\'t wired yet — closing this screen will discard the current recording. Tap Stop to save it as a meeting first.',
          style: RT.body.copyWith(color: t.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep recording', style: TextStyle(color: t.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Discard', style: TextStyle(color: t.recordRed)),
          ),
        ],
      ),
    );
    if (result == true) await _discard();
  }

  Widget _bookmarkBtn(RecapTheme t) {
    return Material(
      color: _flashBookmark ? t.accentSoft : Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _flashBookmark ? t.accentBorder : t.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: _bookmark,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _flashBookmark ? Icons.bookmark : Icons.bookmark_outline,
                size: 13,
                color: _flashBookmark ? t.accent : t.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _flashBookmark ? 'Saved · ${_fmt(_elapsed)}' : 'Bookmark',
                style: RT.label.copyWith(
                  color: _flashBookmark ? t.accent : t.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
