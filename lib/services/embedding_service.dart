import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Sentence embeddings via `all-MiniLM-L6-v2` ONNX (~90 MB) — runs through
/// flutter_onnxruntime. Powers:
///   1. **Cross-meeting search** (Pro+) — embed each segment, cosine-sim
///      retrieval at query time.
///   2. **Chapter detection** — adjacent-segment cosine distance shift
///      contributes (alongside speaker change + silence gap) to the
///      heuristic chapter boundary score.
///
/// 384-dim Float32 output. Stored in `segment_embeddings(meeting_id,
/// segment_id, vec)` as a packed blob (Float32List.buffer.asUint8List).
///
/// **Tokenization:** the model expects WordPiece tokens with a specific
/// vocab. For v1, we ship a lightweight BPE-like tokenizer that handles the
/// common path (lowercase ASCII + numbers); for production multilingual
/// support, swap in a real WordPiece tokenizer that uses the bundled
/// `vocab.txt` from the same release.
class EmbeddingService {
  static const int dim = 384;
  static const int maxSeqLen = 128;

  static const _modelUrl =
      'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/onnx/model.onnx';
  static const _modelFilename = 'all-MiniLM-L6-v2.onnx';
  static const _vocabUrl =
      'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/vocab.txt';
  static const _vocabFilename = 'all-MiniLM-L6-v2-vocab.txt';

  OrtSession? _session;
  Map<String, int>? _vocab;

  Future<String> _modelPath() async {
    final docs = await getApplicationSupportDirectory();
    final dir = Directory(p.join(docs.path, 'onnx_models'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return p.join(dir.path, _modelFilename);
  }

  Future<String> _vocabPath() async {
    final docs = await getApplicationSupportDirectory();
    final dir = Directory(p.join(docs.path, 'onnx_models'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return p.join(dir.path, _vocabFilename);
  }

  Future<bool> isModelInstalled() async {
    final m = File(await _modelPath());
    final v = File(await _vocabPath());
    return await m.exists() && await v.exists() && (await m.length()) > 1024;
  }

  Future<void> ensureModelInstalled({void Function(double)? onProgress}) async {
    if (await isModelInstalled()) return;
    await _downloadOne(_modelUrl, await _modelPath(), onProgress: onProgress);
    await _downloadOne(_vocabUrl, await _vocabPath());
  }

  Future<void> _downloadOne(
    String url,
    String destPath, {
    void Function(double)? onProgress,
  }) async {
    final tmp = File('$destPath.part');
    final req = http.Request('GET', Uri.parse(url));
    final res = await http.Client().send(req);
    if (res.statusCode != 200) {
      throw StateError(
        'Embedding model download failed: HTTP ${res.statusCode}',
      );
    }
    final total = res.contentLength ?? 0;
    var got = 0;
    final sink = tmp.openWrite();
    try {
      await for (final chunk in res.stream) {
        sink.add(chunk);
        got += chunk.length;
        if (total > 0 && onProgress != null) onProgress(got / total);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    await tmp.rename(destPath);
  }

  Future<OrtSession> _ensureSession() async {
    if (_session != null) return _session!;
    if (!await isModelInstalled()) {
      await ensureModelInstalled();
    }
    final ort = OnnxRuntime();
    _session = await ort.createSession(await _modelPath());
    return _session!;
  }

  Future<Map<String, int>> _ensureVocab() async {
    if (_vocab != null) return _vocab!;
    final contents = await File(await _vocabPath()).readAsString();
    final map = <String, int>{};
    var i = 0;
    for (final line in const LineSplitter().convert(contents)) {
      map[line] = i++;
    }
    _vocab = map;
    return map;
  }

  /// True if the MiniLM model + vocab are installed and this service can
  /// actually embed. Callers MUST check this before embedding in bulk — [embed]
  /// throws rather than inventing a vector.
  Future<bool> isReady() async {
    try {
      await _ensureSession();
      await _ensureVocab();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Embed a single text. Returns a 384-dim L2-normalized Float32List.
  ///
  /// THROWS if the model is unavailable. It used to return a deterministic
  /// hash-of-the-text vector instead, which was silent, permanent corruption:
  /// those fake vectors get written to SegmentEmbeddings and poison
  /// cross-meeting search forever, and nothing anywhere would ever report a
  /// problem. A meaningless vector is not a degraded answer, it is a wrong one.
  /// (CLAUDE.md: no mock/fallback data — throw StateError with context.)
  Future<Float32List> embed(String text) async {
    try {
      final session = await _ensureSession();
      final vocab = await _ensureVocab();
      final tokens = _tokenize(text, vocab);
      final inputIds = Int64List(maxSeqLen);
      final attentionMask = Int64List(maxSeqLen);
      final tokenTypeIds = Int64List(maxSeqLen); // all zeros, sentence A
      for (var i = 0; i < tokens.length && i < maxSeqLen; i++) {
        inputIds[i] = tokens[i];
        attentionMask[i] = 1;
      }
      final outputs = await session.run({
        'input_ids': await OrtValue.fromList(inputIds, [1, maxSeqLen]),
        'attention_mask': await OrtValue.fromList(attentionMask, [
          1,
          maxSeqLen,
        ]),
        'token_type_ids': await OrtValue.fromList(tokenTypeIds, [1, maxSeqLen]),
      });
      // Mean-pool the last hidden state across non-padding tokens, then L2.
      final last = await outputs['last_hidden_state']!.asList();
      // last is [1, maxSeqLen, 384] flattened.
      final out = Float32List(dim);
      var counted = 0;
      for (var t = 0; t < maxSeqLen; t++) {
        if (attentionMask[t] == 0) continue;
        counted++;
        final baseIdx = t * dim;
        for (var d = 0; d < dim; d++) {
          out[d] += (last[baseIdx + d] as num).toDouble();
        }
      }
      if (counted > 0) {
        for (var d = 0; d < dim; d++) {
          out[d] /= counted;
        }
      }
      return _l2Normalize(out);
    } on StateError {
      rethrow;
    } catch (e) {
      throw StateError(
        'EmbeddingService.embed failed — the MiniLM model is unavailable or the '
        'ONNX run errored ($e). Call isReady() first and skip the '
        'embedding-dependent feature; do NOT persist a substitute vector, it '
        'would silently poison the search index.',
      );
    }
  }

  /// Pure-Dart WordPiece tokenizer covering ~95% of English. Falls back to
  /// `[UNK]` for OOV. Production: replace with a full WordPiece impl that
  /// handles unicode normalization + accent stripping per BERT spec.
  List<int> _tokenize(String text, Map<String, int> vocab) {
    final cls = vocab['[CLS]'] ?? 101;
    final sep = vocab['[SEP]'] ?? 102;
    final unk = vocab['[UNK]'] ?? 100;

    final out = <int>[cls];
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.isEmpty) continue;
      if (out.length >= maxSeqLen - 1) break;
      // Greedy longest-match WordPiece.
      var i = 0;
      var firstPiece = true;
      while (i < word.length) {
        var j = word.length;
        int? piece;
        while (j > i) {
          final candidate = firstPiece
              ? word.substring(i, j)
              : '##${word.substring(i, j)}';
          if (vocab.containsKey(candidate)) {
            piece = vocab[candidate];
            i = j;
            break;
          }
          j--;
        }
        if (piece == null) {
          out.add(unk);
          break;
        }
        out.add(piece);
        firstPiece = false;
        if (out.length >= maxSeqLen - 1) break;
      }
    }
    out.add(sep);
    return out;
  }

  /// Cosine similarity between two L2-normalized vectors (== dot product).
  static double cosineSim(Float32List a, Float32List b) {
    if (a.length != b.length) return 0;
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  Float32List _l2Normalize(Float32List v) {
    var norm = 0.0;
    for (final x in v) {
      norm += x * x;
    }
    norm = math.sqrt(norm);
    if (norm < 1e-8) return v;
    final out = Float32List(v.length);
    for (var i = 0; i < v.length; i++) {
      out[i] = v[i] / norm;
    }
    return out;
  }
}

/// LineSplitter copy that doesn't pull in dart:convert just for line-by-line
/// vocab parsing. Lightweight + null-safe.
class LineSplitter {
  const LineSplitter();

  List<String> convert(String input) {
    return input.split(RegExp(r'\r?\n')).where((s) => s.isNotEmpty).toList();
  }
}
