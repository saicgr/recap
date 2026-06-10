import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../services/voiceprint_service.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

/// Voice enrollment / voice ID screen (D14.4). Lists enrolled voiceprints,
/// lets the user delete or re-enroll. Recording the 30s reference clip is
/// delegated to the RecordingScreen with a special "enrollment mode" flag —
/// extracting the WeSpeaker embedding then handing back to enroll().
class VoiceEnrollmentScreen extends StatefulWidget {
  const VoiceEnrollmentScreen({super.key});

  @override
  State<VoiceEnrollmentScreen> createState() => _VoiceEnrollmentScreenState();
}

class _VoiceEnrollmentScreenState extends State<VoiceEnrollmentScreen> {
  List<Voiceprint> _list = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final list = await voiceprints.all();
    if (!mounted) return;
    setState(() => _list = list);
  }

  Future<void> _addStub() async {
    // TODO: open recording screen in enrollment mode → produce embedding via
    // SherpaDiarizer's embedding extractor → call enroll(). For now we add
    // a deterministic-zero embedding entry so the list UI can be exercised
    // end-to-end during dev.
    final controller = TextEditingController();
    final t = RecapThemeScope.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('Enroll a voice',
            style: RT.subtitle.copyWith(color: t.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name (e.g. Sarah)'),
          style: TextStyle(color: t.textPrimary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Enroll'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await voiceprints.enroll(
      name: name,
      embedding: Float32List(256), // placeholder until real extraction lands
    );
    await _refresh();
  }

  Future<void> _delete(Voiceprint vp) async {
    await voiceprints.delete(vp.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Scaffold(
      backgroundColor: t.bgSubtle,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              leading: IconBtn(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('Voice enrollment',
                  style: RT.subtitle.copyWith(color: t.textPrimary)),
              trailing: [
                IconBtn(icon: Icons.add, onPressed: _addStub),
              ],
            ),
            Expanded(
              child: _list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.record_voice_over_outlined,
                                size: 48, color: t.textMuted),
                            const SizedBox(height: 16),
                            Text('No voices enrolled yet',
                                style: RT.subtitle
                                    .copyWith(color: t.textPrimary)),
                            const SizedBox(height: 8),
                            Text(
                              'Enroll a 30s reference clip of each known speaker. We\'ll auto-label them in future meetings.',
                              textAlign: TextAlign.center,
                              style: RT.bodySm
                                  .copyWith(color: t.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _list.length,
                      itemBuilder: (_, i) => _row(t, _list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(RecapTheme t, Voiceprint vp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: t.accent.withValues(alpha: 0.12),
          child: Text(vp.name.isEmpty ? '?' : vp.name[0].toUpperCase(),
              style: TextStyle(color: t.accent)),
        ),
        title: Text(vp.name, style: TextStyle(color: t.textPrimary)),
        subtitle: Text(
          'Enrolled ${DateFormat.yMMMd().format(vp.createdAt)}',
          style: RT.caption.copyWith(color: t.textMuted),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: t.textMuted),
          onPressed: () => _delete(vp),
        ),
      ),
    );
  }
}
