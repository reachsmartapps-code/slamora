import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_theme.dart';

class AnimatedSlamoraWordmark extends StatefulWidget {
  const AnimatedSlamoraWordmark({
    super.key,
    this.text = 'Slamora',
    this.style,
    this.duration = const Duration(milliseconds: 1500),
    this.startDelay = const Duration(milliseconds: 180),
    this.showCaret = true,
  });

  final String text;
  final TextStyle? style;
  final Duration duration;
  final Duration startDelay;
  final bool showCaret;

  @override
  State<AnimatedSlamoraWordmark> createState() =>
      _AnimatedSlamoraWordmarkState();
}

class _AnimatedSlamoraWordmarkState extends State<AnimatedSlamoraWordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _revealAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _start();
  }

  @override
  void didUpdateWidget(covariant AnimatedSlamoraWordmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.duration != widget.duration ||
        oldWidget.startDelay != widget.startDelay) {
      _controller.duration = widget.duration;
      _controller.reset();
      _start();
    }
  }

  Future<void> _start() async {
    await Future<void>.delayed(widget.startDelay);
    if (mounted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final textStyle =
        widget.style ??
        AppTextTheme.memoryTitle.copyWith(
          color: AppColors.primary,
          fontSize: 52,
          height: 1,
        );

    if (reduceMotion) {
      return Text(widget.text, style: textStyle);
    }

    return AnimatedBuilder(
      animation: _revealAnimation,
      builder: (context, child) {
        final progress = _revealAnimation.value;
        return Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            Opacity(opacity: 0, child: Text(widget.text, style: textStyle)),
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: child,
              ),
            ),
            if (widget.showCaret && progress > .02 && progress < .98)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(.02, 1.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Transform.rotate(
                      angle: -.22,
                      child: Container(
                        width: 2.5,
                        height: (textStyle.fontSize ?? 52) * .62,
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: .72),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.coral.withValues(alpha: .20),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: Text(widget.text, style: textStyle),
    );
  }
}
