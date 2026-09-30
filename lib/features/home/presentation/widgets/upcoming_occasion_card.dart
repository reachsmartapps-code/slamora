import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../ideas/presentation/screens/gift_ideas_screen.dart';
import '../../../ideas/presentation/screens/message_ideas_screen.dart';
import 'home_models.dart';
import 'person_avatar.dart';

class UpcomingOccasionCard extends StatelessWidget {
  const UpcomingOccasionCard({required this.friend, super.key});

  final SlamFriend friend;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;

        return Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 22,
            18,
            compact ? 16 : 20,
            18,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: compact
              ? _CompactOccasion(friend: friend)
              : _WideOccasion(friend: friend),
        );
      },
    );
  }
}

class _CompactOccasion extends StatelessWidget {
  const _CompactOccasion({required this.friend});

  final SlamFriend friend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PersonAvatar(friend: friend, size: 58),
            const SizedBox(width: 14),
            Expanded(child: _OccasionText(friend: friend)),
            const SizedBox(width: 8),
            const SizedBox(width: 74, height: 86, child: _BalloonCluster()),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _OccasionButton(
                label: 'Gift Ideas',
                icon: Icons.card_giftcard_rounded,
                filled: true,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GiftIdeasScreen(
                        friendName: friend.name,
                        relation: 'friend',
                        occasion: 'Birthday',
                        source: 'upcoming_occasion',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OccasionButton(
                label: 'Message',
                icon: Icons.edit_outlined,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MessageIdeasScreen(
                        friendName: friend.name,
                        relation: 'friend',
                        occasion: 'birthday',
                        source: 'upcoming_occasion',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WideOccasion extends StatelessWidget {
  const _WideOccasion({required this.friend});

  final SlamFriend friend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PersonAvatar(friend: friend, size: 72),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _OccasionText(friend: friend),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _OccasionButton(
                      label: 'Gift Ideas',
                      icon: Icons.card_giftcard_rounded,
                      filled: true,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GiftIdeasScreen(
                              friendName: friend.name,
                              relation: 'friend',
                              occasion: 'Birthday',
                              source: 'upcoming_occasion',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _OccasionButton(
                      label: 'Write Message',
                      icon: Icons.edit_outlined,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MessageIdeasScreen(
                              friendName: friend.name,
                              relation: 'friend',
                              occasion: 'birthday',
                              source: 'upcoming_occasion',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const SizedBox(width: 112, height: 126, child: _BalloonCluster()),
      ],
    );
  }
}

class _OccasionText extends StatelessWidget {
  const _OccasionText({required this.friend});

  final SlamFriend friend;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          friend.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            children: const [
              TextSpan(text: 'Birthday in '),
              TextSpan(
                text: '4 days',
                style: TextStyle(
                  color: AppColors.coral,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '20 September',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OccasionButton extends StatelessWidget {
  const _OccasionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 8),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    if (filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: const BorderSide(color: AppColors.primary, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: child,
    );
  }
}

class _BalloonCluster extends StatelessWidget {
  const _BalloonCluster();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BalloonPainter());
  }
}

class _BalloonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final line = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.coral.withValues(alpha: .65);

    void drawBalloon(Offset center, double radius, Color color) {
      paint.color = color;
      canvas.drawOval(Rect.fromCircle(center: center, radius: radius), paint);
      paint.color = Colors.white.withValues(alpha: .65);
      canvas.drawArc(
        Rect.fromCircle(
          center: center.translate(-radius * .22, -radius * .18),
          radius: radius * .56,
        ),
        3.7,
        .8,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: .65),
      );
      final knot = Path()
        ..moveTo(center.dx - 3, center.dy + radius - 1)
        ..lineTo(center.dx + 3, center.dy + radius - 1)
        ..lineTo(center.dx, center.dy + radius + 5)
        ..close();
      canvas.drawPath(knot, paint);
      final string = Path()
        ..moveTo(center.dx, center.dy + radius + 5)
        ..quadraticBezierTo(
          center.dx - 6,
          center.dy + radius + 24,
          center.dx + 2,
          center.dy + radius + 42,
        );
      canvas.drawPath(string, line);
    }

    drawBalloon(
      Offset(size.width * .48, size.height * .32),
      size.shortestSide * .21,
      AppColors.coral.withValues(alpha: .88),
    );
    drawBalloon(
      Offset(size.width * .25, size.height * .50),
      size.shortestSide * .17,
      AppColors.primary,
    );
    drawBalloon(
      Offset(size.width * .72, size.height * .48),
      size.shortestSide * .18,
      AppColors.accent.withValues(alpha: .72),
    );

    paint.color = AppColors.coral;
    for (final offset in [
      Offset(size.width * .12, size.height * .63),
      Offset(size.width * .25, size.height * .80),
      Offset(size.width * .68, size.height * .73),
      Offset(size.width * .82, size.height * .86),
    ]) {
      canvas.drawCircle(offset, 2, paint);
    }
    paint.color = const Color(0xFFFFA447);
    for (final offset in [
      Offset(size.width * .08, size.height * .46),
      Offset(size.width * .22, size.height * .58),
      Offset(size.width * .52, size.height * .66),
      Offset(size.width * .88, size.height * .54),
    ]) {
      canvas.drawLine(
        offset.translate(-3, 0),
        offset.translate(3, 0),
        paint..strokeWidth = 1.2,
      );
      canvas.drawLine(offset.translate(0, -3), offset.translate(0, 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
