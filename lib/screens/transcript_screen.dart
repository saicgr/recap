import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../billing/persona.dart';
import '../billing/tier.dart';
import '../data/database.dart';
import '../main.dart';
import '../services/audio_player_service.dart';
import '../services/custom_personas_service.dart';
import '../services/summarizer/gemma_downloader.dart';
import '../services/summarizer/summary_router.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';
import 'paywall_screen.dart';
import 'settings_screen.dart';
import 'topup_screen.dart';

class TranscriptScreen extends StatefulWidget {
  final Meeting meeting;
  const TranscriptScreen({super.key, required this.meeting});

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  String _tab = 'summary';
  Transcript? _transcript;
  List<Summary> _summaries = const [];
  List<Bookmark> _bookmarks = const [];
  List<TranscriptSegment> _segments = const [];
  bool _summarizing = false;
  String? _error;
  // settings.defaultPersonaKey has existed with zero readers; this screen just
  // hardcoded 'basic', so setting a default persona did nothing.
  late String _personaKey = settings.defaultPersonaKey;
  late String _title = widget.meeting.title;

  /// Per-summary translation state, keyed by summary.id.
  /// Target language null = showing original. Cached translation string =
  /// the translated body that toggles in place of the original.
  final Map<String, _SummaryTranslation> _summaryTranslations = {};
  bool _translating = false;

  final AudioPlayerService _audio = AudioPlayerService();

  @override
  void initState() {
    super.initState();
    _audio.addListener(_onAudio);
    _audio.loadFile(widget.meeting.audioPath);
    _load();
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudio);
    _audio.dispose();
    super.dispose();
  }

  void _onAudio() {
    if (mounted) setState(() {});
  }

  /// Find the segment whose [startMs, endMs] contains the current playhead.
  TranscriptSegment? get _activeSegment {
    if (_segments.isEmpty) return null;
    final ms = _audio.position.inMilliseconds;
    for (final s in _segments) {
      if (ms >= s.startMs && ms < s.endMs) return s;
    }
    return null;
  }

  Future<void> _load() async {
    final tr = await db.transcriptFor(widget.meeting.id);
    final s = await db.summariesFor(widget.meeting.id);
    final b = await db.bookmarksFor(widget.meeting.id);
    final segs = await db.segmentsFor(widget.meeting.id);
    if (!mounted) return;
    setState(() {
      _transcript = tr;
      _summaries = s;
      _bookmarks = b;
      _segments = segs;
    });
  }

  Future<void> _summarize() async {
    if (_transcript == null) return;
    final persona = _resolvePersona(_personaKey);
    setState(() {
      _summarizing = true;
      _error = null;
    });
    try {
      final res = await summaryRouter.summarize(
        transcript: _transcript!.body,
        persona: persona,
        requested: settings.summaryMode,
      );
      switch (res) {
        case SummaryReady(:final result, :final route):
          await db.into(db.summaries).insert(SummariesCompanion.insert(
                id: const Uuid().v4(),
                meetingId: widget.meeting.id,
                personaKey: persona.key,
                body: result.text,
                backend: switch (route) {
                  SummaryRoute.appleFoundationModels =>
                    SummaryBackendKind.appleFoundationModels,
                  SummaryRoute.gemma => SummaryBackendKind.gemma,
                  SummaryRoute.cloud => SummaryBackendKind.cloud,
                  SummaryRoute.byok => SummaryBackendKind.byok,
                  SummaryRoute.ollama => SummaryBackendKind.ollama,
                },
                modelId: result.modelId,
                processingMs: Value(result.processingTime.inMilliseconds),
                createdAt: DateTime.now(),
              ));
          await _load();
        case SummaryNeedsGemmaDownload():
          setState(() => _error = '__needs_model__');
        case SummaryBlockedByQuota():
          if (!mounted) return;
          await _showQuotaSheet();
        case SummaryFailed(:final error):
          setState(() => _error = error.toString());
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _summarizing = false);
    }
  }

  Persona _resolvePersona(String key) =>
      resolvePersona(key, customPersonas.personas);

  /// Translate the given summary to [targetLocale]. If a translation is
  /// already cached for that target, this is a no-op visually. Tap again
  /// (handled by the caller) reverts to the original by clearing the entry.
  Future<void> _translateSummary(Summary summary, String targetLocale) async {
    setState(() => _translating = true);
    try {
      // Route through the tier-aware translator chain. The chain is
      // ordered: prefer offline engines, fall through to cloud only when
      // the user has opted in (non-Privacy + summaryMode != onDevice).
      for (final t in translatorChain) {
        if (await t.isAvailable(from: 'auto', to: targetLocale)) {
          final res = await t.translate(
            summary.body,
            from: 'auto',
            to: targetLocale,
          );
          _summaryTranslations[summary.id] = _SummaryTranslation(
            targetLocale: targetLocale,
            translatedBody: res.translated,
            engineId: res.engineId,
          );
          break;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  void _clearTranslation(Summary summary) {
    setState(() => _summaryTranslations.remove(summary.id));
  }

  /// Bottom-sheet language picker, returns the locale code or null on cancel.
  Future<String?> _pickTargetLocale(BuildContext context) {
    final t = RecapThemeScope.of(context);
    // 36 locales from the i18n plan — keeping the picker simple + scrollable.
    const locales = <(String, String)>[
      ('en', 'English'),
      ('ar', 'العربية · Arabic'),
      ('bn', 'বাংলা · Bengali'),
      ('cs', 'Čeština · Czech'),
      ('de', 'Deutsch · German'),
      ('es', 'Español · Spanish'),
      ('fi', 'Suomi · Finnish'),
      ('fr', 'Français · French'),
      ('ha', 'Hausa'),
      ('hi', 'हिन्दी · Hindi'),
      ('id', 'Bahasa Indonesia · Indonesian'),
      ('it', 'Italiano · Italian'),
      ('ja', '日本語 · Japanese'),
      ('jv', 'Basa Jawa · Javanese'),
      ('kn', 'ಕನ್ನಡ · Kannada'),
      ('ko', '한국어 · Korean'),
      ('ml', 'മലയാളം · Malayalam'),
      ('mr', 'मराठी · Marathi'),
      ('ms', 'Bahasa Melayu · Malay'),
      ('ne', 'नेपाली · Nepali'),
      ('nl', 'Nederlands · Dutch'),
      ('or', 'ଓଡ଼ିଆ · Odia'),
      ('pa', 'ਪੰਜਾਬੀ · Punjabi'),
      ('pl', 'Polski · Polish'),
      ('pt', 'Português · Portuguese'),
      ('ru', 'Русский · Russian'),
      ('sv', 'Svenska · Swedish'),
      ('sw', 'Kiswahili · Swahili'),
      ('ta', 'தமிழ் · Tamil'),
      ('te', 'తెలుగు · Telugu'),
      ('th', 'ไทย · Thai'),
      ('tl', 'Tagalog · Filipino'),
      ('tr', 'Türkçe · Turkish'),
      ('ur', 'اردو · Urdu'),
      ('vi', 'Tiếng Việt · Vietnamese'),
      ('zh', '简体中文 · Chinese'),
    ];
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Translate summary to…',
                    style: RT.subtitle.copyWith(color: t.textPrimary)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: locales.length,
                  itemBuilder: (_, i) {
                    final (code, label) = locales[i];
                    return ListTile(
                      dense: true,
                      onTap: () => Navigator.pop(ctx, code),
                      title: Text(label,
                          style: TextStyle(color: t.textPrimary)),
                      trailing: Text(code,
                          style: RT.caption.copyWith(color: t.textMuted)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rename(Meeting m) async {
    final t = RecapThemeScope.of(context);
    final controller = TextEditingController(text: m.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('Rename meeting',
            style: RT.subtitle.copyWith(color: t.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          cursorColor: t.accent,
          style: RT.body.copyWith(color: t.textPrimary),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: t.border)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: t.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: t.textMuted)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child:
                Text('Save', style: TextStyle(color: t.accent)),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty && newTitle != _title) {
      await (db.update(db.meetings)..where((t) => t.id.equals(m.id))).write(
        MeetingsCompanion(
          title: Value(newTitle),
          updatedAt: Value(DateTime.now()),
        ),
      );
      if (!mounted) return;
      setState(() => _title = newTitle);
    }
  }

  Future<void> _pickPersona() async {
    final t = RecapThemeScope.of(context);
    final tier = entitlements.currentTier;
    final allowed = tier.personaTemplates;
    final available =
        personas.where((p) => allowed.contains(p.style)).toList();
    final customs = CustomPersonasService.isAvailableFor(tier)
        ? customPersonas.personas
        : const <Persona>[];
    final pick = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PersonaSheet(
        available: available,
        customs: customs,
        selectedKey: _personaKey,
        lockedCount: personas.length - available.length,
        canAddCustom: CustomPersonasService.isAvailableFor(tier),
      ),
    );
    if (pick != null) {
      setState(() => _personaKey = pick);
      _summarize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    final m = widget.meeting;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              leading: IconBtn(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.pop(context),
              ),
              title: GestureDetector(
                onTap: () => _rename(m),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _title,
                        overflow: TextOverflow.ellipsis,
                        style:
                            RT.subtitle.copyWith(color: t.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_outlined,
                        size: 14, color: t.textMuted),
                  ],
                ),
              ),
              trailing: [
                IconBtn(icon: Icons.ios_share, onPressed: () {}),
                const SizedBox(width: 4),
                IconBtn(icon: Icons.more_horiz, onPressed: () {}),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text(DateFormat('MMM d · h:mm a').format(m.createdAt),
                      style: RT.bodySm.copyWith(color: t.textMuted)),
                  Text('  ·  ',
                      style: RT.bodySm.copyWith(color: t.textMuted)),
                  Text(_formatDuration(m.durationMs),
                      style: RT.bodySm
                          .copyWith(color: t.textMuted)
                          .merge(RT.num)),
                ],
              ),
            ),
            TabsBar(
              items: [
                const TabItem(label: 'Transcript', value: 'transcript'),
                const TabItem(label: 'Summary', value: 'summary'),
                TabItem(
                    label: 'Bookmarks',
                    value: 'bookmarks',
                    count:
                        _bookmarks.isEmpty ? null : _bookmarks.length),
              ],
              value: _tab,
              onChanged: (v) => setState(() => _tab = v),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, _audio.hasSource ? 96 : 32),
                child: switch (_tab) {
                  'summary' => _summaryTab(t),
                  'bookmarks' => _bookmarksTab(t),
                  _ => _transcriptTab(t, m),
                },
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _audio.hasSource ? _miniPlayer(t) : null,
    );
  }

  Widget _miniPlayer(RecapTheme t) {
    final dur = _audio.duration.inMilliseconds.toDouble();
    final pos = _audio.position.inMilliseconds
        .clamp(0, dur > 0 ? dur.toInt() : 0)
        .toDouble();
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _audio.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 36,
              color: t.accent,
            ),
            onPressed: _audio.togglePlayPause,
            tooltip: _audio.isPlaying ? 'Pause' : 'Play',
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: t.accent,
                    inactiveTrackColor: t.border,
                    thumbColor: t.accent,
                    overlayColor: t.accent.withValues(alpha: 0.15),
                    trackHeight: 2.5,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: dur > 0 ? pos : 0,
                    max: dur > 0 ? dur : 1,
                    onChanged: (v) =>
                        _audio.seekMs(v.round()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmtMs(_audio.position.inMilliseconds),
                          style: RT.caption
                              .copyWith(color: t.textMuted)
                              .merge(RT.num)),
                      Text(_fmtMs(_audio.duration.inMilliseconds),
                          style: RT.caption
                              .copyWith(color: t.textMuted)
                              .merge(RT.num)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _audio.cycleSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: t.bgSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.border),
              ),
              child: Text(
                '${_audio.speed.toStringAsFixed(_audio.speed == _audio.speed.truncate() ? 0 : 1)}x',
                style: RT.caption.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transcriptTab(RecapTheme t, Meeting m) {
    if (m.status == MeetingStatus.processing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(children: [
            CircularProgressIndicator(color: t.accent),
            const SizedBox(height: 12),
            Text('Transcribing on-device…',
                style: RT.body.copyWith(color: t.textMuted)),
          ]),
        ),
      );
    }
    if (m.status == MeetingStatus.failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Transcription failed: ${m.failureReason ?? 'unknown'}',
          style: RT.body.copyWith(color: t.recordRed),
        ),
      );
    }
    // If we have segments (with or without speaker labels), render them as
    // tap-to-seek tiles. If labels are present, also group by speaker.
    if (_segments.isEmpty) {
      // Fall back to plain body when segmentation wasn't persisted.
      if (_audio.hasSource) {
        // Still allow tap on the whole block to seek to 0.
        return GestureDetector(
          onTap: () {
            _audio.seekMs(0);
            _audio.play();
          },
          child: SelectableText(
            _transcript?.body ?? '(empty)',
            style: RT.bodyLg
                .copyWith(color: t.textPrimary, height: 26 / 16),
          ),
        );
      }
      return SelectableText(
        _transcript?.body ?? '(empty)',
        style: RT.bodyLg.copyWith(color: t.textPrimary, height: 26 / 16),
      );
    }
    final hasSpeakers = _segments.any((s) => s.speakerLabel != null);
    final groups = hasSpeakers
        ? _groupBySpeaker(_segments)
        : [
            _SpeakerGroup(
              speaker: '',
              startMs: _segments.first.startMs,
              segments: _segments,
            ),
          ];
    final activeId = _activeSegment?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          if (group.speaker.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(group.speaker,
                      style: RT.subtitle.copyWith(
                          color: _speakerColor(t, group.speaker),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text(_fmtMs(group.startMs),
                      style: RT.bodySm
                          .copyWith(color: t.textMuted)
                          .merge(RT.num)),
                ],
              ),
            ),
          for (final seg in group.segments)
            _SegmentTile(
              key: ValueKey(seg.id),
              theme: t,
              seg: seg,
              active: seg.id == activeId,
              onTap: () {
                _audio.seekMs(seg.startMs);
                if (!_audio.isPlaying) _audio.play();
              },
            ),
        ],
      ],
    );
  }

  /// Group consecutive segments sharing the same speaker label into a single
  /// block. Each group keeps the underlying segments so the UI can render
  /// per-segment tap-to-seek widgets while still showing one speaker header.
  List<_SpeakerGroup> _groupBySpeaker(List<TranscriptSegment> segs) {
    if (segs.isEmpty) return const [];
    final out = <_SpeakerGroup>[];
    var currentSpeaker = segs.first.speakerLabel ?? '';
    var currentStart = segs.first.startMs;
    var bucket = <TranscriptSegment>[];
    for (final s in segs) {
      final lbl = s.speakerLabel ?? '';
      if (lbl == currentSpeaker) {
        bucket.add(s);
      } else {
        out.add(_SpeakerGroup(
          speaker: currentSpeaker,
          startMs: currentStart,
          segments: List.unmodifiable(bucket),
        ));
        currentSpeaker = lbl;
        currentStart = s.startMs;
        bucket = [s];
      }
    }
    if (bucket.isNotEmpty) {
      out.add(_SpeakerGroup(
        speaker: currentSpeaker,
        startMs: currentStart,
        segments: List.unmodifiable(bucket),
      ));
    }
    return out;
  }

  Color _speakerColor(RecapTheme t, String speaker) {
    // Cycle through accent + positive + warn so different speakers are
    // visually distinct without inventing new tokens.
    final n = int.tryParse(speaker.split(' ').last) ?? 1;
    return [t.accent, t.positive, t.warn][((n - 1) % 3)];
  }

  Widget _summaryTab(RecapTheme t) {
    if (_summaries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _personaBar(t),
            const SizedBox(height: 28),
            if (_summarizing)
              Row(children: [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation(t.accent))),
                const SizedBox(width: 10),
                Text('Generating…',
                    style: RT.body.copyWith(color: t.textMuted)),
              ])
            else
              Center(
                child: Column(children: [
                  Icon(Icons.auto_awesome,
                      size: 36, color: t.textMuted),
                  const SizedBox(height: 12),
                  Text('No summary yet',
                      style: RT.subtitle.copyWith(color: t.textPrimary)),
                  const SizedBox(height: 6),
                  Text(
                      'Pick a style above and tap Generate.',
                      style: RT.body.copyWith(color: t.textMuted)),
                ]),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _errorBlock(t, _error!),
            ],
          ],
        ),
      );
    }
    final latest = _summaries.first;
    final translation = _summaryTranslations[latest.id];
    final isTranslated = translation != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _personaBar(t),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                // _resolvePersona, not personasByKey: the latter holds only the
                // 7 built-ins, so a summary generated with a custom template
                // rendered its raw key here — literally "OVERVIEW · custom:1752438…".
                'OVERVIEW · ${_resolvePersona(latest.personaKey).displayName}',
                style: RT.caption.copyWith(color: t.textMuted),
              ),
            ),
            _TranslateToggle(
              theme: t,
              isTranslated: isTranslated,
              translation: translation,
              translating: _translating,
              onPickLanguage: () async {
                final code = await _pickTargetLocale(context);
                if (code != null) await _translateSummary(latest, code);
              },
              onRevert: () => _clearTranslation(latest),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SelectableText(
          isTranslated ? translation.translatedBody : latest.body,
          style: RT.bodyLg.copyWith(color: t.textPrimary, height: 26 / 16),
        ),
        const SizedBox(height: 14),
        Text(
          isTranslated
              ? 'Translated to ${translation.targetLocale.toUpperCase()} via ${translation.engineId} · original by ${_backendLabel(latest.backend)} · ${latest.modelId}'
              : 'Generated by ${_backendLabel(latest.backend)} · ${latest.modelId}',
          style: RT.bodySm.copyWith(color: t.textMuted),
        ),
      ],
    );
  }

  Widget _personaBar(RecapTheme t) {
    // _resolvePersona, not personasByKey: with a custom template selected the
    // lookup missed and the chip fell back to the label "Meeting notes" — it
    // told the user they had picked a persona they had not picked.
    final persona = _resolvePersona(_personaKey);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Material(
          color: t.accentSoft,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: t.accentBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: _pickPersona,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 13, color: t.accent),
                  const SizedBox(width: 6),
                  Text(persona.displayName,
                      style: RT.label.copyWith(
                          color: t.accent, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down,
                      size: 13, color: t.accent),
                ],
              ),
            ),
          ),
        ),
        TextButton.icon(
          icon: Icon(Icons.add, size: 13, color: t.textSecondary),
          label: Text('New summary',
              style: RT.label.copyWith(
                color: t.textSecondary,
                fontWeight: FontWeight.w600,
              )),
          onPressed: _summarizing ? null : _summarize,
        ),
      ],
    );
  }

  Future<void> _showQuotaSheet() async {
    final t = RecapThemeScope.of(context);
    final tier = entitlements.currentTier;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cloud summary quota exhausted',
                  style: RT.title.copyWith(color: t.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Buy a top-up to keep using cloud summaries this month, or upgrade your tier for a bigger monthly allowance.',
                style: RT.body
                    .copyWith(color: t.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 18),
              if (tier.topUpsEnabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Btn(
                    label: 'Buy top-up · from \$2.99',
                    variant: BtnVariant.primary,
                    full: true,
                    size: BtnSize.lg,
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TopUpScreen()),
                      );
                    },
                  ),
                ),
              Btn(
                label: 'Upgrade tier',
                variant: BtnVariant.accentSoft,
                full: true,
                size: BtnSize.lg,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaywallScreen(
                        reason: 'Cloud summary quota exhausted.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Switch to on-device in Settings instead',
                    style: TextStyle(color: t.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBlock(RecapTheme t, String error) {
    if (error == '__needs_model__') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.bgSubtle,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('On-device AI not installed',
                style: RT.subtitle.copyWith(color: t.textPrimary)),
            const SizedBox(height: 6),
            Text(
              'The ${entitlements.currentTier.gemmaVariant.displayName} summary model (~${(entitlements.currentTier.gemmaVariant.approxBytes / 1e9).toStringAsFixed(1)} GB) hasn\'t been downloaded yet. Wi-Fi recommended.',
              style: RT.bodySm.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: gemmaDownloader,
              builder: (_, __) {
                final s = gemmaDownloader.status;
                if (s == GemmaDownloadStatus.downloading) {
                  final pct = (gemmaDownloader.progress * 100)
                      .toStringAsFixed(0);
                  return Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation(t.accent),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Downloading · $pct%',
                          style: RT.bodySm.copyWith(color: t.textSecondary)),
                    ],
                  );
                }
                if (s == GemmaDownloadStatus.installed) {
                  return Text(
                    'Model installed. Pick a style and tap Generate.',
                    style: RT.bodySm.copyWith(color: t.textSecondary),
                  );
                }
                return Row(
                  children: [
                    Btn(
                      label: s == GemmaDownloadStatus.failed
                          ? 'Retry download'
                          : 'Download model',
                      variant: BtnVariant.accentSoft,
                      size: BtnSize.sm,
                      trailing: Icons.download,
                      onPressed: () => gemmaDownloader.warmUp(),
                    ),
                    const SizedBox(width: 8),
                    Btn(
                      label: 'Settings',
                      variant: BtnVariant.ghost,
                      size: BtnSize.sm,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (gemmaDownloader.failureReason != null) ...[
              const SizedBox(height: 8),
              Text(
                gemmaDownloader.failureReason!,
                style: RT.caption.copyWith(color: t.recordRed),
              ),
            ],
          ],
        ),
      );
    }
    return Text(error, style: RT.body.copyWith(color: t.recordRed));
  }

  Widget _bookmarksTab(RecapTheme t) {
    if (_bookmarks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('No bookmarks',
              style: RT.body.copyWith(color: t.textMuted)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < _bookmarks.length; i++)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: i == _bookmarks.length - 1
                      ? BorderSide.none
                      : BorderSide(color: t.divider),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bookmark, size: 16, color: t.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fmtMs(_bookmarks[i].atMs),
                          style: RT.bodySm
                              .copyWith(color: t.textMuted)
                              .merge(RT.num),
                        ),
                        if (_bookmarks[i].note != null) ...[
                          const SizedBox(height: 4),
                          Text(_bookmarks[i].note!,
                              style: RT.body
                                  .copyWith(color: t.textPrimary)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _backendLabel(SummaryBackendKind k) => switch (k) {
        SummaryBackendKind.appleFoundationModels => 'Apple Foundation Models',
        SummaryBackendKind.gemma => 'Gemma 4 (on-device)',
        SummaryBackendKind.cloud => 'Gemini Flash Lite (cloud)',
        SummaryBackendKind.byok => 'BYOK',
        SummaryBackendKind.ollama => 'Ollama (desktop)',
      };

  String _formatDuration(int ms) {
    final s = ms ~/ 1000;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final ss = s % 60;
    return h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}'
        : '$m:${ss.toString().padLeft(2, '0')}';
  }

  String _fmtMs(int ms) => _formatDuration(ms);
}

class _PersonaSheet extends StatefulWidget {
  final List<Persona> available;
  final List<Persona> customs;
  final String selectedKey;
  final int lockedCount;
  final bool canAddCustom;
  const _PersonaSheet({
    required this.available,
    required this.customs,
    required this.selectedKey,
    required this.lockedCount,
    required this.canAddCustom,
  });

  @override
  State<_PersonaSheet> createState() => _PersonaSheetState();
}

class _PersonaSheetState extends State<_PersonaSheet> {
  late String _selected = widget.selectedKey;

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.fromLTRB(0, 10, 0, 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: t.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Generate summary',
                    style: RT.subtitle.copyWith(color: t.textPrimary)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: RT.label.copyWith(
                          color: t.textSecondary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: t.divider),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              children: [
                for (final p in widget.available)
                  _personaCard(t, p,
                      selected: _selected == p.key,
                      onTap: () =>
                          setState(() => _selected = p.key)),
                if (widget.customs.isNotEmpty) ...[
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Text('CUSTOM',
                        style:
                            RT.caption.copyWith(color: t.textMuted)),
                  ),
                  for (final p in widget.customs)
                    _personaCard(t, p,
                        selected: _selected == p.key,
                        custom: true,
                        onTap: () =>
                            setState(() => _selected = p.key)),
                ],
                if (widget.canAddCustom)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                    child: Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: t.border, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final created = await _newCustom(context);
                          if (created != null) {
                            setState(() => _selected = created);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          child: Row(
                            children: [
                              Icon(Icons.add,
                                  size: 18, color: t.accent),
                              const SizedBox(width: 10),
                              Text('Add custom persona',
                                  style: RT.body.copyWith(
                                      color: t.accent,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.lockedCount > 0)
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: t.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline,
                            size: 16, color: t.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${widget.lockedCount} more styles with Pro',
                            style: RT.body.copyWith(color: t.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Btn(
              label: 'Generate',
              variant: BtnVariant.primary,
              size: BtnSize.lg,
              leading: Icons.auto_awesome,
              full: true,
              onPressed: () => Navigator.pop(context, _selected),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _newCustom(BuildContext context) async {
    final t = RecapThemeScope.of(context);
    final name = TextEditingController();
    final prompt = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('Custom persona',
            style: RT.subtitle.copyWith(color: t.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                cursorColor: t.accent,
                style: RT.body.copyWith(color: t.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: t.textMuted),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: t.border)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: t.accent)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: prompt,
                cursorColor: t.accent,
                style: RT.body.copyWith(color: t.textPrimary),
                maxLines: 6,
                minLines: 4,
                decoration: InputDecoration(
                  labelText: 'Prompt — how should we structure the summary?',
                  labelStyle: TextStyle(color: t.textMuted),
                  alignLabelWithHint: true,
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: t.border)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: t.accent)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancel', style: TextStyle(color: t.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Save', style: TextStyle(color: t.accent)),
          ),
        ],
      ),
    );
    if (ok != true) return null;
    if (name.text.trim().isEmpty || prompt.text.trim().isEmpty) return null;
    await customPersonas.add(name: name.text.trim(), prompt: prompt.text.trim());
    final created = customPersonas.personas.last;
    return created.key;
  }

  Widget _personaCard(RecapTheme t, Persona p,
      {required bool selected,
      required VoidCallback onTap,
      bool custom = false}) {
    return Material(
      color: selected ? t.accentSoft : Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: selected ? t.accentBorder : Colors.transparent),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? t.accent : t.bgSubtle,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(p.emoji,
                    style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.displayName,
                        style: RT.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary)),
                    const SizedBox(height: 2),
                    Text(_personaDesc(p.style),
                        style:
                            RT.bodySm.copyWith(color: t.textMuted)),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? t.accent : Colors.transparent,
                  border: Border.all(
                      color: selected ? t.accent : t.border, width: 1.5),
                ),
                child: selected
                    ? const Icon(Icons.check,
                        size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _personaDesc(SummaryStyle s) => switch (s) {
        SummaryStyle.basic => 'Overview, decisions, action items.',
        SummaryStyle.oneOnOne => 'Topics discussed, follow-ups, feedback.',
        SummaryStyle.standup => 'Per-person updates and blockers.',
        SummaryStyle.salesCall => 'BANT, objections, next steps.',
        SummaryStyle.interview => 'Signal by competency, hire/no-hire notes.',
        SummaryStyle.lecture => 'Outline, key terms, study questions.',
        SummaryStyle.doctorVisit =>
          'Symptoms, instructions, prescriptions.',
      };
}

class _SpeakerGroup {
  final String speaker;
  final int startMs;
  final List<TranscriptSegment> segments;
  _SpeakerGroup({
    required this.speaker,
    required this.startMs,
    required this.segments,
  });
}

/// One tappable transcript segment. Tap → seek + play. The active segment
/// (containing the current playhead) gets an accent background.
class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    super.key,
    required this.theme,
    required this.seg,
    required this.active,
    required this.onTap,
  });

  final RecapTheme theme;
  final TranscriptSegment seg;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? t.accent.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: active
              ? Border.all(color: t.accent.withValues(alpha: 0.35), width: 1)
              : null,
        ),
        child: Text(
          seg.body,
          style: RT.bodyLg.copyWith(
            color: t.textPrimary,
            height: 26 / 16,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// In-memory translation state for one rendered summary. Translations are
/// session-scoped — toggling off discards the cached translation. Users who
/// want to keep a translated version can re-generate the summary via the
/// persona picker with a different "Summary language" choice (persisted
/// path) instead of using this toggle (ephemeral path).
class _SummaryTranslation {
  final String targetLocale;
  final String translatedBody;
  final String engineId;
  const _SummaryTranslation({
    required this.targetLocale,
    required this.translatedBody,
    required this.engineId,
  });
}

/// Compact pill button that toggles a summary between its original language
/// and a translation. Tapping when not translated opens the language picker;
/// tapping when translated reverts to the original. Long-press not used —
/// to switch *target* language, revert first then re-tap. Keeps the UI
/// state machine simple: 2 states, 1 button.
class _TranslateToggle extends StatelessWidget {
  const _TranslateToggle({
    required this.theme,
    required this.isTranslated,
    required this.translation,
    required this.translating,
    required this.onPickLanguage,
    required this.onRevert,
  });

  final RecapTheme theme;
  final bool isTranslated;
  final _SummaryTranslation? translation;
  final bool translating;
  final VoidCallback onPickLanguage;
  final VoidCallback onRevert;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final label = translating
        ? 'Translating…'
        : isTranslated
            ? 'Show original'
            : 'Translate';
    return Material(
      color: isTranslated ? t.accentSoft : Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: isTranslated ? t.accentBorder : t.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: translating
            ? null
            : isTranslated
                ? onRevert
                : onPickLanguage,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (translating)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(t.accent),
                  ),
                )
              else
                Icon(
                  isTranslated
                      ? Icons.translate
                      : Icons.translate_outlined,
                  size: 13,
                  color: isTranslated ? t.accent : t.textMuted,
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: RT.label.copyWith(
                  color: isTranslated ? t.accent : t.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isTranslated && translation != null) ...[
                const SizedBox(width: 6),
                Text(
                  translation!.targetLocale.toUpperCase(),
                  style: RT.caption.copyWith(
                    color: t.accent,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
