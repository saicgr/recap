import 'package:flutter/material.dart';

import '../main.dart';
import '../services/importers/file_importer.dart';
import '../services/importers/import_pipeline.dart';
import '../services/importers/url_importer.dart';
import '../services/importers/youtube_importer.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';
import 'transcript_screen.dart';

/// One screen, four sources. Tap a source → pipeline runs → user lands on the
/// new meeting's transcript screen, just like a finished recording.
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _busy = false;
  String? _error;
  double _progress = 0;
  String _status = '';

  Future<void> _openMeeting(String meetingId) async {
    final meeting = await db.meetingById(meetingId);
    if (meeting == null || !mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TranscriptScreen(meeting: meeting)),
    );
  }

  Future<void> _runImportFromFile() async {
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Picking file…';
    });
    try {
      final imported = await FileImporter.pickAndConvert();
      if (imported == null) {
        setState(() => _busy = false);
        return;
      }
      setState(() => _status = 'Saving meeting…');
      final id = await persistImportedMeeting(imported);
      if (!mounted) return;
      await _openMeeting(id);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runImportFromUrl() async {
    final url = await _promptUrl(
      title: 'Import from URL',
      hint: 'https://example.com/episode.mp3',
    );
    if (url == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Downloading…';
      _progress = 0;
    });
    try {
      final imported = await UrlImporter.importFromUrl(
        url,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress = p);
        },
      );
      if (imported == null) {
        throw StateError(
          'That URL returned HTML, not a media file. Try a direct .mp3 / .mp4 link.',
        );
      }
      setState(() => _status = 'Saving meeting…');
      final id = await persistImportedMeeting(imported);
      if (!mounted) return;
      await _openMeeting(id);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runImportFromYoutube() async {
    final url = await _promptUrl(
      title: 'Import from YouTube',
      hint: 'https://youtube.com/watch?v=…',
    );
    if (url == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Fetching captions…';
      _progress = 0;
    });
    try {
      final imported = await YoutubeImporter.importByUrl(url);
      setState(() => _status = 'Saving meeting…');
      final id = await persistImportedMeeting(imported);
      if (!mounted) return;
      await _openMeeting(id);
    } on NoCaptionsAvailable catch (e) {
      setState(() => _error = e.toString());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptUrl({
    required String title,
    required String hint,
  }) async {
    final t = RecapThemeScope.of(context);
    final c = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text(title, style: RT.subtitle.copyWith(color: t.textPrimary)),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.textMuted),
          ),
          style: TextStyle(color: t.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (res == null || res.isEmpty) return null;
    return res;
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
                'Import',
                style: RT.subtitle.copyWith(color: t.textPrimary),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    'Recap anything — audio, video, podcasts, YouTube. Everything is transcribed and summarized on-device.',
                    style: RT.body.copyWith(color: t.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  _sourceTile(
                    t,
                    icon: Icons.folder_open,
                    title: 'From file or gallery',
                    subtitle:
                        'Pick an audio or video file from Files / Photos.',
                    onTap: _busy ? null : _runImportFromFile,
                  ),
                  _sourceTile(
                    t,
                    icon: Icons.link,
                    title: 'From URL',
                    subtitle: 'Direct link to .mp3 / .mp4 / .m4a / .opus etc.',
                    onTap: _busy ? null : _runImportFromUrl,
                  ),
                  _sourceTile(
                    t,
                    icon: Icons.smart_display_outlined,
                    title: 'From YouTube',
                    subtitle: 'Captions only — never downloads the video.',
                    onTap: _busy ? null : _runImportFromYoutube,
                  ),
                  const SizedBox(height: 24),
                  if (_busy)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: t.bgSubtle,
                        border: Border.all(color: t.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation(t.accent),
                              value: _progress > 0 ? _progress : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _status,
                              style: RT.bodySm.copyWith(color: t.textPrimary),
                            ),
                          ),
                          if (_progress > 0)
                            Text(
                              '${(_progress * 100).toStringAsFixed(0)}%',
                              style: RT.bodySm.copyWith(color: t.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.bgSubtle,
                        border: Border.all(color: t.recordRed),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: RT.bodySm.copyWith(color: t.recordRed),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceTile(
    RecapTheme t, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: t.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: t.accent, size: 20),
        ),
        title: Text(
          title,
          style: RT.body.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: RT.bodySm.copyWith(color: t.textSecondary),
        ),
        trailing: Icon(Icons.chevron_right, color: t.textMuted),
      ),
    );
  }
}
