import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_theme.dart';

class AuthMemoryNote extends StatelessWidget {
  const AuthMemoryNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -.08,
      child: Container(
        width: 170,
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.peach.withValues(alpha: .44),
          borderRadius: BorderRadius.circular(42),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'More\nmemories\nwith you',
                textAlign: TextAlign.center,
                style: AppTextTheme.memoryTitle.copyWith(
                  color: AppColors.primary,
                  fontSize: 24,
                  height: .94,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.favorite_border_rounded,
                color: AppColors.coral,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthPolaroid extends StatelessWidget {
  const AuthPolaroid({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: .74,
      child: Transform.rotate(
        angle: .12,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 42),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                bottom: 28,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CustomPaint(painter: _FriendsPhotoPainter()),
                ),
              ),
              Positioned(
                right: -16,
                top: -18,
                child: Transform.rotate(
                  angle: -.12,
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.coral,
                    size: 38,
                  ),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 0,
                child: Text(
                  'Good people\nBrighter days ♡',
                  textAlign: TextAlign.center,
                  style: AppTextTheme.memoryTitle.copyWith(
                    fontSize: 18,
                    color: AppColors.primary,
                    height: .96,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendsPhotoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFD7B8), Color(0xFFA6CFE5), Color(0xFF395D77)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    final mountainPaint = Paint()..color = const Color(0xFF6F8094);
    final mountainPath = Path()
      ..moveTo(0, size.height * .34)
      ..lineTo(size.width * .25, size.height * .18)
      ..lineTo(size.width * .48, size.height * .36)
      ..lineTo(size.width * .72, size.height * .12)
      ..lineTo(size.width, size.height * .32)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(mountainPath, mountainPaint);

    final groundPaint = Paint()..color = const Color(0xFFE9B891);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .92),
        width: size.width * 1.2,
        height: size.height * .36,
      ),
      groundPaint,
    );

    _drawPerson(
      canvas,
      size,
      center: Offset(size.width * .25, size.height * .58),
      hair: const Color(0xFF523222),
      shirt: const Color(0xFF4E6E91),
      face: const Color(0xFFF4B991),
      scale: .92,
    );
    _drawPerson(
      canvas,
      size,
      center: Offset(size.width * .52, size.height * .62),
      hair: const Color(0xFF5C3422),
      shirt: const Color(0xFFFFE5DC),
      face: const Color(0xFFF3B48C),
      scale: 1.08,
    );
    _drawPerson(
      canvas,
      size,
      center: Offset(size.width * .76, size.height * .55),
      hair: const Color(0xFF2A211E),
      shirt: const Color(0xFF222F43),
      face: const Color(0xFFEAAE84),
      scale: .9,
      sunglasses: true,
    );
  }

  void _drawPerson(
    Canvas canvas,
    Size size, {
    required Offset center,
    required Color hair,
    required Color shirt,
    required Color face,
    required double scale,
    bool sunglasses = false,
  }) {
    final unit = size.width * .16 * scale;
    final hairPaint = Paint()..color = hair;
    final facePaint = Paint()..color = face;
    final shirtPaint = Paint()..color = shirt;
    final smilePaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + unit * 1.45),
        width: unit * 2.2,
        height: unit * 1.75,
      ),
      shirtPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, -unit * .25),
        width: unit * 1.5,
        height: unit * 1.75,
      ),
      hairPaint,
    );
    canvas.drawCircle(center, unit * .58, facePaint);
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, unit * .12),
        width: unit * .45,
        height: unit * .26,
      ),
      0,
      math.pi,
      false,
      smilePaint,
    );

    if (sunglasses) {
      final glassesPaint = Paint()
        ..color = AppColors.textPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        center.translate(-unit * .22, -unit * .12),
        unit * .13,
        glassesPaint,
      );
      canvas.drawCircle(
        center.translate(unit * .22, -unit * .12),
        unit * .13,
        glassesPaint,
      );
      canvas.drawLine(
        center.translate(-unit * .08, -unit * .12),
        center.translate(unit * .08, -unit * .12),
        glassesPaint,
      );
    } else {
      final eyePaint = Paint()..color = AppColors.textPrimary;
      canvas.drawCircle(
        center.translate(-unit * .22, -unit * .12),
        unit * .04,
        eyePaint,
      );
      canvas.drawCircle(
        center.translate(unit * .22, -unit * .12),
        unit * .04,
        eyePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
