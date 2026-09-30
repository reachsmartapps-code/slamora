import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slamora/core/extensions/spacing_extensions.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_theme.dart';

const ideaTextSoft = Color(0xFF2B4774);
const ideaTextMuted = Color(0xFF74819A);
const ideaChipBackground = Color(0xFFF2F6FF);

class AnimatedSlamoraMark extends StatefulWidget {
  const AnimatedSlamoraMark({super.key});

  @override
  State<AnimatedSlamoraMark> createState() => _AnimatedSlamoraMarkState();
}

class _AnimatedSlamoraMarkState extends State<AnimatedSlamoraMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
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

    if (reduceMotion) {
      return const _SlamoraIdeaMark(progress: .22);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _SlamoraIdeaMark(progress: _controller.value);
      },
    );
  }
}

class _SlamoraIdeaMark extends StatelessWidget {
  const _SlamoraIdeaMark({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final pulse = .5 + (.5 * Curves.easeInOutSine.transform(progress));

    return SizedBox(
      width: 96,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.scale(
            scale: 1 + (.035 * pulse),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.peach.withValues(alpha: .42),
                    AppColors.coral.withValues(alpha: .12),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0, .54, 1],
                ),
              ),
            ),
          ),
          ...List.generate(5, (index) {
            final turn = progress + (index / 5);
            final angle = (turn * 6.28318530718) - 1.2;
            final radius = 36.0 + (index.isEven ? 2 : -2);
            final sparkle = .58 + (.42 * Curves.easeInOut.transform(turn % 1));
            final size = index == 0 ? 8.0 : 5.8;

            return Transform.translate(
              offset: Offset(
                radius * math.cos(angle),
                radius * math.sin(angle),
              ),
              child: Opacity(
                opacity: sparkle,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: index.isEven ? AppColors.coral : AppColors.peach,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withValues(alpha: .28),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .001)
              ..rotateX(-.08)
              ..rotateY(.15),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, 9),
                  child: Text(
                    'S',
                    style: AppTextTheme.memoryTitle.copyWith(
                      color: AppColors.primary.withValues(alpha: .14),
                      fontSize: 78,
                      height: .86,
                      shadows: [
                        Shadow(
                          color: AppColors.primary.withValues(alpha: .18),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(4, 4),
                  child: Text(
                    'S',
                    style: AppTextTheme.memoryTitle.copyWith(
                      color: AppColors.coral.withValues(alpha: .26),
                      fontSize: 78,
                      height: .86,
                    ),
                  ),
                ),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF123B73),
                        Color(0xFF1B3565),
                        Color(0xFFFF684D),
                      ],
                    ).createShader(bounds);
                  },
                  child: Text(
                    'S',
                    style: AppTextTheme.memoryTitle.copyWith(
                      color: AppColors.primary,
                      fontSize: 78,
                      height: .86,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IdeasTopBar extends StatelessWidget {
  const IdeasTopBar({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppColors.primary,
          iconSize: 34,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: ideaTextSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ideaTextMuted,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class IdeasHeroCard extends StatelessWidget {
  const IdeasHeroCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B3565),
                      Color(0xFF244E86),
                      Color(0xFFFF684D),
                    ],
                    stops: [0, .62, 1],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .24),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
            ),
            Positioned(
              top: -36,
              left: -18,
              right: 42,
              height: 88,
              child: Transform.rotate(
                angle: -.14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .30),
                        Colors.white.withValues(alpha: .03),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: .08),
                          blurRadius: 18,
                          offset: const Offset(-4, -4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: AppColors.peach, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        6.h,
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: .82),
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IdeaSectionTitle extends StatelessWidget {
  const IdeaSectionTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: ideaTextSoft,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }
}

class IdeaChip extends StatelessWidget {
  const IdeaChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : ideaChipBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : ideaTextSoft,
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white : ideaTextSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CopyButton extends StatelessWidget {
  const CopyButton({required this.text, this.label = 'Copy', super.key});

  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Text('Copied'),
          ),
        );
      },
      icon: const Icon(Icons.copy_rounded, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
