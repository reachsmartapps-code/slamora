import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:slamora/core/extensions/spacing_extensions.dart';

import '../../../../app/theme/app_colors.dart';

class ProfileSettingTile extends StatelessWidget {
  const ProfileSettingTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.foregroundColor = AppColors.primary,
    this.showDivider = true,
    super.key,
  });

  final List<List<dynamic>> icon;
  final String title;
  final VoidCallback? onTap;
  final Color foregroundColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Row(
              children: [
                HugeIcon(color: foregroundColor, size: 24, icon: icon),
                24.w,
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: foregroundColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 76, right: 28),
            child: Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}
