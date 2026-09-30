import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:slamora/core/extensions/spacing_extensions.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_theme.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/slam_firestore_service.dart';
import '../../../../core/widgets/user_profile_avatar.dart';
import '../widgets/home_models.dart';
import '../widgets/home_section_header.dart';
import '../widgets/person_avatar.dart';
import '../../../create_slam/presentation/screens/create_slam_flow_screen.dart';
import '../../../ideas/presentation/screens/gift_ideas_screen.dart';
import '../../../ideas/presentation/screens/message_ideas_screen.dart';
import '../../../invitations/presentation/screens/invite_friend_screen.dart';
import '../../../my_slam/presentation/screens/my_slam_detail_screen.dart';
import '../../../my_slam/presentation/screens/my_slam_screen.dart';
import '../../../my_slam/presentation/widgets/my_slam_person_card.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _friends = [
    SlamFriend(
      name: 'Amit',
      colors: [Color(0xFFF8D4B8), Color(0xFF243D73)],
      hairColor: Color(0xFF151515),
    ),
    SlamFriend(
      name: 'Neha',
      colors: [Color(0xFFFFD8C8), Color(0xFFBF4C3C)],
      hairColor: Color(0xFF4B2C21),
    ),
    SlamFriend(
      name: 'Rahul',
      colors: [Color(0xFFF7D7C0), Color(0xFF224A73)],
      hairColor: Color(0xFF121212),
    ),
    SlamFriend(
      name: 'Priya',
      colors: [Color(0xFFFFDEC8), Color(0xFFE86755)],
      hairColor: Color(0xFF3D241C),
    ),
    SlamFriend(
      name: 'Karan',
      colors: [Color(0xFFF4D2B5), Color(0xFF203863)],
      hairColor: Color(0xFF2B211C),
    ),
  ];

  void _openCreateSlamFlow() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreateSlamFlowScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(AnalyticsService.instance.homeViewed());
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = switch (_selectedIndex) {
      1 => const MySlamScreen(),
      2 => const ProfileScreen(),
      _ => _HomeDashboard(
        friends: _friends,
        onOpenMySlam: () => setState(() => _selectedIndex = 1),
        onCreateSlam: _openCreateSlamFlow,
      ),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      floatingActionButton: _selectedIndex == 0
          ? _CreateSlamFab(onPressed: _openCreateSlamFlow)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _HomeNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      body: currentPage,
    );
  }
}

class _CreateSlamFab extends StatelessWidget {
  const _CreateSlamFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'create_slam_flow',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .46)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.coral.withValues(alpha: .12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Transform.scale(
                        scale: 1.08,
                        child: Image.asset(
                          'assets/images/profile_header_smoke.avif',
                          fit: BoxFit.cover,
                          color: AppColors.primary.withValues(alpha: .20),
                          colorBlendMode: BlendMode.multiply,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: .30),
                            AppColors.coral.withValues(alpha: .20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
          /*child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                height: 48,
                padding: const EdgeInsets.fromLTRB(10, 7, 16, 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B3565),
                      Color(0xFF244E86),
                      Color(0xFFFF684D),
                    ],
                    stops: [0, .64, 1],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .26),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .22),
                      blurRadius: 18,
                      offset: const Offset(0, 9),
                    ),
                    BoxShadow(
                      color: AppColors.coral.withValues(alpha: .16),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .24),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Create Slam',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),*/
        ),
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.friends,
    required this.onOpenMySlam,
    required this.onCreateSlam,
  });

  final List<SlamFriend> friends;
  final VoidCallback onOpenMySlam;
  final VoidCallback onCreateSlam;

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUser?.uid;

    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.only(left: 18, right: 18, top: 18),
          child: Column(
            children: [
              const _HomeHeader(),
              20.h,
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeSectionHeader(
                        title: 'Upcoming Occasions',
                        actionLabel: 'See All',
                        onActionTap: onOpenMySlam,
                        showChevron: true,
                      ),
                      10.h,
                      _UpcomingOccasionsSection(
                        userId: userId,
                        fallbackFriend: friends[1],
                        onCreateSlam: onCreateSlam,
                      ),
                      20.h,
                      const _QuickIdeasCard(),
                      30.h,
                      HomeSectionHeader(
                        title: 'My Slam',
                        actionLabel: 'See All',
                        onActionTap: onOpenMySlam,
                        showChevron: true,
                      ),
                      20.h,
                      _HomeSlamPeople(
                        userId: userId,
                        onOpenMySlam: onOpenMySlam,
                        onCreateSlam: onCreateSlam,
                        fallbackFriends: [
                          friends[1],
                          friends[2],
                          friends[3],
                          friends[0],
                        ],
                      ),
                      25.h,
                      const _WhatsappInviteCard(),
                      90.h,
                    ],
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

class _HomeNavigationBar extends StatelessWidget {
  const _HomeNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(120),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(120),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.64),
                borderRadius: BorderRadius.circular(120),
                border: Border.all(
                  color: AppColors.peach.withValues(alpha: 0.42),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.80),
                    AppColors.surfaceWarm.withValues(alpha: 0.52),
                  ],
                ),
              ),
              child: NavigationBarTheme(
                data: NavigationBarTheme.of(context).copyWith(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
                    states,
                  ) {
                    final selected = states.contains(WidgetState.selected);
                    return Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? Colors.black : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    );
                  }),
                  indicatorColor: AppColors.primary.withValues(alpha: 0),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    NavigationBar(
                      selectedIndex: selectedIndex,
                      height: 72,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,

                      indicatorColor: AppColors.primary.withValues(alpha: 0),
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysShow,
                      onDestinationSelected: onDestinationSelected,
                      destinations: const [
                        NavigationDestination(
                          key: ValueKey('home-nav-home'),
                          selectedIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedHome03,
                            color: AppColors.coral,
                          ),
                          icon: HugeIcon(icon: HugeIcons.strokeRoundedHome03),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          key: ValueKey('home-nav-my-slam'),
                          selectedIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedNotebook,
                            color: AppColors.coral,
                          ),
                          icon: HugeIcon(icon: HugeIcons.strokeRoundedNotebook),
                          label: 'My Slam',
                        ),
                        NavigationDestination(
                          key: ValueKey('home-nav-profile'),
                          selectedIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedUser02,
                            color: AppColors.coral,
                          ),
                          icon: HugeIcon(icon: HugeIcons.strokeRoundedUser02),
                          label: 'Profile',
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Row(
                          children: [
                            for (var i = 0; i < 3; i += 1)
                              Expanded(
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOut,
                                    width: selectedIndex == i ? 18 : 0,
                                    height: selectedIndex == i ? 2 : 0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(1000),
                                      color: AppColors.coral,
                                      shape: BoxShape.rectangle,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final rawName = user?.displayName?.trim();
    final fallbackName = user?.email?.split('@').first.trim();
    final name = rawName == null || rawName.isEmpty
        ? fallbackName == null || fallbackName.isEmpty
              ? 'Alex'
              : fallbackName
        : rawName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final profileSize = compact ? 48.0 : 60.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi $name 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextTheme.memoryTitle.copyWith(
                      color: AppColors.primary,
                      fontSize: 28,
                      height: 1,
                    ) /*Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    )*/,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Good memories make a\nbrighter tomorrow.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: .72),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: compact ? 16 : 24),
            UserProfileAvatar(
              name: name,
              photoUrl: user?.photoURL,
              size: profileSize,
            ),
          ],
        );
      },
    );
  }
}

class _UpcomingOccasionsSection extends StatelessWidget {
  const _UpcomingOccasionsSection({
    required this.userId,
    required this.fallbackFriend,
    required this.onCreateSlam,
  });

  final String? userId;
  final SlamFriend fallbackFriend;
  final VoidCallback onCreateSlam;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return _CompactOccasionCard(
        occasion: _UpcomingOccasion.fallback(fallbackFriend),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SlamFirestoreService.instance.watchSlamsForUser(userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 166,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return _CompactOccasionCard(
            occasion: _UpcomingOccasion.fallback(fallbackFriend),
          );
        }

        final occasions =
            snapshot.data?.docs
                .expand(_UpcomingOccasion.fromSlamDoc)
                .toList() ??
            [];
        occasions.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));

        if (occasions.isEmpty) {
          return _HomeEmptyStateCard(
            icon: Icons.event_available_outlined,
            title: 'No occasions yet',
            message: 'Birthdays and anniversaries will appear here.',
            actionLabel: 'Add',
            onActionTap: onCreateSlam,
          );
        }

        return _CompactOccasionCard(occasion: occasions.first);
      },
    );
  }
}

class _HomeEmptyStateCard extends StatelessWidget {
  const _HomeEmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onActionTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: .55)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F7A563C),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.coral.withValues(alpha: .22)),
            ),
            child: Icon(icon, color: AppColors.coral, size: 22),
          ),
          12.w,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                3.h,
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          10.w,
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                actionLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.coralDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactOccasionCard extends StatelessWidget {
  const _CompactOccasionCard({required this.occasion});

  final _UpcomingOccasion occasion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              PersonAvatar(
                friend: occasion.person.friend,
                size: 72,
                photoUrl: occasion.person.photoUrl,
                localPhotoPath: occasion.person.localPhotoPath,
              ),
              15.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      occasion.person.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 15,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    3.h,
                    Text(
                      occasion.typeLabel,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    3.h,
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                        children: [
                          TextSpan(
                            text: occasion.shortDateLabel,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const TextSpan(
                            text: '  •  ',
                            style: TextStyle(
                              color: AppColors.coral,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: occasion.relativeLabel,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              12.w,
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedGift,
                  color: AppColors.coral,
                  size: 28,
                ),
              ),
            ],
          ),
          20.h,
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => GiftIdeasScreen(
                            friendName: occasion.person.fullName,
                            relation: occasion.person.relation,
                            occasion: occasion.typeLabel,
                            source: 'upcoming_occasion',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Find Gift Ideas ✨',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: AppColors.surface,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              10.w,
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MessageIdeasScreen(
                            friendName: occasion.person.fullName,
                            relation: occasion.person.relation,
                            occasion: occasion.typeLabel.toLowerCase(),
                            source: 'upcoming_occasion',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: AppColors.primary, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Message Ideas ✨',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingOccasion {
  const _UpcomingOccasion({
    required this.person,
    required this.typeLabel,
    required this.shortDateLabel,
    required this.daysUntil,
  });

  final MySlamPerson person;
  final String typeLabel;
  final String shortDateLabel;
  final int daysUntil;

  String get relativeLabel {
    if (daysUntil == 0) {
      return 'today';
    }
    if (daysUntil == 1) {
      return 'tomorrow';
    }
    return '$daysUntil days left';
  }

  static _UpcomingOccasion fallback(SlamFriend friend) {
    return _UpcomingOccasion(
      person: MySlamPerson(
        friend: friend,
        fullName: 'Neha Verma',
        relation: 'friend',
        date: '12 Sep',
        memories: 0,
      ),
      typeLabel: 'Birthday',
      shortDateLabel: '12 Sep',
      daysUntil: 5,
    );
  }

  static Iterable<_UpcomingOccasion> fromSlamDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final fullName = _HomeSlamPeople._stringValue(
      data['fullName'],
      fallback: 'Untitled Slam',
    );
    final nickname = _HomeSlamPeople._stringValue(data['nickname']);
    final relation = _HomeSlamPeople._stringValue(
      data['relation'],
      fallback: nickname,
    );
    final photoUrl = _HomeSlamPeople._stringValue(data['photoUrl']);
    final localPhotoPath = _HomeSlamPeople._stringValue(data['localPhotoPath']);
    final person = MySlamPerson(
      id: doc.id,
      friend: SlamFriend(
        name: fullName,
        colors: const [Color(0xFFFFD8C8), Color(0xFFBF4C3C)],
        hairColor: const Color(0xFF4B2C21),
      ),
      fullName: fullName,
      relation: relation.isEmpty ? 'My Slam' : relation,
      date: _HomeSlamPeople._shortDate(
        _HomeSlamPeople._stringValue(data['dateOfBirth']),
      ),
      memories: _HomeSlamPeople._intValue(data['photoCount']),
      photoUrl: photoUrl,
      localPhotoPath: localPhotoPath,
      favorite: data['favorite'] == true,
    );

    final occasions = <_UpcomingOccasion>[];
    final birthday = _dateParts(
      _HomeSlamPeople._stringValue(data['dateOfBirth']),
    );
    final anniversary = _dateParts(
      _HomeSlamPeople._stringValue(data['anniversary']),
    );

    if (birthday != null) {
      occasions.add(
        _UpcomingOccasion(
          person: person,
          typeLabel: 'Birthday',
          shortDateLabel: _shortDateLabel(birthday),
          daysUntil: _daysUntil(birthday),
        ),
      );
    }

    if (anniversary != null) {
      occasions.add(
        _UpcomingOccasion(
          person: person,
          typeLabel: 'Anniversary',
          shortDateLabel: _shortDateLabel(anniversary),
          daysUntil: _daysUntil(anniversary),
        ),
      );
    }

    return occasions;
  }

  static (int, int)? _dateParts(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return null;
    }

    final day = int.tryParse(parts.first);
    final month = _monthNumber(parts[1]);
    if (day == null || month == null) {
      return null;
    }

    return (day, month);
  }

  static int _daysUntil((int, int) date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(now.year, date.$2, date.$1);
    if (next.isBefore(today)) {
      next = DateTime(now.year + 1, date.$2, date.$1);
    }
    return next.difference(today).inDays;
  }

  static String _shortDateLabel((int, int) date) {
    return '${date.$1} ${_monthShortName(date.$2)}';
  }

  static String _monthShortName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  static int? _monthNumber(String value) {
    return const {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    }[value.trim().toLowerCase()];
  }
}

class _HomeSlamPeople extends StatelessWidget {
  const _HomeSlamPeople({
    required this.fallbackFriends,
    required this.userId,
    required this.onOpenMySlam,
    required this.onCreateSlam,
  });

  final List<SlamFriend> fallbackFriends;
  final String? userId;
  final VoidCallback onOpenMySlam;
  final VoidCallback onCreateSlam;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return _HomeSlamPeopleRow(
        slams: fallbackFriends.take(4).map(_fallbackSlamFromFriend).toList(),
        onFallbackTap: onOpenMySlam,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SlamFirestoreService.instance.watchSlamsForUser(userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 106,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return _HomeSlamPeopleRow(
            slams: fallbackFriends
                .take(4)
                .map(_fallbackSlamFromFriend)
                .toList(),
            onFallbackTap: onOpenMySlam,
          );
        }

        final slams =
            snapshot.data?.docs.take(4).map(_homeSlamFromDoc).toList() ?? [];
        if (slams.isEmpty) {
          return _HomeEmptyStateCard(
            icon: Icons.auto_stories_outlined,
            title: 'No slams yet',
            message: 'Start with one person you want to remember.',
            actionLabel: 'Add',
            onActionTap: onCreateSlam,
          );
        }

        return _HomeSlamPeopleRow(slams: slams, onFallbackTap: onOpenMySlam);
      },
    );
  }

  static _HomeSlamItem _homeSlamFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final fullName = _stringValue(data['fullName'], fallback: 'Untitled Slam');
    final nickname = _stringValue(data['nickname']);
    final relation = _stringValue(data['relation'], fallback: nickname);
    final photoUrl = _stringValue(data['photoUrl']);
    final localPhotoPath = _stringValue(data['localPhotoPath']);

    return _HomeSlamItem(
      person: MySlamPerson(
        id: doc.id,
        friend: SlamFriend(
          name: fullName,
          colors: const [Color(0xFFFFD8C8), Color(0xFFBF4C3C)],
          hairColor: const Color(0xFF4B2C21),
        ),
        fullName: fullName,
        relation: relation.isEmpty ? 'My Slam' : relation,
        date: _shortDate(_stringValue(data['dateOfBirth'])),
        memories: _intValue(data['photoCount']),
        photoUrl: photoUrl,
        localPhotoPath: localPhotoPath,
        favorite: data['favorite'] == true,
      ),
      fallbackOnly: false,
    );
  }

  static _HomeSlamItem _fallbackSlamFromFriend(SlamFriend friend) {
    return _HomeSlamItem(
      person: MySlamPerson(
        friend: friend,
        fullName: friend.name,
        relation: 'My Slam',
        date: 'No date',
        memories: 0,
      ),
      fallbackOnly: true,
    );
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  static String _shortDate(String value) {
    final parts = value.split(' ');
    if (parts.length >= 2) {
      return '${parts[0]} ${parts[1]}';
    }
    return value.isEmpty ? 'No date' : value;
  }
}

class _HomeSlamPeopleRow extends StatelessWidget {
  const _HomeSlamPeopleRow({required this.slams, required this.onFallbackTap});

  final List<_HomeSlamItem> slams;
  final VoidCallback onFallbackTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: slams.length,
        separatorBuilder: (_, _) => const SizedBox(width: 22),
        itemBuilder: (context, index) {
          final item = slams[index];
          return SizedBox(
            width: 74,
            child: _HomeSlamPerson(
              item: item,
              onTap: item.fallbackOnly
                  ? onFallbackTap
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              MySlamDetailScreen(person: item.person),
                        ),
                      );
                    },
            ),
          );
        },
      ),
    );
  }
}

class _HomeSlamPerson extends StatelessWidget {
  const _HomeSlamPerson({required this.item, required this.onTap});

  final _HomeSlamItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final person = item.person;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            PersonAvatar(
              friend: person.friend,
              size: 72,
              photoUrl: person.photoUrl,
              localPhotoPath: person.localPhotoPath,
            ),
            const SizedBox(height: 12),
            Text(
              person.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSlamItem {
  const _HomeSlamItem({required this.person, required this.fallbackOnly});

  final MySlamPerson person;
  final bool fallbackOnly;
}

const _quickIdeasTextSoft = Color(0xFF2B4774);
const _quickIdeasTextMuted = Color(0xFF74819A);
const _quickIdeasSoftFill = Color(0xFFFFFCF8);

class _QuickIdeasCard extends StatelessWidget {
  const _QuickIdeasCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openQuickIdeasSheet(context),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border.withValues(alpha: .48)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .06),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.peach.withValues(alpha: .32),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.coralDark,
                  size: 27,
                ),
              ),
              14.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Ideas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _quickIdeasTextSoft,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    4.h,
                    Text(
                      'Get gift and message ideas without creating a slam.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _quickIdeasTextMuted,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _quickIdeasTextSoft.withValues(alpha: .72),
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuickIdeasSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => const _QuickIdeasSheet(),
    );
  }
}

class _QuickIdeasSheet extends StatefulWidget {
  const _QuickIdeasSheet();

  @override
  State<_QuickIdeasSheet> createState() => _QuickIdeasSheetState();
}

class _QuickIdeasSheetState extends State<_QuickIdeasSheet> {
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _dateController = TextEditingController();
  String _occasion = 'Birthday';
  String? _gender;

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  bool get _showsDateField => _occasion == 'Birthday';

  String get _dateLabel => 'Date of Birth';

  String get _dateHint => 'Select DOB';

  IconData get _dateIcon => Icons.cake_outlined;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) {
      return;
    }

    _dateController.text = _formatDate(selected);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _openIdeas({required bool giftIdeas}) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.coral,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text('Please add a name first.'),
        ),
      );
      return;
    }

    final relation = _relationController.text.trim();
    final gender = _gender?.trim();
    final occasionDate = _occasion == 'Birthday'
        ? _dateController.text.trim()
        : '';
    unawaited(
      AnalyticsService.instance.quickIdeasSubmitted(
        type: giftIdeas ? 'gift' : 'message',
        occasion: _occasion,
        gender: gender,
      ),
    );
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => giftIdeas
            ? GiftIdeasScreen(
                friendName: name,
                relation: relation.isEmpty ? null : relation,
                gender: gender == null || gender.isEmpty ? null : gender,
                occasion: _occasion,
                occasionDate: occasionDate.isEmpty ? null : occasionDate,
                source: 'quick_ideas',
              )
            : MessageIdeasScreen(
                friendName: name,
                relation: relation.isEmpty ? null : relation,
                gender: gender == null || gender.isEmpty ? null : gender,
                occasion: _occasion.toLowerCase(),
                occasionDate: occasionDate.isEmpty ? null : occasionDate,
                source: 'quick_ideas',
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            18.h,
            Text(
              'Quick Ideas',
              style: AppTextTheme.memoryTitle.copyWith(
                color: _quickIdeasTextSoft,
                fontSize: 30,
                height: 1,
              ),
            ),
            8.h,
            Text(
              'Add a few details and get ideas right away.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _quickIdeasTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            18.h,
            _QuickIdeasField(
              controller: _nameController,
              label: 'Name',
              hintText: 'E.g. Neha',
              icon: Icons.person_outline_rounded,
            ),
            12.h,
            _QuickIdeasField(
              controller: _relationController,
              label: 'Relation',
              hintText: 'E.g. Friend, cousin, brother',
              icon: Icons.favorite_border_rounded,
            ),
            16.h,
            Text(
              'Gender',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _quickIdeasTextSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            10.h,
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final gender in const ['Male', 'Female'])
                  ChoiceChip(
                    label: Text(gender),
                    selected: _gender == gender,
                    showCheckmark: true,
                    checkmarkColor: AppColors.surface,
                    onSelected: (selected) => setState(() {
                      _gender = selected ? gender : null;
                    }),
                    selectedColor: AppColors.primary,
                    backgroundColor: _quickIdeasSoftFill,
                    labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _gender == gender
                          ? Colors.white
                          : _quickIdeasTextSoft,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _gender == gender
                          ? AppColors.primary
                          : AppColors.border.withValues(alpha: .64),
                    ),
                  ),
              ],
            ),
            16.h,
            Text(
              'Occasion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _quickIdeasTextSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            10.h,
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final occasion in const [
                  'Birthday',
                  'Anniversary',
                  'Just because',
                ])
                  ChoiceChip(
                    label: Text(occasion),
                    selected: _occasion == occasion,
                    showCheckmark: true,
                    checkmarkColor: AppColors.surface,
                    onSelected: (_) => setState(() {
                      _occasion = occasion;
                      _dateController.clear();
                    }),
                    selectedColor: AppColors.primary,
                    backgroundColor: _quickIdeasSoftFill,
                    labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _occasion == occasion
                          ? Colors.white
                          : _quickIdeasTextSoft,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _occasion == occasion
                          ? AppColors.primary
                          : AppColors.border.withValues(alpha: .64),
                    ),
                  ),
              ],
            ),
            if (_showsDateField) ...[
              12.h,
              _QuickIdeasField(
                controller: _dateController,
                label: _dateLabel,
                hintText: _dateHint,
                icon: _dateIcon,
                readOnly: true,
                onTap: _pickDate,
              ),
            ],
            22.h,
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openIdeas(giftIdeas: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      textStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Gift Ideas ✨'),
                  ),
                ),
                10.w,
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openIdeas(giftIdeas: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _quickIdeasTextSoft,
                      minimumSize: const Size.fromHeight(48),
                      textStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: .72),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    child: const Text('Messages ✨'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickIdeasField extends StatelessWidget {
  const _QuickIdeasField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: _quickIdeasTextSoft),
        filled: true,
        fillColor: _quickIdeasSoftFill,
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _quickIdeasTextMuted,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _quickIdeasTextMuted.withValues(alpha: .72),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: .54),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: .54),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: .72),
            width: 1.2,
          ),
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: _quickIdeasTextSoft,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _WhatsappInviteCard extends StatelessWidget {
  const _WhatsappInviteCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          unawaited(AnalyticsService.instance.inviteFriendClicked());
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const InviteFriendScreen()),
          );
        },
        child: Ink(
          padding: const EdgeInsets.fromLTRB(24, 18, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF2BC765),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              20.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite a Friend',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Share your unique link\nvia WhatsApp',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
