import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../main.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';
import 'transcript_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Meeting> _results = const [];
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final ids = await db.searchMeetingIds(q);
      if (ids.isEmpty) {
        setState(() => _results = const []);
        return;
      }
      final all = await db.recentMeetings(limit: 1000);
      final byId = {for (final m in all) m.id: m};
      final ordered = ids.map((id) => byId[id]).whereType<Meeting>().toList();
      setState(() => _results = ordered);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  IconBtn(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: t.bgSubtle,
                        border: Border.all(color: t.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 16, color: t.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              style: RT.body.copyWith(color: t.textPrimary),
                              cursorColor: t.accent,
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Search transcripts…',
                                hintStyle: RT.body.copyWith(color: t.textMuted),
                              ),
                              onChanged: _onChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _searching
                  ? LinearProgressIndicator(color: t.accent)
                  : _results.isEmpty
                  ? Center(
                      child: Text(
                        _controller.text.isEmpty
                            ? 'Search across all meetings'
                            : 'No matches',
                        style: RT.body.copyWith(color: t.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _row(t, _results[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(RecapTheme t, Meeting m) {
    return Material(
      color: t.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: t.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TranscriptScreen(meeting: m)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: RT.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d · h:mm a').format(m.createdAt),
                      style: RT.bodySm.copyWith(color: t.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: t.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
