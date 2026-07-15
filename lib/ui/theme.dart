import 'package:flutter/material.dart';

/// Recap design tokens — ported from the v2 design system bundle.
/// Light = Things-3 cream paper. Dark = Raycast slate.
/// Single accent (default warm amber-orange), user-switchable from Settings.

enum RecapMode { light, dark }

enum RecapButtonStyle { flat, glass }

/// The four accent options offered in the Tweaks panel.
class AccentOption {
  final String name;
  final Color light;
  final Color dark;
  const AccentOption(this.name, this.light, this.dark);
}

const accentOptions = <AccentOption>[
  AccentOption('Amber', Color(0xFFD87434), Color(0xFFEC8A52)),
  AccentOption('Indigo', Color(0xFF4F46E5), Color(0xFF6C66F1)),
  AccentOption('Teal', Color(0xFF2F7E6E), Color(0xFF4FA396)),
  AccentOption('Brick', Color(0xFFB5384B), Color(0xFFD15A6C)),
];

class RecapTheme {
  final RecapMode mode;
  final Color bg;
  final Color bgSubtle;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color accentBorder;
  final Color recordRed;
  final Color border;
  final Color divider;
  final Color hairline;
  final Color positive;
  final Color warn;
  final Color overlay;
  final RecapButtonStyle buttonStyle;
  // Encoded accent components for deriving translucent variants at use sites.
  final int accentR;
  final int accentG;
  final int accentB;

  const RecapTheme._({
    required this.mode,
    required this.bg,
    required this.bgSubtle,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.accentBorder,
    required this.recordRed,
    required this.border,
    required this.divider,
    required this.hairline,
    required this.positive,
    required this.warn,
    required this.overlay,
    required this.buttonStyle,
    required this.accentR,
    required this.accentG,
    required this.accentB,
  });

  static RecapTheme build({
    required RecapMode mode,
    required AccentOption accentOpt,
    required RecapButtonStyle buttonStyle,
  }) {
    final isDark = mode == RecapMode.dark;
    final accent = isDark ? accentOpt.dark : accentOpt.light;
    final r = (accent.toARGB32() >> 16) & 0xff;
    final g = (accent.toARGB32() >> 8) & 0xff;
    final b = accent.toARGB32() & 0xff;
    final softA = isDark ? 0.14 : 0.10;
    final borderA = isDark ? 0.32 : 0.22;
    return RecapTheme._(
      mode: mode,
      bg: isDark ? const Color(0xFF161618) : const Color(0xFFFAF8F4),
      bgSubtle: isDark ? const Color(0xFF1B1B1E) : const Color(0xFFF3F0E9),
      surface: isDark ? const Color(0xFF212124) : const Color(0xFFFFFFFF),
      surfaceAlt: isDark ? const Color(0xFF26262A) : const Color(0xFFFBF9F5),
      textPrimary: isDark ? const Color(0xFFF4F2EC) : const Color(0xFF15140F),
      textSecondary: isDark ? const Color(0xFFA8A49A) : const Color(0xFF5A574F),
      textMuted: isDark ? const Color(0xFF6E6A60) : const Color(0xFF9A968B),
      accent: accent,
      accentSoft: Color.fromRGBO(r, g, b, softA),
      accentBorder: Color.fromRGBO(r, g, b, borderA),
      recordRed: isDark ? const Color(0xFFE76A55) : const Color(0xFFC9412E),
      border: isDark ? const Color(0xFF2A2A2E) : const Color(0xFFEBE6DC),
      divider: isDark ? const Color(0xFF232327) : const Color(0xFFF0ECE2),
      hairline: isDark
          ? const Color.fromRGBO(255, 253, 247, 0.06)
          : const Color.fromRGBO(20, 18, 12, 0.06),
      positive: isDark ? const Color(0xFF62B384) : const Color(0xFF3D8B5F),
      warn: isDark ? const Color(0xFFD8A647) : const Color(0xFFB98315),
      overlay: isDark
          ? const Color.fromRGBO(0, 0, 0, 0.45)
          : const Color.fromRGBO(20, 18, 12, 0.32),
      buttonStyle: buttonStyle,
      accentR: r,
      accentG: g,
      accentB: b,
    );
  }

  Color accentWithAlpha(double a) =>
      Color.fromRGBO(accentR, accentG, accentB, a);
}

/// InheritedNotifier so widgets rebuild when the theme changes.
class RecapThemeScope extends InheritedNotifier<ThemeController> {
  const RecapThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static RecapTheme of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RecapThemeScope>();
    assert(scope != null, 'RecapThemeScope missing in widget tree');
    return scope!.notifier!.theme;
  }

  static ThemeController controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RecapThemeScope>();
    assert(scope != null, 'RecapThemeScope missing in widget tree');
    return scope!.notifier!;
  }
}

class ThemeController extends ChangeNotifier {
  RecapMode _mode;
  AccentOption _accent;
  RecapButtonStyle _buttonStyle;

  ThemeController({
    RecapMode mode = RecapMode.light,
    AccentOption? accent,
    RecapButtonStyle buttonStyle = RecapButtonStyle.flat,
  })  // `mode`/`buttonStyle` are public named params (call sites pass them);
      // this._mode would rename them, so the initializing-formal lint can't apply.
      // ignore: prefer_initializing_formals
      : _mode = mode,
        _accent = accent ?? accentOptions[0],
        // ignore: prefer_initializing_formals
        _buttonStyle = buttonStyle;

  RecapMode get mode => _mode;
  AccentOption get accent => _accent;
  RecapButtonStyle get buttonStyle => _buttonStyle;

  RecapTheme get theme => RecapTheme.build(
        mode: _mode,
        accentOpt: _accent,
        buttonStyle: _buttonStyle,
      );

  void setMode(RecapMode m) {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
  }

  void setAccent(AccentOption a) {
    if (a == _accent) return;
    _accent = a;
    notifyListeners();
  }

  void setButtonStyle(RecapButtonStyle s) {
    if (s == _buttonStyle) return;
    _buttonStyle = s;
    notifyListeners();
  }
}
