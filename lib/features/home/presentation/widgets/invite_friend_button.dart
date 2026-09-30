import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class InviteFriendButton extends StatelessWidget {
  const InviteFriendButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 10,
            bottom: 2,
            child: Icon(
              Icons.local_florist_outlined,
              color: Color(0x66FF8E78),
              size: 44,
            ),
          ),
          const Positioned(
            right: 16,
            bottom: 2,
            child: Icon(
              Icons.local_florist_outlined,
              color: Color(0x66FF8E78),
              size: 44,
            ),
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Invite a Friend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Transform.rotate(
                  angle: -.45,
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
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
