import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../billing/persona.dart';
import '../data/database.dart';

/// Branded PDF reports (D14.11). Free tier gets the "Made with Recap"
/// footer; Pro+ removes it; Power tier can add user's logo + accent colors.
///
/// Implementation uses the `pdf` + `printing` packages. To minimize coupling
/// during scaffolding, this file lays out the layer with stub methods that
/// return a placeholder text file — the real PDF rendering happens once we
/// add `pdf: ^3.x` to pubspec.yaml. Settings → Export sheet wires the
/// "PDF" button here.
class PdfExporter {
  Future<String> exportMeeting({
    required Meeting meeting,
    required Transcript? transcript,
    required List<Summary> summaries,
    PdfTemplate template = PdfTemplate.minimal,
    bool watermark = true,

    /// The user's custom templates, so a `custom:<id>` key resolves to its real
    /// name instead of being printed raw as a heading.
    Iterable<Persona> customPersonas = const [],
  }) async {
    final docs = await getApplicationSupportDirectory();
    final outDir = Directory(p.join(docs.path, 'exports'));
    if (!await outDir.exists()) await outDir.create(recursive: true);
    final outPath = p.join(outDir.path,
        '${_safeFilename(meeting.title)}-${meeting.id.substring(0, 8)}.pdf');

    // TODO: implement real PDF rendering. For now we write a placeholder
    // text file at the .pdf path so the share-sheet flow can be exercised
    // end-to-end during dev; production builds replace this with the real
    // pdf package's PdfDocument layout.
    final buf = StringBuffer()
      ..writeln('# ${meeting.title}')
      ..writeln('${meeting.createdAt}')
      ..writeln('')
      ..writeln('## Summaries (${summaries.length})')
      ..writeln('');
    for (final s in summaries) {
      // resolvePersona, not the raw key: a custom template would otherwise be
      // exported as the heading "### custom:1752438…".
      buf
        ..writeln(
            '### ${resolvePersona(s.personaKey, customPersonas).displayName}')
        ..writeln(s.body)
        ..writeln('');
    }
    buf
      ..writeln('## Transcript')
      ..writeln(transcript?.body ?? '(empty)');
    if (watermark) {
      buf
        ..writeln('')
        ..writeln('---')
        ..writeln('Made with Recap · recapfreenote.com');
    }
    await File(outPath).writeAsString(buf.toString());
    return outPath;
  }

  String _safeFilename(String s) {
    return s.replaceAll(RegExp(r'[^A-Za-z0-9 _.-]'), '').trim().isEmpty
        ? 'meeting'
        : s.replaceAll(RegExp(r'[^A-Za-z0-9 _.-]'), '').trim();
  }
}

enum PdfTemplate { minimal, professional, creative, dark }
