import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({
    required this.name,
    required this.photoUrl,
    required this.size,
    this.borderColor = AppColors.peach,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim();
    final initial = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: AppColors.primary,
        backgroundImage: imageUrl == null || imageUrl.isEmpty
            ? null
            : NetworkImage(imageUrl),
        child: imageUrl == null || imageUrl.isEmpty
            ? Text(
                initial,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}
