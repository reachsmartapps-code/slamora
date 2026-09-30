import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'home_models.dart';

class GiftIdeaCard extends StatelessWidget {
  const GiftIdeaCard({required this.gift, super.key});

  final GiftIdea gift;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 246,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 13,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 102,
            child: CustomPaint(painter: _GiftPainter(gift.kind)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gift.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  gift.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.1),
                ),
                const SizedBox(height: 8),
                Text(
                  gift.price,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.coral,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: gift.tagColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    gift.tag,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: gift.tagColor == AppColors.peach
                          ? AppColors.coral
                          : AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

class _GiftPainter extends CustomPainter {
  const _GiftPainter(this.kind);

  final GiftVisualKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case GiftVisualKind.watch:
        _drawWatch(canvas, size);
      case GiftVisualKind.notebook:
        _drawNotebook(canvas, size);
      case GiftVisualKind.mug:
        _drawMug(canvas, size);
    }
  }

  void _drawWatch(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    paint.color = const Color(0xFF3A281E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .38, 0, size.width * .24, size.height),
        const Radius.circular(8),
      ),
      paint,
    );
    paint.color = AppColors.primary;
    canvas.drawCircle(
      Offset(size.width / 2, size.height * .48),
      size.width * .34,
      paint,
    );
    paint.color = const Color(0xFFE4BE7E);
    canvas.drawCircle(
      Offset(size.width / 2, size.height * .48),
      size.width * .37,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white;
    canvas.drawLine(
      Offset(size.width / 2, size.height * .48),
      Offset(size.width * .50, size.height * .28),
      paint..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height * .48),
      Offset(size.width * .66, size.height * .52),
      paint..strokeWidth = 2,
    );
  }

  void _drawNotebook(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    canvas.save();
    canvas.translate(size.width * .12, 4);
    canvas.rotate(.08);
    paint.color = AppColors.primary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 4, size.width * .62, size.height * .88),
        const Radius.circular(2),
      ),
      paint,
    );
    paint.color = Colors.black.withValues(alpha: .18);
    canvas.drawRect(Rect.fromLTWH(14, 6, 7, size.height * .84), paint);
    canvas.restore();
  }

  void _drawMug(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    paint.color = const Color(0xFFEAD8C2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 22, 50, 58),
        const Radius.circular(8),
      ),
      paint,
    );
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 7;
    canvas.drawOval(Rect.fromLTWH(48, 34, 26, 30), paint);
    paint.style = PaintingStyle.fill;
    final paragraph = TextPainter(
      text: const TextSpan(
        text: 'BEST\nBROTHER\nEVER',
        style: TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 44);
    paragraph.paint(canvas, const Offset(12, 36));
  }

  @override
  bool shouldRepaint(covariant _GiftPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
