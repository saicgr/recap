import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

/// Backup / restore screen (D14.3). User-controlled, E2E-encrypted backup
/// to wherever the user wants — iCloud / Drive / local. Recap never holds
/// the encryption key.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  String? _lastError;
  String? _lastBackupPath;

  Future<void> _exportNow() async {
    setState(() {
      _busy = true;
      _lastError = null;
    });
    try {
      final path = await backupService.exportAll();
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Recap backup',
      );
      if (!mounted) return;
      setState(() => _lastBackupPath = path);
    } catch (e) {
      if (!mounted) return;
      setState(() => _lastError = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
              title: Text('Backup & restore',
                  style: RT.subtitle.copyWith(color: t.textPrimary)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _card(
                    t,
                    icon: Icons.upload_outlined,
                    title: 'Export everything',
                    subtitle:
                        'All meetings, transcripts, summaries, and audio packed into one encrypted .recap-backup zip. We hold zero keys.',
                    child: Btn(
                      label: _busy ? 'Exporting…' : 'Export now',
                      variant: BtnVariant.accentSoft,
                      full: true,
                      onPressed: _busy ? null : _exportNow,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    t,
                    icon: Icons.download_outlined,
                    title: 'Restore from backup',
                    subtitle:
                        'Import a .recap-backup zip from a previous device. Idempotent — already-imported meetings are skipped.',
                    child: const Btn(
                      label: 'Restore… (coming soon)',
                      variant: BtnVariant.ghost,
                      full: true,
                      onPressed: null,
                    ),
                  ),
                  if (_lastBackupPath != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.bgSubtle,
                        border: Border.all(color: t.positive),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Last backup: $_lastBackupPath',
                          style: RT.bodySm.copyWith(color: t.textSecondary)),
                    ),
                  ],
                  if (_lastError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: t.bgSubtle,
                        border: Border.all(color: t.recordRed),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_lastError!,
                          style: RT.bodySm.copyWith(color: t.recordRed)),
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

  Widget _card(
    RecapTheme t, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: t.accent, size: 20),
              const SizedBox(width: 8),
              Text(title, style: RT.subtitle.copyWith(color: t.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: RT.bodySm.copyWith(color: t.textSecondary)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
