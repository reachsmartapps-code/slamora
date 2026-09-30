import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Spacing tokens — single source of truth
// ─────────────────────────────────────────────
abstract class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xl2 = 24.0;
  static const double xl3 = 32.0;
  static const double xl4 = 40.0;
  static const double xl5 = 48.0;
  static const double xl6 = 64.0;
}

// ─────────────────────────────────────────────
//  num extension  →  spacing SizedBoxes
//  Usage: 16.h   16.w   16.square
// ─────────────────────────────────────────────
extension NumSpacing on num {
  /// Vertical gap:  16.h
  SizedBox get h => SizedBox(height: toDouble());

  /// Horizontal gap:  16.w
  SizedBox get w => SizedBox(width: toDouble());

  /// Square gap (both axes):  16.square
  SizedBox get square => SizedBox(height: toDouble(), width: toDouble());
}

// ─────────────────────────────────────────────
//  Widget extension  →  padding shortcuts
//  Usage:
//    Text('Hello').paddingAll(16)
//    Text('Hello').paddingSymmetric(h: 16, v: 8)
//    Text('Hello').paddingOnly(left: 12, top: 8)
//    Text('Hello').paddingHorizontal(16)
//    Text('Hello').paddingVertical(8)
// ─────────────────────────────────────────────
extension WidgetSpacingX on Widget {
  Widget paddingAll(double value) => Padding(
    padding: EdgeInsets.all(value),
    child: this,
  );

  Widget paddingSymmetric({double h = 0, double v = 0}) => Padding(
    padding: EdgeInsets.symmetric(horizontal: h, vertical: v),
    child: this,
  );

  Widget paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      Padding(
        padding: EdgeInsets.only(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        ),
        child: this,
      );

  Widget paddingHorizontal(double value) => Padding(
    padding: EdgeInsets.symmetric(horizontal: value),
    child: this,
  );

  Widget paddingVertical(double value) => Padding(
    padding: EdgeInsets.symmetric(vertical: value),
    child: this,
  );

  /// Token-based shortcuts using AppSpacing
  Widget get paddingXS  => paddingAll(AppSpacing.xs);
  Widget get paddingSM  => paddingAll(AppSpacing.sm);
  Widget get paddingMD  => paddingAll(AppSpacing.md);
  Widget get paddingLG  => paddingAll(AppSpacing.lg);
  Widget get paddingXL  => paddingAll(AppSpacing.xl);
  Widget get paddingXL2 => paddingAll(AppSpacing.xl2);
  Widget get paddingXL3 => paddingAll(AppSpacing.xl3);
}

// ─────────────────────────────────────────────
//  Widget extension  →  gap shortcuts
//  Adds a SizedBox AFTER the widget when used
//  inside a Column or Row via .withGapBelow / .withGapAfter
// ─────────────────────────────────────────────
extension WidgetGapX on Widget {
  /// Wraps widget + adds vertical gap below (for Column use)
  List<Widget> withGapBelow(double gap) => [this, SizedBox(height: gap)];

  /// Wraps widget + adds horizontal gap after (for Row use)
  List<Widget> withGapAfter(double gap) => [this, SizedBox(width: gap)];
}

// ─────────────────────────────────────────────
//  List<Widget> extension  →  add gaps between items
//  Usage:
//    Column(children: [...].withVerticalGap(12))
//    Row(children:    [...].withHorizontalGap(8))
//    Column(children: [...].withDivider())
// ─────────────────────────────────────────────
extension WidgetListSpacingX on List<Widget> {
  /// Inserts a vertical SizedBox between every widget
  List<Widget> withVerticalGap(double gap) => _intersperse(SizedBox(height: gap));

  /// Inserts a horizontal SizedBox between every widget
  List<Widget> withHorizontalGap(double gap) => _intersperse(SizedBox(width: gap));

  /// Token-based vertical gap shortcuts
  List<Widget> get gapXS  => withVerticalGap(AppSpacing.xs);
  List<Widget> get gapSM  => withVerticalGap(AppSpacing.sm);
  List<Widget> get gapMD  => withVerticalGap(AppSpacing.md);
  List<Widget> get gapLG  => withVerticalGap(AppSpacing.lg);
  List<Widget> get gapXL  => withVerticalGap(AppSpacing.xl);
  List<Widget> get gapXL2 => withVerticalGap(AppSpacing.xl2);
  List<Widget> get gapXL3 => withVerticalGap(AppSpacing.xl3);

  /// Token-based horizontal gap shortcuts
  List<Widget> get hGapXS  => withHorizontalGap(AppSpacing.xs);
  List<Widget> get hGapSM  => withHorizontalGap(AppSpacing.sm);
  List<Widget> get hGapMD  => withHorizontalGap(AppSpacing.md);
  List<Widget> get hGapLG  => withHorizontalGap(AppSpacing.lg);
  List<Widget> get hGapXL  => withHorizontalGap(AppSpacing.xl);
  List<Widget> get hGapXL2 => withHorizontalGap(AppSpacing.xl2);
  List<Widget> get hGapXL3 => withHorizontalGap(AppSpacing.xl3);

  /// Inserts a Divider between every widget
  List<Widget> withDivider({Color? color, double thickness = 0.5}) =>
      _intersperse(Divider(color: color, thickness: thickness));

  List<Widget> _intersperse(Widget separator) {
    if (isEmpty) return this;
    final result = <Widget>[];
    for (int i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) result.add(separator);
    }
    return result;
  }
}

// ─────────────────────────────────────────────
//  Pre-built gap widgets (use directly in widget trees)
//  Usage: Gap.sm   Gap.lg   Gap.xl2
// ─────────────────────────────────────────────
abstract class Gap {
  // Vertical
  static const SizedBox xs  = SizedBox(height: AppSpacing.xs);
  static const SizedBox sm  = SizedBox(height: AppSpacing.sm);
  static const SizedBox md  = SizedBox(height: AppSpacing.md);
  static const SizedBox lg  = SizedBox(height: AppSpacing.lg);
  static const SizedBox xl  = SizedBox(height: AppSpacing.xl);
  static const SizedBox xl2 = SizedBox(height: AppSpacing.xl2);
  static const SizedBox xl3 = SizedBox(height: AppSpacing.xl3);
  static const SizedBox xl4 = SizedBox(height: AppSpacing.xl4);
  static const SizedBox xl5 = SizedBox(height: AppSpacing.xl5);
  static const SizedBox xl6 = SizedBox(height: AppSpacing.xl6);

  // Horizontal
  static const SizedBox hXS  = SizedBox(width: AppSpacing.xs);
  static const SizedBox hSM  = SizedBox(width: AppSpacing.sm);
  static const SizedBox hMD  = SizedBox(width: AppSpacing.md);
  static const SizedBox hLG  = SizedBox(width: AppSpacing.lg);
  static const SizedBox hXL  = SizedBox(width: AppSpacing.xl);
  static const SizedBox hXL2 = SizedBox(width: AppSpacing.xl2);
  static const SizedBox hXL3 = SizedBox(width: AppSpacing.xl3);

  // Flexible spacer
  static const Spacer expand = Spacer();
}