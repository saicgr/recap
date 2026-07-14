import 'package:flutter/material.dart';

/// Recap type ramp. Inter for UI, JetBrains Mono for timer + tabular nums.
///
/// Note: these are the fonts the design system specifies. Until those font
/// families are bundled in the app, `TextStyle` falls back to the platform
/// default (SF Pro on iOS, Roboto on Android) which is still acceptable —
/// the design language survives because it's typography hierarchy + spacing
/// + color, not the specific font.
class RT {
  static const _ui =
      null; // null = platform default; bundle 'Inter' to override
  static const _mono = null;

  static const display = TextStyle(
    fontFamily: _ui,
    fontSize: 34,
    height: 40 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.85, // -0.025em on 34px
  );

  static const titleLg = TextStyle(
    fontFamily: _ui,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.56,
  );

  static const title = TextStyle(
    fontFamily: _ui,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.33,
  );

  static const subtitle = TextStyle(
    fontFamily: _ui,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.17,
  );

  static const bodyLg = TextStyle(
    fontFamily: _ui,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
  );

  static const body = TextStyle(
    fontFamily: _ui,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.045,
  );

  static const bodySm = TextStyle(
    fontFamily: _ui,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );

  static const label = TextStyle(
    fontFamily: _ui,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.04,
  );

  static const caption = TextStyle(
    fontFamily: _ui,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.66, // 0.06em on 11px
  );

  /// Use for the recording timer + any tabular-numeric stat.
  static const timer = TextStyle(
    fontFamily: _mono,
    fontSize: 64,
    height: 1.0,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.28,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const num = TextStyle(
    fontFamily: _mono,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Helpers — quickly compose a styled text without rebuilding TextStyle each call.
Text tCaption(String text, {required Color color}) =>
    Text(text.toUpperCase(), style: RT.caption.copyWith(color: color));
