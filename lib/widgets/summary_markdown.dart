import 'package:flutter/material.dart';

import '../ui/theme.dart';
import '../ui/type.dart';

/// A lightweight, fluid renderer for a meeting summary — no markdown package,
/// just the small subset the summaries use: `## ` section headers, `### `
/// chapter sub-headers, `- ` bullets, `> ` notes, `**bold**`, and — the delight
/// — tappable `[mm:ss]` citations that seek the audio. Turns a wall of raw text
/// into an interactive, navigable, cited document.
///
/// Public + widget-tested so the "creative UI" is verified, not just compiled.
class SummaryMarkdown extends StatelessWidget {
  final String text;
  final RecapTheme t;

  /// Tapping a `[mm:ss]` citation calls this with the absolute millisecond
  /// offset — wire it to the audio player's seek.
  final void Function(int ms)? onSeekMs;

  const SummaryMarkdown(this.text, this.t, {super.key, this.onSeekMs});

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        blocks.add(const SizedBox(height: 6));
        continue;
      }
      final h2 = RegExp(r'^##\s+(.*)').firstMatch(line);
      final h3 = RegExp(r'^###\s+(.*)').firstMatch(line);
      final quote = RegExp(r'^>\s?(.*)').firstMatch(line);
      final bullet = RegExp(r'^(\s*)[-*]\s+(.*)').firstMatch(line);
      if (h2 != null) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 6),
            child: Text(
              h2.group(1)!,
              style: RT.subtitle.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      } else if (h3 != null) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: Text(
              h3.group(1)!,
              style: RT.body.copyWith(
                color: t.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      } else if (quote != null) {
        blocks.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: t.accentSoft,
              border: Border(left: BorderSide(color: t.accent, width: 3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _rich(quote.group(1)!, muted: true),
          ),
        );
      } else if (bullet != null) {
        final indent = (bullet.group(1)!.length ~/ 2).clamp(0, 3);
        blocks.add(
          Padding(
            padding: EdgeInsets.only(
              left: 4 + indent * 16.0,
              top: 3,
              bottom: 3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: t.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(child: _rich(bullet.group(2)!)),
              ],
            ),
          ),
        );
      } else {
        blocks.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _rich(line),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  Widget _rich(String s, {bool muted = false}) {
    final base = RT.body.copyWith(
      color: muted ? t.textSecondary : t.textPrimary,
      height: 24 / 15,
    );
    final spans = <InlineSpan>[];
    final tok = RegExp(r'\*\*(.+?)\*\*|\[(\d{1,2}):(\d{2})(?::(\d{2}))?\]');
    var i = 0;
    for (final m in tok.allMatches(s)) {
      if (m.start > i) spans.add(TextSpan(text: s.substring(i, m.start)));
      if (m.group(1) != null) {
        spans.add(
          TextSpan(
            text: m.group(1),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else {
        final hasH = m.group(4) != null;
        final h = hasH ? int.parse(m.group(2)!) : 0;
        final mm = hasH ? int.parse(m.group(3)!) : int.parse(m.group(2)!);
        final ss = hasH ? int.parse(m.group(4)!) : int.parse(m.group(3)!);
        final ms = ((h * 3600) + (mm * 60) + ss) * 1000;
        final label = m.group(0)!;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _TsChip(
              label: label.substring(1, label.length - 1),
              t: t,
              onTap: onSeekMs == null ? null : () => onSeekMs!(ms),
            ),
          ),
        );
      }
      i = m.end;
    }
    if (i < s.length) spans.add(TextSpan(text: s.substring(i)));
    return SelectableText.rich(TextSpan(style: base, children: spans));
  }
}

/// The tappable `[mm:ss]` citation chip — jumps the audio to that moment.
class _TsChip extends StatelessWidget {
  final String label;
  final RecapTheme t;
  final VoidCallback? onTap;
  const _TsChip({required this.label, required this.t, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: t.accentSoft,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 12, color: t.accent),
                Text(
                  label,
                  style: RT.bodySm.copyWith(color: t.accent, height: 1.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
