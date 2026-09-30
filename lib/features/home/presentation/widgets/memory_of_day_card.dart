import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_theme.dart';

class MemoryOfDayCard extends StatelessWidget {
  const MemoryOfDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final polaroidWidth = compact ? 138.0 : 208.0;
        final polaroidHeight = compact ? 98.0 : 142.0;

        return Container(
          height: compact ? 246 : 224,
          padding: EdgeInsets.fromLTRB(compact ? 18 : 24, 16, 18, 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: compact
                    ? constraints.maxWidth * .58
                    : constraints.maxWidth * .50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Memory of the Day',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: compact ? 34 : 28),
                    Text(
                      '“Our Goa trip\nwas unforgettable.”',
                      style: AppTextTheme.memoryTitle.copyWith(
                        fontSize: compact ? 23 : 27,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '- Neha',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.coral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: compact
                    ? constraints.maxWidth * .43
                    : constraints.maxWidth * .36,
                top: compact ? 96 : 72,
                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.coral,
                  size: 28,
                ),
              ),
              const Positioned(
                right: 6,
                bottom: 2,
                child: Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.coral,
                  size: 36,
                ),
              ),
              Positioned(
                right: compact ? 0 : 34,
                top: compact ? 16 : -8,
                child: Transform.rotate(
                  angle: .11,
                  child: _Polaroid(
                    width: polaroidWidth,
                    height: polaroidHeight,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Polaroid extends StatelessWidget {
  const _Polaroid({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(left: 64, top: -20, child: _Tape()),
          Positioned.fill(child: CustomPaint(painter: _BeachPainter())),
        ],
      ),
    );
  }
}

class _Tape extends StatelessWidget {
  const _Tape();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: .08,
      child: Container(
        width: 72,
        height: 24,
        color: AppColors.accent.withValues(alpha: .55),
      ),
    );
  }
}

class _BeachPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final rect = Offset.zero & size;
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF9FBBD0), Color(0xFFFFD08C), Color(0xFF1D4B64)],
    ).createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null;

    paint.color = const Color(0xFFFFF1B9);
    canvas.drawCircle(Offset(size.width * .36, size.height * .48), 15, paint);
    paint.color = Colors.white.withValues(alpha: .7);
    for (final y in [.62, .72, .82]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width * .85, size.height * y - 8),
        paint..strokeWidth = 2,
      );
    }
    paint.color = const Color(0xFF173B29);
    canvas.drawLine(
      Offset(size.width * .68, size.height * .95),
      Offset(size.width * .80, size.height * .08),
      paint..strokeWidth = 6,
    );
    for (final angle in [-.9, -.45, .1, .55, .95]) {
      final start = Offset(size.width * .78, size.height * .13);
      final end = start + Offset(54 * angle, 44 * (angle.abs() - .4));
      canvas.drawLine(start, end, paint..strokeWidth = 4);
    }
    paint.color = const Color(0xFF0E3022);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .60, size.height * .82, 80, 22),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
