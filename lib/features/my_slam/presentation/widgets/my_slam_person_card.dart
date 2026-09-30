import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../home/presentation/widgets/home_models.dart';
import '../../../home/presentation/widgets/person_avatar.dart';

class MySlamPerson {
  const MySlamPerson({
    required this.friend,
    required this.fullName,
    required this.relation,
    required this.date,
    required this.memories,
    this.id,
    this.photoUrl,
    this.localPhotoPath,
    this.favorite = false,
  });

  final String? id;
  final SlamFriend friend;
  final String fullName;
  final String relation;
  final String date;
  final int memories;
  final String? photoUrl;
  final String? localPhotoPath;
  final bool favorite;
}

class MySlamPersonCard extends StatelessWidget {
  const MySlamPersonCard({required this.person, this.onTap, super.key});

  final MySlamPerson person;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('my-slam-person-${person.fullName}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              PersonAvatar(
                friend: person.friend,
                size: 64,
                photoUrl: person.photoUrl,
                localPhotoPath: person.localPhotoPath,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      person.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      person.relation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 5,
                      children: [
                        _MetaItem(
                          icon: Icons.calendar_month_outlined,
                          label: person.date,
                        ),
                        _MetaItem(
                          icon: Icons.favorite_border_rounded,
                          label: '${person.memories} memories',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.accent, size: 16),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
