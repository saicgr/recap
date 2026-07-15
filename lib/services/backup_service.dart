import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../main.dart';

/// User-controlled E2E-encrypted backup (D14.3). Lifetime products can't
/// tolerate "lose phone = lose data" — but server-side sync would break the
/// no-account default. Solution: export everything to an encrypted zip the
/// user puts wherever they want (iCloud / Drive / Dropbox / local).
///
/// **Encryption:** PBKDF2-SHA256 (200K iterations) → AES-256-GCM, derived
/// from a user-chosen passphrase. We hold zero keys. The native crypto for
/// AES-GCM ships via the platform channel set up for `flutter_secure_storage`.
///
/// **Format:** `recap-backup-<iso8601>.recap-backup` is a zipped JSON
/// manifest + WAV files + transcripts/summaries blobs. Version-tagged so
/// future Recap installs can restore older backups.
class BackupService {
  /// Pack everything into a `.recap-backup` zip. Returns the on-disk path.
  /// Encryption is applied by the caller (we leave the cryptography step
  /// out of the zip layer so a future `--unencrypted` debug build is easy).
  Future<String> exportAll({String? toFolder}) async {
    final docs = await getApplicationSupportDirectory();
    final outDir = toFolder ?? p.join(docs.path, 'backups');
    await Directory(outDir).create(recursive: true);
    final now = DateTime.now().toIso8601String().replaceAll(':', '-');
    final outPath = p.join(outDir, 'recap-backup-$now.zip');

    final encoder = ZipFileEncoder();
    encoder.create(outPath);

    // 1. Manifest JSON — version, schema, list of meetings + audio paths.
    final meetings = await db.select(db.meetings).get();
    final manifest = {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'meetingCount': meetings.length,
      'meetings': [
        for (final m in meetings)
          {
            'id': m.id,
            'title': m.title,
            'audioPath': p.basename(m.audioPath),
            'createdAt': m.createdAt.toIso8601String(),
            'durationMs': m.durationMs,
            'status': m.status.name,
          },
      ],
    };
    encoder.addArchiveFile(
      ArchiveFile.string(
        'manifest.json',
        const JsonEncoder.withIndent('  ').convert(manifest),
      ),
    );

    // 2. Per-meeting JSON dump (transcript + segments + summaries +
    //    bookmarks). Faster restore than re-running schema migrations.
    for (final m in meetings) {
      final tr = await db.transcriptFor(m.id);
      final segs = await db.segmentsFor(m.id);
      final summaries = await db.summariesFor(m.id);
      final bookmarks = await db.bookmarksFor(m.id);
      final meetingBlob = {
        'meeting': {
          'id': m.id,
          'title': m.title,
          'audioPath': m.audioPath,
          'createdAt': m.createdAt.toIso8601String(),
          'durationMs': m.durationMs,
          'status': m.status.name,
        },
        'transcript': tr == null
            ? null
            : {'body': tr.body, 'modelId': tr.modelId},
        'segments': [
          for (final s in segs)
            {
              'id': s.id,
              'startMs': s.startMs,
              'endMs': s.endMs,
              'body': s.body,
              'speakerLabel': s.speakerLabel,
            },
        ],
        'summaries': [
          for (final s in summaries)
            {
              'id': s.id,
              'personaKey': s.personaKey,
              'body': s.body,
              'backend': s.backend.name,
              'modelId': s.modelId,
              'createdAt': s.createdAt.toIso8601String(),
            },
        ],
        'bookmarks': [
          for (final b in bookmarks)
            {'id': b.id, 'atMs': b.atMs, 'note': b.note},
        ],
      };
      encoder.addArchiveFile(
        ArchiveFile.string(
          'meetings/${m.id}.json',
          const JsonEncoder.withIndent('  ').convert(meetingBlob),
        ),
      );

      // 3. Audio file (if present). Big — most of the zip size lives here.
      final audioFile = File(m.audioPath);
      if (await audioFile.exists()) {
        encoder.addFile(audioFile, 'audio/${p.basename(m.audioPath)}');
      }
    }

    encoder.close();
    return outPath;
  }

  /// Restore a `.recap-backup` zip. Reads the manifest, recreates Drift rows,
  /// extracts audio files back to the recordings dir. Skips IDs that
  /// already exist (idempotent re-import).
  Future<int> restore(String zipPath) async {
    // TODO: implement. Skeleton committed so the Settings → Backup screen
    // can wire its "Restore" button without crashing in dev builds.
    // Reverse of [exportAll]: unzip → parse manifest → iterate meetings →
    // insertOnConflictUpdate on each Drift row → copy audio files back.
    throw UnimplementedError('Backup restore is not yet implemented.');
  }
}
