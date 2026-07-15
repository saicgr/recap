import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'theme.dart';
import 'type.dart';

// ─── Top bar ────────────────────────────────────────────────────────────────

/// Flat app bar. No shadow, no border. Title centered, leading/trailing slots
/// for icon-buttons or text.
class TopBar extends StatelessWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget> trailing;
  final bool large;
  final Widget? largeTitle;
  final EdgeInsets padding;

  const TopBar({
    super.key,
    this.title,
    this.leading,
    this.trailing = const [],
    this.large = false,
    this.largeTitle,
    this.padding = const EdgeInsets.fromLTRB(16, 6, 16, 6),
  });

  @override
  Widget build(BuildContext context) {
    if (large) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [if (leading != null) leading!]),
                  Row(children: trailing),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (largeTitle != null) largeTitle!,
          ],
        ),
      );
    }
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Row(children: [if (leading != null) leading!]),
            ),
            Expanded(child: Center(child: title ?? const SizedBox.shrink())),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: trailing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Icon button ────────────────────────────────────────────────────────────

class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool accent;
  final String? tooltip;

  const IconBtn({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 36,
    this.accent = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    final glass = t.buttonStyle == RecapButtonStyle.glass;
    final btn = Material(
      color: glass
          ? (t.mode == RecapMode.dark
                ? const Color.fromRGBO(255, 255, 255, 0.10)
                : const Color.fromRGBO(255, 255, 255, 0.55))
          : Colors.transparent,
      shape: glass
          ? CircleBorder(
              side: BorderSide(
                color: t.mode == RecapMode.dark
                    ? const Color.fromRGBO(255, 255, 255, 0.14)
                    : const Color.fromRGBO(0, 0, 0, 0.06),
              ),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onPressed,
        customBorder: glass
            ? const CircleBorder()
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        hoverColor: t.divider,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.5,
            color: accent ? t.accent : t.textSecondary,
          ),
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}

// ─── Button ─────────────────────────────────────────────────────────────────

enum BtnVariant { primary, secondary, ghost, destructive, accentSoft }

enum BtnSize { sm, md, lg }

class Btn extends StatelessWidget {
  final String label;
  final BtnVariant variant;
  final BtnSize size;
  final IconData? leading;
  final IconData? trailing;
  final VoidCallback? onPressed;
  final bool full;

  const Btn({
    super.key,
    required this.label,
    this.variant = BtnVariant.primary,
    this.size = BtnSize.md,
    this.leading,
    this.trailing,
    this.onPressed,
    this.full = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    final h = switch (size) {
      BtnSize.lg => 52.0,
      BtnSize.sm => 32.0,
      BtnSize.md => 44.0,
    };
    final px = switch (size) {
      BtnSize.lg => 24.0,
      BtnSize.sm => 12.0,
      BtnSize.md => 18.0,
    };
    final fs = switch (size) {
      BtnSize.lg => 17.0,
      BtnSize.sm => 13.0,
      BtnSize.md => 15.0,
    };

    late final Color bg;
    late final Color fg;
    late final Color border;
    switch (variant) {
      case BtnVariant.primary:
        bg = t.accent;
        fg = Colors.white;
        border = Colors.transparent;
      case BtnVariant.secondary:
        bg = t.surface;
        fg = t.textPrimary;
        border = t.border;
      case BtnVariant.ghost:
        bg = Colors.transparent;
        fg = t.textPrimary;
        border = Colors.transparent;
      case BtnVariant.destructive:
        bg = Colors.transparent;
        fg = t.recordRed;
        border = t.border;
      case BtnVariant.accentSoft:
        bg = t.accentSoft;
        fg = t.accent;
        border = Colors.transparent;
    }

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: h,
          width: full ? double.infinity : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: px),
            child: Row(
              mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  Icon(leading, size: fs + 1, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fs,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                    color: fg,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailing, size: fs + 1, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chip ───────────────────────────────────────────────────────────────────

class Chip2 extends StatelessWidget {
  final String label;
  final IconData? leading;
  final bool accent;
  final BtnSize size;

  const Chip2({
    super.key,
    required this.label,
    this.leading,
    this.accent = false,
    this.size = BtnSize.md,
  });

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    final pad = size == BtnSize.sm
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    final color = accent ? t.accent : t.textSecondary;
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: accent ? t.accentSoft : t.bgSubtle,
        border: Border.all(color: accent ? t.accentBorder : t.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            Icon(leading, size: size == BtnSize.sm ? 11 : 12, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: size == BtnSize.sm ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.07,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card ───────────────────────────────────────────────────────────────────

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool accent;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final double radius;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accent = false,
    this.onTap,
    this.margin,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: accent ? t.accentBorder : t.border),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// ─── Section header ─────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String label;
  final Widget? action;
  final EdgeInsets padding;
  const SectionHeader({
    super.key,
    required this.label,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 8),
  });

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: RT.caption.copyWith(color: t.textMuted),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ─── Settings group + row ───────────────────────────────────────────────────

class SettingsGroup extends StatelessWidget {
  final String? label;
  final List<Widget> children;
  final EdgeInsets margin;
  const SettingsGroup({
    super.key,
    this.label,
    required this.children,
    this.margin = const EdgeInsets.only(bottom: 24),
  });

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                label!.toUpperCase(),
                style: RT.caption.copyWith(color: t.textMuted),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: t.surface,
              border: Border.all(color: t.border),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool accentIcon;
  final bool last;

  const SettingsRow({
    super.key,
    this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.accentIcon = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: last
                  ? BorderSide.none
                  : BorderSide(color: t.divider, width: 1),
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accentIcon ? t.accentSoft : t.bgSubtle,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    icon,
                    size: 15,
                    color: danger
                        ? t.recordRed
                        : accentIcon
                        ? t.accent
                        : t.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: RT.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: danger ? t.recordRed : t.textPrimary,
                  ),
                ),
              ),
              if (value != null) ...[
                Text(value!, style: RT.body.copyWith(color: t.textMuted)),
                if (trailing != null) const SizedBox(width: 6),
              ],
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Toggle ─────────────────────────────────────────────────────────────────

class RecapToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const RecapToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? t.accent : t.border,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.18),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Segmented (light/dark, flat/glass) ─────────────────────────────────────

class Segmented<T> extends StatelessWidget {
  final List<({T value, String label})> options;
  final T value;
  final ValueChanged<T> onChanged;
  const Segmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.bgSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: options.map((o) {
          final selected = o.value == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.value),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: selected ? t.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: t.mode == RecapMode.dark
                                ? const Color.fromRGBO(0, 0, 0, 0.35)
                                : const Color.fromRGBO(20, 18, 12, 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  o.label,
                  style: RT.label.copyWith(
                    color: selected ? t.textPrimary : t.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Alias to avoid colliding with the type parameter `T` above.

// ─── Accent picker swatches ─────────────────────────────────────────────────

class AccentSwatches extends StatelessWidget {
  final AccentOption value;
  final ValueChanged<AccentOption> onChanged;
  const AccentSwatches({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Row(
      children: accentOptions.map((o) {
        final selected = o == value;
        final color = t.mode == RecapMode.dark ? o.dark : o.light;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? t.textPrimary : Colors.transparent,
                    width: selected ? 1.5 : 0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.06),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Tabs (underline) ───────────────────────────────────────────────────────

class TabItem {
  final String label;
  final int? count;
  final String value;
  const TabItem({required this.label, required this.value, this.count});
}

class TabsBar extends StatelessWidget {
  final List<TabItem> items;
  final String value;
  final ValueChanged<String> onChanged;
  const TabsBar({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: items.map((item) {
          final active = item.value == value;
          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: GestureDetector(
              onTap: () => onChanged(item.value),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? t.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      item.label,
                      style: RT.subtitle.copyWith(
                        color: active ? t.textPrimary : t.textMuted,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (item.count != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${item.count}',
                        style: RT.label.copyWith(color: t.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Record FAB ─────────────────────────────────────────────────────────────

class RecordFab extends StatefulWidget {
  final bool recording;
  final VoidCallback? onPressed;
  final double size;
  const RecordFab({
    super.key,
    this.recording = false,
    this.onPressed,
    this.size = 72,
  });

  @override
  State<RecordFab> createState() => _RecordFabState();
}

class _RecordFabState extends State<RecordFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    final baseBg = widget.recording ? t.recordRed : t.accent;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: widget.size,
        height: widget.size,
        transform: Matrix4.identity()
          ..scaleByDouble(
            _pressed ? 0.97 : 1.0,
            _pressed ? 0.97 : 1.0,
            1.0,
            1.0,
          ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: baseBg,
          boxShadow: [
            BoxShadow(
              color: baseBg.withValues(alpha: 0.35),
              blurRadius: 28,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: widget.recording
              ? Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Icon(Icons.mic, size: widget.size * 0.4, color: Colors.white),
        ),
      ),
    );
  }
}

// ─── Record dot (pulsing red dot) ───────────────────────────────────────────

class RecDot extends StatefulWidget {
  final double size;
  const RecDot({super.key, this.size = 8});

  @override
  State<RecDot> createState() => _RecDotState();
}

class _RecDotState extends State<RecDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t.recordRed.withValues(alpha: 0.6 + (_ctrl.value * 0.4)),
        ),
      ),
    );
  }
}

// ─── Waveform (animated bars) ───────────────────────────────────────────────

class Waveform extends StatefulWidget {
  final int bars;
  final bool active;
  final double height;
  final Color? color;
  const Waveform({
    super.key,
    this.bars = 32,
    this.active = true,
    this.height = 32,
    this.color,
  });

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _t = elapsed.inMilliseconds / 1000.0;
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    final c = widget.color ?? t.accent;
    return SizedBox(
      height: widget.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.bars, (i) {
          final s1 = math.sin(_t * 4 + i * 0.6) * 0.5 + 0.5;
          final s2 = math.cos(_t * 2 + i * 1.1) * 0.5 + 0.5;
          final h = widget.active ? (4 + s1 * s2 * (widget.height - 4)) : 3.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              width: 2.5,
              height: h,
              decoration: BoxDecoration(
                color: c.withValues(
                  alpha: widget.active ? 0.55 + s1 * 0.45 : 0.35,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
