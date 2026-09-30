import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'home_models.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    required this.friend,
    this.size = 58,
    this.showBorder = true,
    this.photoUrl,
    this.localPhotoPath,
    super.key,
  });

  final SlamFriend friend;
  final double size;
  final bool showBorder;
  final String? photoUrl;
  final String? localPhotoPath;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim();
    final imagePath = localPhotoPath?.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceWarm,
        border: showBorder
            ? Border.all(color: AppColors.accent, width: size > 64 ? 1.8 : 1.2)
            : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: switch ((
          imageUrl?.isNotEmpty == true,
          imagePath?.isNotEmpty == true,
        )) {
          (true, _) => Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }

              return _AvatarLoadingIndicator(size: size);
            },
            errorBuilder: (_, _, _) =>
                CustomPaint(painter: _AvatarPainter(friend)),
          ),
          (_, true) => Image.file(
            File(imagePath!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                CustomPaint(painter: _AvatarPainter(friend)),
          ),
          _ => CustomPaint(painter: _AvatarPainter(friend)),
        },
      ),
    );
  }
}

class _AvatarLoadingIndicator extends StatelessWidget {
  const _AvatarLoadingIndicator({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWarm,
      child: Center(
        child: SizedBox(
          width: size * .34,
          height: size * .34,
          child: const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter(this.friend);

  final SlamFriend friend;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..isAntiAlias = true;

    final bg = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: friend.colors,
    ).createShader(bg);
    canvas.drawRect(bg, paint);
    paint.shader = null;

    paint.color = const Color(0xFFF2B28B);
    canvas.drawCircle(
      center.translate(0, size.height * .04),
      size.width * .24,
      paint,
    );

    paint.color = friend.hairColor;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, -size.height * .18),
        width: size.width * .56,
        height: size.height * .30,
      ),
      paint,
    );

    paint.color = AppColors.primary;
    canvas.drawCircle(
      center.translate(-size.width * .08, size.height * .03),
      size.width * .018,
      paint,
    );
    canvas.drawCircle(
      center.translate(size.width * .08, size.height * .03),
      size.width * .018,
      paint,
    );

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .018
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, size.height * .08),
        width: size.width * .18,
        height: size.height * .10,
      ),
      .15,
      2.85,
      false,
      paint,
    );
    paint.style = PaintingStyle.fill;

    paint.color = friend.colors.last.withValues(alpha: .95);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .20,
          size.height * .68,
          size.width * .60,
          size.height * .34,
        ),
        Radius.circular(size.width * .16),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.friend != friend;
}
