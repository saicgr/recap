import 'dart:async';

import 'package:flutter/material.dart';

import '../ui/theme.dart';

/// Live audio meter widget for the recording screen (D14.6). Renders a
/// scrolling bar-graph of RMS levels plus a numeric dB display with a
/// "clipping" warning above -3 dB.
///
/// Driven by any Stream<double> of 0..1 RMS values — for in-app recordings
/// we'll wire it to a tap on the recorder service's PCM frames; for desktop
/// system audio it consumes [SystemAudioCapture.levels()].
class WaveformMeter extends StatefulWidget {
  const WaveformMeter({
    super.key,
    required this.levels,
    this.height = 48,
    this.barCount = 60,
  });

  final Stream<double> levels;
  final double height;
  final int barCount;

  @override
  State<WaveformMeter> createState() => _WaveformMeterState();
}

class _WaveformMeterState extends State<WaveformMeter> {
  late final List<double> _bars =
      List<double>.filled(widget.barCount, 0, growable: false);
  late final StreamSubscription<double> _sub;
  double _currentRms = 0;

  @override
  void initState() {
    super.initState();
    _sub = widget.levels.listen((rms) {
      _currentRms = rms;
      // Shift bars left by one + push new bar on right.
      for (var i = 0; i < _bars.length - 1; i++) {
        _bars[i] = _bars[i + 1];
      }
      _bars[_bars.length - 1] = rms;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    final db = _rmsToDb(_currentRms);
    final clipping = db > -3;
    final hot = db > -12;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 56,
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: t.bgSubtle,
              border: Border.all(
                  color: clipping
                      ? t.recordRed
                      : hot
                          ? t.warn
                          : t.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${db.isFinite ? db.toStringAsFixed(0) : '−∞'} dB',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: clipping
                    ? t.recordRed
                    : hot
                        ? t.warn
                        : t.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: widget.height,
              child: CustomPaint(
                painter: _BarsPainter(
                  bars: _bars,
                  color: hot ? t.warn : t.accent,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _rmsToDb(double rms) {
    if (rms <= 0.00001) return double.negativeInfinity;
    return 20 * _log10(rms);
  }

  static double _log10(double x) {
    // Newton's series fallback; precise enough for a meter.
    var sum = 0.0;
    var term = (x - 1) / (x + 1);
    final term2 = term * term;
    for (var n = 0; n < 6; n++) {
      sum += term / (2 * n + 1);
      term *= term2;
    }
    return 2 * sum / 2.302585093; // ln→log10 conversion
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.bars, required this.color});
  final List<double> bars;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width / bars.length;
    for (var i = 0; i < bars.length; i++) {
      final h = (bars[i].clamp(0.0, 1.0)) * size.height;
      final cx = i * w + w / 2;
      final rect = Rect.fromCenter(
        center: Offset(cx, size.height / 2),
        width: w * 0.7,
        height: h.clamp(2, size.height),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.bars != bars || old.color != color;
}
