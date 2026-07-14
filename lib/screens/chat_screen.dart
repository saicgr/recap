import 'package:flutter/material.dart';

import '../main.dart';
import '../services/rag/chat_service.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';
import 'transcript_screen.dart';

class _Turn {
  _Turn.user(this.text)
      : isUser = true,
        answer = null;
  _Turn.assistant(this.answer)
      : isUser = false,
        text = answer!.text;

  final bool isUser;
  final String text;
  final ChatAnswer? answer;
}

/// "Ask your notes anything", over the local corpus.
///
/// Runs entirely on-device: free, offline, and available on the Privacy tier —
/// Granola's chat is cloud-only, so a Privacy-minded user cannot have it there.
///
/// [meetingId] scopes the chat to a single recording; null asks the whole corpus.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.meetingId, this.meetingTitle});

  final String? meetingId;
  final String? meetingTitle;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Turn> _turns = [];
  bool _thinking = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final q = _controller.text.trim();
    if (q.isEmpty || _thinking) return;
    _controller.clear();
    setState(() {
      _turns.add(_Turn.user(q));
      _thinking = true;
      _error = null;
    });
    _jumpToEnd();

    try {
      final answer = await chatService.ask(q, meetingId: widget.meetingId);
      if (!mounted) return;
      setState(() => _turns.add(_Turn.assistant(answer)));
    } catch (e) {
      // No on-device model installed, etc. Surfaced, never silently swallowed
      // into an empty answer.
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _thinking = false);
      _jumpToEnd();
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Open the cited meeting at the cited moment. transcript_screen already does
  /// tap-to-seek, so a citation only needs (meetingId, startMs).
  Future<void> _openCitation(ChatCitation c) async {
    final meeting = await (db.select(db.meetings)
          ..where((m) => m.id.equals(c.meetingId)))
        .getSingleOrNull();
    if (meeting == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TranscriptScreen(meeting: meeting),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
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
              title: Text(
                widget.meetingTitle ?? 'Ask your notes',
                overflow: TextOverflow.ellipsis,
                style: RT.subtitle.copyWith(color: t.textPrimary),
              ),
            ),
            Expanded(
              child: _turns.isEmpty && _error == null
                  ? _empty(t)
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        for (final turn in _turns) _bubble(t, turn),
                        if (_thinking) _thinkingRow(t),
                        if (_error != null) _errorCard(t),
                      ],
                    ),
            ),
            _composer(t),
          ],
        ),
      ),
    );
  }

  Widget _empty(RecapTheme t) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_outlined, size: 40, color: t.textMuted),
              const SizedBox(height: 16),
              Text(
                widget.meetingId == null
                    ? 'Ask anything about your recordings'
                    : 'Ask about this recording',
                textAlign: TextAlign.center,
                style: RT.subtitle.copyWith(color: t.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                '"What did we decide about pricing?"\n'
                '"Who owns the migration?"\n\n'
                'Answers run on your device and cite the exact moment they came '
                'from.',
                textAlign: TextAlign.center,
                style: RT.bodySm.copyWith(color: t.textMuted),
              ),
            ],
          ),
        ),
      );

  Widget _bubble(RecapTheme t, _Turn turn) {
    if (turn.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: t.accentSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.accentBorder),
          ),
          child: Text(turn.text, style: RT.body.copyWith(color: t.accent)),
        ),
      );
    }

    final citations = turn.answer?.citations ?? const <ChatCitation>[];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(turn.text, style: RT.body.copyWith(color: t.textPrimary)),
          if (citations.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Only the excerpts the model actually cited. Listing everything
            // retrieved would be noise dressed up as rigour.
            for (final c in citations)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SurfaceCard(
                  onTap: () => _openCitation(c),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('[${c.index}]',
                          style: RT.caption.copyWith(
                              color: t.accent, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.meetingTitle,
                              overflow: TextOverflow.ellipsis,
                              style: RT.caption.copyWith(
                                  color: t.textMuted,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.quote,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  RT.bodySm.copyWith(color: t.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: t.textMuted),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _thinkingRow(RecapTheme t) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
            ),
            const SizedBox(width: 10),
            Text('Reading your recordings…',
                style: RT.bodySm.copyWith(color: t.textMuted)),
          ],
        ),
      );

  Widget _errorCard(RecapTheme t) => SurfaceCard(
        child: Text(_error!, style: RT.bodySm.copyWith(color: t.textPrimary)),
      );

  Widget _composer(RecapTheme t) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border(top: BorderSide(color: t.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: RT.body.copyWith(color: t.textPrimary),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ask a question…',
                  hintStyle: RT.body.copyWith(color: t.textMuted),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
              ),
            ),
            IconBtn(icon: Icons.arrow_upward, onPressed: _send),
          ],
        ),
      );
}
