import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

import 'import_pipeline.dart';

/// YouTube import via the public caption track only. We never download the
/// video itself — that would violate YouTube ToS and risk app-store rejection.
///
/// Flow:
///   1. Parse the URL → extract video ID (supports youtube.com/watch?v=…,
///      youtu.be/…, /shorts/…, /embed/…).
///   2. Fetch the watch page HTML.
///   3. Extract the caption-track list URL from the embedded
///      ytInitialPlayerResponse JSON.
///   4. Pick the user's-language track if available, else English, else first.
///   5. Fetch the timedtext XML → parse <text start="..." dur="..."> entries
///      into transcript segments.
///   6. Return ImportedAudio with precomputed transcript + segments; audio
///      path points to a 0-byte placeholder (we have no audio).
///
/// When a video has no captions, throws [NoCaptionsAvailable] so the UI can
/// guide the user to import the audio file themselves.
class NoCaptionsAvailable implements Exception {
  final String videoId;
  const NoCaptionsAvailable(this.videoId);
  @override
  String toString() =>
      'No captions available for video $videoId. Save the audio yourself, then File-import.';
}

class YoutubeImporter {
  /// Pulls the caption track for [url] and returns an ImportedAudio whose
  /// `precomputedTranscript` and `precomputedSegments` are populated.
  /// The wavPath is empty — caller should treat this as caption-only import.
  static Future<ImportedAudio> importByUrl(String url,
      {String preferredLang = 'en'}) async {
    final videoId = _extractVideoId(url);
    if (videoId == null) {
      throw StateError('Could not find a YouTube video ID in URL: $url');
    }
    final watchUri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    final res = await http.get(watchUri, headers: {
      'User-Agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
      'Accept-Language': '$preferredLang,en;q=0.9',
    });
    if (res.statusCode != 200) {
      throw StateError('YouTube returned HTTP ${res.statusCode}');
    }
    final html = res.body;

    final captionTrackUrl =
        _findCaptionTrackUrl(html, preferredLang: preferredLang);
    if (captionTrackUrl == null) {
      throw NoCaptionsAvailable(videoId);
    }

    final ttRes = await http.get(Uri.parse(captionTrackUrl));
    if (ttRes.statusCode != 200) {
      throw StateError(
          'Caption track fetch failed: HTTP ${ttRes.statusCode}');
    }

    final segments = _parseTimedText(ttRes.body);
    if (segments.isEmpty) {
      throw NoCaptionsAvailable(videoId);
    }
    final body = segments.map((e) => e.body).join(' ');
    final lastEndMs = segments.last.endMs;

    final title = _extractTitle(html) ?? 'YouTube import';

    return ImportedAudio(
      wavPath: '', // caption-only; no local audio file
      duration: Duration(milliseconds: lastEndMs),
      title: title,
      sourceDate: DateTime.now(),
      precomputedTranscript: body,
      precomputedSegments: segments,
    );
  }

  static String? _extractVideoId(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return null;
    if (u.host.contains('youtu.be')) {
      return u.pathSegments.isEmpty ? null : u.pathSegments.first;
    }
    if (!u.host.contains('youtube.com')) return null;
    final v = u.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    final segs = u.pathSegments;
    if (segs.length >= 2 &&
        (segs.first == 'shorts' ||
            segs.first == 'embed' ||
            segs.first == 'live')) {
      return segs[1];
    }
    return null;
  }

  /// Pull the captionTracks list out of the ytInitialPlayerResponse JSON
  /// blob embedded in the watch HTML, and pick the best match.
  static String? _findCaptionTrackUrl(String html,
      {required String preferredLang}) {
    // The JSON is inline: var ytInitialPlayerResponse = {...};
    final start = html.indexOf('captionTracks');
    if (start < 0) return null;
    // Find the enclosing array.
    final arrStart = html.indexOf('[', start);
    if (arrStart < 0) return null;
    final arrEnd = html.indexOf(']', arrStart);
    if (arrEnd < 0) return null;
    final raw = html.substring(arrStart, arrEnd + 1);
    // Find each baseUrl + languageCode. We do this with a lightweight regex
    // rather than full JSON parsing because the surrounding context isn't
    // always strict JSON (escapes vary).
    final entries = RegExp(
            r'\{[^}]*?"baseUrl":"([^"]+)"[^}]*?"languageCode":"([^"]+)"',
            multiLine: true)
        .allMatches(raw);
    String? firstUrl;
    String? englishUrl;
    String? preferredUrl;
    for (final m in entries) {
      final urlEsc = m.group(1)!;
      final lang = m.group(2)!;
      final decoded = urlEsc
          .replaceAll(r'&', '&')
          .replaceAll(r'\/', '/');
      firstUrl ??= decoded;
      if (lang.startsWith('en')) englishUrl ??= decoded;
      if (lang.startsWith(preferredLang)) preferredUrl ??= decoded;
    }
    return preferredUrl ?? englishUrl ?? firstUrl;
  }

  static List<({int startMs, int endMs, String body})> _parseTimedText(
      String body) {
    final out = <({int startMs, int endMs, String body})>[];
    try {
      final doc = xml.XmlDocument.parse(body);
      for (final el in doc.findAllElements('text')) {
        final start = double.tryParse(el.getAttribute('start') ?? '0') ?? 0;
        final dur = double.tryParse(el.getAttribute('dur') ?? '0') ?? 0;
        final text = el.innerText
            .replaceAll('&amp;', '&')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll('\n', ' ')
            .trim();
        if (text.isEmpty) continue;
        out.add((
          startMs: (start * 1000).round(),
          endMs: ((start + dur) * 1000).round(),
          body: text,
        ));
      }
    } catch (_) {
      // Malformed — leave list empty, caller will throw NoCaptionsAvailable.
    }
    return out;
  }

  static String? _extractTitle(String html) {
    final m = RegExp(r'<meta name="title" content="([^"]+)"').firstMatch(html);
    if (m != null) return m.group(1);
    final m2 = RegExp(r'<title>(.+?) - YouTube</title>').firstMatch(html);
    return m2?.group(1);
  }
}
