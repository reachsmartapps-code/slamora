import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'home_models.dart';
import 'person_avatar.dart';

class SlamPreviewRow extends StatelessWidget {
  const SlamPreviewRow({required this.friends, super.key});

  final List<SlamFriend> friends;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: friends.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          if (index == friends.length) {
            return const _InvitePerson();
          }

          return _PreviewPerson(friend: friends[index]);
        },
      ),
    );
  }
}

class _PreviewPerson extends StatelessWidget {
  const _PreviewPerson({required this.friend});

  final SlamFriend friend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: Column(
        children: [
          PersonAvatar(friend: friend, size: 54),
          const SizedBox(height: 7),
          Text(
            friend.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitePerson extends StatelessWidget {
  const _InvitePerson();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceWarm,
              border: Border.all(color: AppColors.accent, width: 1.2),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.coral,
              size: 30,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Invite',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
