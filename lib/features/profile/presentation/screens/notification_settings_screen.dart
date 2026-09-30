import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:slamora/core/extensions/spacing_extensions.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/reminder_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isUpdating = false;

  Future<void> _toggleReminderNotifications({
    required bool enabled,
    required bool currentPaused,
  }) async {
    final userId = AuthService.instance.currentUser?.uid;
    if (userId == null || _isUpdating) {
      return;
    }

    final nextPaused = !enabled;
    if (nextPaused == currentPaused) {
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await ReminderNotificationService.instance.setReminderNotificationsPaused(
        ownerUserId: userId,
        paused: nextPaused,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.coral,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text('Could not update reminder notifications.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppColors.primary,
          iconSize: 34,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        ),
        title: Text(
          'Notifications',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  22.h,
                  if (userId == null)
                    const _NotificationSettingsMessage()
                  else
                    StreamBuilder<bool>(
                      stream: ReminderNotificationService.instance
                          .watchReminderNotificationsPaused(userId),
                      builder: (context, snapshot) {
                        final paused = snapshot.data ?? false;
                        final enabled = !paused;

                        return _ReminderNotificationCard(
                          enabled: enabled,
                          isUpdating: _isUpdating,
                          onChanged: (value) => _toggleReminderNotifications(
                            enabled: value,
                            currentPaused: paused,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderNotificationCard extends StatelessWidget {
  const _ReminderNotificationCard({
    required this.enabled,
    required this.isUpdating,
    required this.onChanged,
  });

  final bool enabled;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.peach.withValues(alpha: .55)
                  : AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(10),
            ),
            child: HugeIcon(
              icon: enabled
                  ? HugeIcons.strokeRoundedNotification01
                  : HugeIcons.strokeRoundedNotificationOff01,
              color: enabled ? AppColors.coral : AppColors.primary,
              size: 28,
            ),
          ),
          14.w,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                3.h,
                Text(
                  enabled
                      ? 'Birthday and anniversary reminders are active.'
                      : 'Reminders are paused. You can turn them back on anytime.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          12.w,
          _ReminderSwitch(
            enabled: enabled,
            isUpdating: isUpdating,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ReminderSwitch extends StatelessWidget {
  const _ReminderSwitch({
    required this.enabled,
    required this.isUpdating,
    required this.onChanged,
  });

  final bool enabled;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            ignoring: isUpdating,
            child: Switch(
              activeTrackColor: AppColors.coral.withAlpha(40),
              value: enabled,
              activeThumbColor: AppColors.coral,
              inactiveThumbColor: AppColors.textSecondary,
              onChanged: onChanged,
            ),
          ),
          if (isUpdating)
            const Positioned.fill(
              child: IgnorePointer(child: _SwitchLoadingBorder()),
            ),
        ],
      ),
    );
  }
}

class _SwitchLoadingBorder extends StatefulWidget {
  const _SwitchLoadingBorder();

  @override
  State<_SwitchLoadingBorder> createState() => _SwitchLoadingBorderState();
}

class _SwitchLoadingBorderState extends State<_SwitchLoadingBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _SwitchLoadingBorderPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _SwitchLoadingBorderPainter extends CustomPainter {
  const _SwitchLoadingBorderPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(999)),
      );
    final metric = path.computeMetrics().first;
    final length = metric.length;
    final start = progress * length;
    final end = start + length * .32;
    final paint = Paint()
      ..color = AppColors.coral
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (end <= length) {
      canvas.drawPath(metric.extractPath(start, end), paint);
      return;
    }

    canvas.drawPath(metric.extractPath(start, length), paint);
    canvas.drawPath(metric.extractPath(0, end - length), paint);
  }

  @override
  bool shouldRepaint(covariant _SwitchLoadingBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _NotificationSettingsMessage extends StatelessWidget {
  const _NotificationSettingsMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Please log in to manage reminder notifications.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
