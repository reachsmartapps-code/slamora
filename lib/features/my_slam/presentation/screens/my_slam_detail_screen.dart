import 'dart:async';

import 'package:flutter/material.dart';
import 'package:slamora/core/extensions/spacing_extensions.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_theme.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/reminder_notification_service.dart';
import '../../../../core/services/slam_firestore_service.dart';
import '../../../home/presentation/widgets/person_avatar.dart';
import '../../../ideas/presentation/screens/gift_ideas_screen.dart';
import '../../../ideas/presentation/screens/message_ideas_screen.dart';
import '../widgets/my_slam_person_card.dart';

const _detailTextSoft = Color(0xFF2B4774);
const _detailTextMuted = Color(0xFF74819A);
const _detailChipBackground = Color(0xFFF2F6FF);

class MySlamDetailScreen extends StatelessWidget {
  const MySlamDetailScreen({required this.person, super.key});

  final MySlamPerson person;

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.instance.currentUser?.uid;
    final slamId = person.id;

    if (userId != null && slamId != null && slamId.isNotEmpty) {
      return FutureBuilder<Map<String, Object?>>(
        future: SlamFirestoreService.instance.getSlamDetail(
          ownerUserId: userId,
          slamId: slamId,
        ),
        builder: (context, snapshot) {
          final detail = _SlamDetailData.fromSnapshot(
            person: person,
            snapshot: snapshot.data,
          );

          return _DetailScaffold(
            detail: detail,
            isLoading: snapshot.connectionState == ConnectionState.waiting,
          );
        },
      );
    }

    return _DetailScaffold(detail: _SlamDetailData.fromPerson(person));
  }
}

class _DetailScaffold extends StatefulWidget {
  const _DetailScaffold({required this.detail, this.isLoading = false});

  final _SlamDetailData detail;
  final bool isLoading;

  @override
  State<_DetailScaffold> createState() => _DetailScaffoldState();
}

class _DetailScaffoldState extends State<_DetailScaffold> {
  final _overviewKey = GlobalKey();
  final _preferencesKey = GlobalKey();
  final _memoriesKey = GlobalKey();
  final _photosKey = GlobalKey();
  bool _isDeleting = false;

  Future<void> _confirmDeleteSlam() async {
    final slamId = widget.detail.person.id;
    final userId = AuthService.instance.currentUser?.uid;
    if (_isDeleting || slamId == null || slamId.isEmpty || userId == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete slam?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _detailTextSoft,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently delete this slam and its memory photos.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: _detailTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        //actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await ReminderNotificationService.instance.cancelReminder(
        slamId: slamId,
        reminderType: 'birthday',
      );
      await ReminderNotificationService.instance.cancelReminder(
        slamId: slamId,
        reminderType: 'anniversary',
      );
      await SlamFirestoreService.instance.deleteSlam(
        ownerUserId: userId,
        slamId: slamId,
      );

      if (!mounted) {
        return;
      }
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text('Slam deleted'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.coral,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text('Could not delete slam. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 390 ? 14.0 : 18.0;
    final detail = widget.detail;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppColors.primary,
          iconSize: 34,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        ),
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Slamora',
            style: AppTextTheme.memoryTitle.copyWith(
              color: AppColors.primary,
              fontSize: 34,
              height: 1,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<_SlamDetailMenuAction>(
            tooltip: 'More',
            color: AppColors.surface,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            position: PopupMenuPosition.under,
            onSelected: (action) {
              if (action == _SlamDetailMenuAction.delete) {
                _confirmDeleteSlam;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _SlamDetailMenuAction.delete,
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.coral,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Delete slam',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.coral,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.more_horiz_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
          ),
          10.w,
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            12,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _ProfileHero(detail: detail),
                          const SizedBox(height: 16),
                          _MilestoneCards(detail: detail),
                          const SizedBox(height: 14),
                          _ReminderSection(detail: detail),
                          const SizedBox(height: 14),
                          KeyedSubtree(
                            key: _overviewKey,
                            child: _AboutSection(detail: detail),
                          ),
                          const SizedBox(height: 14),
                          KeyedSubtree(
                            key: _preferencesKey,
                            child: _PreferencesSection(detail: detail),
                          ),
                          const SizedBox(height: 14),
                          KeyedSubtree(
                            key: _memoriesKey,
                            child: _MemoriesSection(detail: detail),
                          ),
                          if (detail.photoUrls.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            KeyedSubtree(
                              key: _photosKey,
                              child: _MomentsSection(detail: detail),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  10.h,
                  _DetailActions(detail: detail),
                ],
              ),

              if (widget.isLoading) ...[
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: const _LoadingGlowIndicator(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SlamDetailData {
  const _SlamDetailData({
    required this.person,
    required this.fullName,
    required this.nickname,
    required this.relation,
    required this.gender,
    required this.dateOfBirth,
    required this.anniversary,
    required this.interests,
    required this.favourites,
    required this.memories,
    required this.photoUrls,
    required this.reminders,
  });

  final MySlamPerson person;
  final String fullName;
  final String nickname;
  final String relation;
  final String gender;
  final String dateOfBirth;
  final String anniversary;
  final List<String> interests;
  final Map<String, String> favourites;
  final Map<String, String> memories;
  final List<String> photoUrls;
  final Map<String, _ReminderSetting> reminders;

  String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return 'Slam';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get displayRelation => relation.isEmpty ? person.relation : relation;

  static _SlamDetailData fromPerson(MySlamPerson person) {
    return _SlamDetailData(
      person: person,
      fullName: person.fullName,
      nickname: person.relation == 'My Slam' ? '' : person.relation,
      relation: person.relation == 'My Slam' ? '' : person.relation,
      gender: '',
      dateOfBirth: person.date,
      anniversary: '',
      interests: const ['Travel', 'Photography', 'Music', 'Reading'],
      favourites: const {
        'food': 'Pasta',
        'colour': 'Peach',
        'movieOrSeries': 'Interstellar',
        'dreamDestination': 'Switzerland',
        'giftPreference': 'Personalized / Useful',
        'style': 'Casual / Minimal',
      },
      memories: const {
        'moment': 'Our Goa trip was unforgettable.',
        'compliment': 'You always make everyone feel comfortable.',
        'message': 'Thank you for being part of my memories.',
      },
      photoUrls: const [],
      reminders: const {},
    );
  }

  static _SlamDetailData fromSnapshot({
    required MySlamPerson person,
    required Map<String, Object?>? snapshot,
  }) {
    final slam = _mapValue(snapshot?['slam']);
    final sections = _mapValue(snapshot?['sections']);
    final about = _mapValue(sections['about']);
    final interests = _mapValue(sections['interests']);
    final favourites = _mapValue(sections['favourites']);
    final memories = _mapValue(sections['memories']);
    final photos = _mapValue(sections['photos']);
    final reminders = _mapValue(slam['reminders']);
    final relation = _stringValue(
      about['relation'] ?? slam['relation'],
      fallback: person.relation == 'My Slam' ? '' : person.relation,
    );

    final photoUrls = _stringList(slam['memoryPhotoUrls']);
    final sectionPhotoUrls = _stringList(photos['urls']);

    return _SlamDetailData(
      person: MySlamPerson(
        id: person.id,
        friend: person.friend,
        fullName: _stringValue(
          about['fullName'] ?? slam['fullName'],
          fallback: person.fullName,
        ),
        relation: _stringValue(
          about['relation'] ?? slam['relation'],
          fallback: relation.isEmpty ? person.relation : relation,
        ),
        date: _shortDate(
          _stringValue(
            about['dateOfBirth'] ?? slam['dateOfBirth'],
            fallback: person.date,
          ),
        ),
        memories: _intValue(slam['photoCount'], fallback: person.memories),
        photoUrl: _stringValue(
          slam['photoUrl'],
          fallback: person.photoUrl ?? '',
        ),
        localPhotoPath: person.localPhotoPath,
        favorite: person.favorite,
      ),
      fullName: _stringValue(
        about['fullName'] ?? slam['fullName'],
        fallback: person.fullName,
      ),
      nickname: _stringValue(about['nickname'] ?? slam['nickname']),
      relation: relation,
      gender: _stringValue(about['gender'] ?? slam['gender']),
      dateOfBirth: _stringValue(
        about['dateOfBirth'] ?? slam['dateOfBirth'],
        fallback: person.date,
      ),
      anniversary: _stringValue(about['anniversary'] ?? slam['anniversary']),
      interests: _stringList(interests['values']),
      favourites: {
        'food': _stringValue(favourites['food']),
        'colour': _stringValue(favourites['colour']),
        'movieOrSeries': _stringValue(favourites['movieOrSeries']),
        'brand': _stringValue(favourites['brand']),
        'dreamDestination': _stringValue(favourites['dreamDestination']),
      },
      memories: {
        'moment': _stringValue(memories['moment']),
        'compliment': _stringValue(memories['compliment']),
        'message': _stringValue(memories['message']),
      },
      photoUrls: photoUrls.isNotEmpty ? photoUrls : sectionPhotoUrls,
      reminders: {
        'birthday': _ReminderSetting.fromMap(_mapValue(reminders['birthday'])),
        'anniversary': _ReminderSetting.fromMap(
          _mapValue(reminders['anniversary']),
        ),
      },
    );
  }

  static Map<String, Object?> _mapValue(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) {
      return const [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static int _intValue(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  static String _shortDate(String value) {
    final parts = value.split(' ');
    if (parts.length >= 2) {
      return '${parts[0]} ${parts[1]}';
    }
    return value.isEmpty ? 'No date' : value;
  }
}

enum _SlamDetailMenuAction { delete }

class _LoadingGlowIndicator extends StatelessWidget {
  const _LoadingGlowIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: .88),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.peach.withValues(alpha: .58)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading details..',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.detail});

  final _SlamDetailData detail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final avatarSize = compact ? 122.0 : 134.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 18,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: PersonAvatar(
                    friend: detail.person.friend,
                    size: avatarSize - 10,
                    showBorder: false,
                    photoUrl: detail.person.photoUrl,
                    localPhotoPath: detail.person.localPhotoPath,
                  ),
                ),
                /*Positioned(
                  right: compact ? -2 : -8,
                  top: compact ? 20 : 18,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.coral,
                      size: 28,
                    ),
                  ),
                ),*/
              ],
            ),
            SizedBox(width: compact ? 16 : 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 24 : 28,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail.displayRelation,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (!compact) const SizedBox(width: 12),
            if (!compact) const _MemoryNote(),
          ],
        );
      },
    );
  }
}

class _MemoryNote extends StatelessWidget {
  const _MemoryNote();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -.18,
      child: Container(
        width: 112,
        height: 112,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.peach.withValues(alpha: .38),
          borderRadius: BorderRadius.circular(42),
        ),
        child: Text(
          'More\nmemories\nwith you ♡',
          textAlign: TextAlign.center,
          style: AppTextTheme.memoryTitle.copyWith(
            color: AppColors.primary,
            fontSize: 20,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _MilestoneCards extends StatelessWidget {
  const _MilestoneCards({required this.detail});

  final _SlamDetailData detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MilestoneCard(
            icon: Icons.calendar_month_outlined,
            title: detail.dateOfBirth.isEmpty ? 'No date' : detail.dateOfBirth,
            subtitle: 'Birthday',
            accent: AppColors.coral,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MilestoneCard(
            icon: Icons.favorite_border_rounded,
            title: detail.anniversary.isEmpty
                ? 'Not added'
                : detail.anniversary,
            subtitle: 'Anniversary',
            accent: AppColors.coral,
          ),
        ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: .72)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _detailTextSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _detailTextMuted,
                    fontWeight: FontWeight.w500,
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

class _ReminderSetting {
  const _ReminderSetting({
    required this.enabled,
    required this.remindBeforeDays,
  });

  final bool enabled;
  final int remindBeforeDays;

  static const off = _ReminderSetting(enabled: false, remindBeforeDays: 1);

  String get label {
    if (!enabled) {
      return 'Set reminder';
    }
    if (remindBeforeDays == 0) {
      return 'On the day';
    }
    if (remindBeforeDays == 1) {
      return '1 day before';
    }
    return '$remindBeforeDays days before';
  }

  static _ReminderSetting fromMap(Map<String, Object?> data) {
    final days = data['remindBeforeDays'];
    return _ReminderSetting(
      enabled: data['enabled'] == true,
      remindBeforeDays: days is num ? days.toInt() : 1,
    );
  }
}

class _ReminderSection extends StatefulWidget {
  const _ReminderSection({required this.detail});

  final _SlamDetailData detail;

  @override
  State<_ReminderSection> createState() => _ReminderSectionState();
}

class _ReminderSectionState extends State<_ReminderSection> {
  late _ReminderSetting _birthdayReminder;
  late _ReminderSetting _anniversaryReminder;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _syncReminderState();
  }

  @override
  void didUpdateWidget(covariant _ReminderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _syncReminderState();
    }
  }

  void _syncReminderState() {
    _birthdayReminder =
        widget.detail.reminders['birthday'] ?? _ReminderSetting.off;
    _anniversaryReminder =
        widget.detail.reminders['anniversary'] ?? _ReminderSetting.off;
  }

  Future<void> _openReminderSheet({
    required String type,
    required String title,
    required String eventDate,
    required _ReminderSetting current,
  }) async {
    final selected = await showModalBottomSheet<_ReminderSetting>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) =>
          _ReminderBottomSheet(title: title, current: current),
    );

    if (selected == null || !mounted) {
      return;
    }

    final previousBirthdayReminder = _birthdayReminder;
    final previousAnniversaryReminder = _anniversaryReminder;

    setState(() {
      _isUpdating = true;
      if (type == 'birthday') {
        _birthdayReminder = selected;
      } else {
        _anniversaryReminder = selected;
      }
    });

    try {
      final userId = AuthService.instance.currentUser?.uid;
      final slamId = widget.detail.person.id;
      if (userId != null && slamId != null && slamId.isNotEmpty) {
        await SlamFirestoreService.instance.updateSlamReminder(
          ownerUserId: userId,
          slamId: slamId,
          reminderType: type,
          enabled: selected.enabled,
          remindBeforeDays: selected.remindBeforeDays,
          eventDate: eventDate,
        );
        if (selected.enabled) {
          await ReminderNotificationService.instance.scheduleReminder(
            ownerUserId: userId,
            slamId: slamId,
            reminderType: type,
            friendName: widget.detail.fullName,
            eventDate: eventDate,
            remindBeforeDays: selected.remindBeforeDays,
          );
          unawaited(AnalyticsService.instance.reminderSet(type: type));
        } else {
          await ReminderNotificationService.instance.cancelReminder(
            slamId: slamId,
            reminderType: type,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _birthdayReminder = previousBirthdayReminder;
          _anniversaryReminder = previousAnniversaryReminder;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.coral,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Text('Could not update reminder. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBirthday = widget.detail.dateOfBirth.trim().isNotEmpty;
    final hasAnniversary = widget.detail.anniversary.trim().isNotEmpty;

    if (!hasBirthday && !hasAnniversary) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      icon: Icons.notifications_active_outlined,
      title: 'Reminders',
      iconColor: AppColors.coral,
      child: Column(
        children: [
          if (hasBirthday)
            _ReminderTile(
              icon: Icons.cake_outlined,
              title: 'Birthday reminder',
              subtitle: _birthdayReminder.label,
              enabled: _birthdayReminder.enabled,
              isUpdating: _isUpdating,
              onTap: () => _openReminderSheet(
                type: 'birthday',
                title: 'Birthday reminder',
                eventDate: widget.detail.dateOfBirth,
                current: _birthdayReminder,
              ),
            ),
          if (hasBirthday && hasAnniversary)
            const Divider(height: 18, color: AppColors.divider),
          if (hasAnniversary)
            _ReminderTile(
              icon: Icons.favorite_border_rounded,
              title: 'Anniversary reminder',
              subtitle: _anniversaryReminder.label,
              enabled: _anniversaryReminder.enabled,
              isUpdating: _isUpdating,
              onTap: () => _openReminderSheet(
                type: 'anniversary',
                title: 'Anniversary reminder',
                eventDate: widget.detail.anniversary,
                current: _anniversaryReminder,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.isUpdating,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool isUpdating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUpdating ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.peach.withValues(alpha: .55)
                    : AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: enabled ? AppColors.coral : AppColors.primary,
              ),
            ),
            12.w,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _detailTextSoft,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  2.h,
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _detailTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isUpdating)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(
                enabled
                    ? Icons.notifications_active_rounded
                    : Icons.add_circle_outline_rounded,
                color: enabled ? AppColors.coral : AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _ReminderBottomSheet extends StatelessWidget {
  const _ReminderBottomSheet({required this.title, required this.current});

  final String title;
  final _ReminderSetting current;

  @override
  Widget build(BuildContext context) {
    final options = const [
      _ReminderSetting(enabled: false, remindBeforeDays: 1),
      _ReminderSetting(enabled: true, remindBeforeDays: 0),
      _ReminderSetting(enabled: true, remindBeforeDays: 1),
      _ReminderSetting(enabled: true, remindBeforeDays: 3),
      _ReminderSetting(enabled: true, remindBeforeDays: 7),
    ];

    final maxHeight = MediaQuery.sizeOf(context).height * .72;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
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
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _detailTextSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              for (final option in options)
                _ReminderOptionTile(
                  setting: option,
                  selected:
                      option.enabled == current.enabled &&
                      option.remindBeforeDays == current.remindBeforeDays,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderOptionTile extends StatelessWidget {
  const _ReminderOptionTile({required this.setting, required this.selected});

  final _ReminderSetting setting;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final label = setting.enabled ? setting.label : 'Off';

    return ListTile(
      onTap: () => Navigator.of(context).pop(setting),
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(
        setting.enabled
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
        color: selected ? AppColors.coral : AppColors.primary,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: _detailTextSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.coral)
          : null,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: .72)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _detailTextSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.detail});

  final _SlamDetailData detail;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.person_rounded,
      title: 'About ${detail.firstName}',
      child: Row(
        children: [
          Expanded(
            child: _SmallInfo(
              icon: Icons.local_offer_outlined,
              label: 'Nickname',
              value: detail.nickname.isEmpty ? 'Not added' : detail.nickname,
            ),
          ),
          const SizedBox(
            height: 50,
            child: VerticalDivider(color: AppColors.divider),
          ),
          Expanded(
            child: _SmallInfo(
              icon: Icons.favorite_border_rounded,
              label: 'Relation',
              value: detail.displayRelation.isEmpty
                  ? 'Not added'
                  : detail.displayRelation,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  const _SmallInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _detailTextSoft, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _detailTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              4.h,
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _detailTextSoft,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection({required this.detail});

  final _SlamDetailData detail;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.auto_awesome_rounded,
      title: 'Interests & Preferences',
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final interest
                    in detail.interests.isEmpty
                        ? const ['No interests added']
                        : detail.interests)
                  _InterestChip(
                    icon: _interestIconFor(interest),
                    label: interest,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth > 360;
              final items = [
                _PreferenceItem(
                  icon: Icons.checkroom_outlined,
                  label: 'Favourite Movie',
                  value: _valueOrFallback(
                    detail.favourites['movieOrSeries'],
                    'Not added',
                  ),
                ),
                _PreferenceItem(
                  icon: Icons.flight_rounded,
                  label: 'Dream Destination',
                  value: _valueOrFallback(
                    detail.favourites['dreamDestination'],
                    'Not added',
                  ),
                ),
                _PreferenceItem(
                  icon: Icons.restaurant_rounded,
                  label: 'Favourite Food',
                  value: _valueOrFallback(
                    detail.favourites['food'],
                    'Not added',
                  ),
                ),
                _PreferenceItem(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Favourite Brand',
                  value: _valueOrFallback(
                    detail.favourites['brand'],
                    'Not added',
                  ),
                ),
                _PreferenceItem(
                  icon: Icons.palette_outlined,
                  label: 'Favourite Colour',
                  value: _valueOrFallback(
                    detail.favourites['colour'],
                    'Not added',
                  ),
                ),
              ];

              if (!twoColumns) {
                return Column(children: items);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(children: items.take(3).toList())),
                  const SizedBox(
                    height: 96,
                    child: VerticalDivider(color: AppColors.divider),
                  ),
                  Expanded(child: Column(children: items.skip(3).toList())),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _valueOrFallback(String? value, String fallback) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static IconData _interestIconFor(String interest) {
    final normalized = interest.toLowerCase();
    if (normalized.contains('travel')) return Icons.flight_rounded;
    if (normalized.contains('photo')) return Icons.camera_alt_outlined;
    if (normalized.contains('music')) return Icons.music_note_rounded;
    if (normalized.contains('read')) return Icons.menu_book_outlined;
    if (normalized.contains('sport')) return Icons.sports_cricket_rounded;
    if (normalized.contains('movie')) return Icons.movie_outlined;
    if (normalized.contains('food') || normalized.contains('cook')) {
      return Icons.restaurant_rounded;
    }
    return Icons.auto_awesome_rounded;
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _detailChipBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: _detailTextSoft, size: 19),
          8.w,
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _detailTextSoft,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceItem extends StatelessWidget {
  const _PreferenceItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _detailTextSoft, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _detailTextMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _detailTextSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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

class _MemoriesSection extends StatelessWidget {
  const _MemoriesSection({required this.detail});

  final _SlamDetailData detail;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.favorite_rounded,
      iconColor: AppColors.coral,
      title: 'Our Memories',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _MemoryNoteCard(
                text: _quote(detail.memories['moment'], 'No memory added yet.'),
                author: '- ${detail.firstName}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MemoryNoteCard(
                text: _quote(
                  detail.memories['compliment'] ?? detail.memories['message'],
                  'No message added yet.',
                ),
                author: '- ${detail.firstName}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _quote(String? value, String fallback) {
    final text = value?.trim() ?? '';
    return '“ ${text.isEmpty ? fallback : text} ”';
  }
}

class _MemoryNoteCard extends StatelessWidget {
  const _MemoryNoteCard({required this.text, required this.author});

  final String text;
  final String author;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: .58)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextTheme.memoryTitle.copyWith(
              color: _detailTextSoft,
              fontSize: 19,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(
                Icons.favorite_border_rounded,
                color: AppColors.coral,
                size: 18,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w600,
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

class _MomentsSection extends StatelessWidget {
  const _MomentsSection({required this.detail});

  final _SlamDetailData detail;

  @override
  Widget build(BuildContext context) {
    final photoUrls = detail.photoUrls.take(3).toList();

    return _SectionCard(
      icon: Icons.image_outlined,
      title: 'Recent Moments',
      child: Row(
        children: [
          for (var i = 0; i < photoUrls.length; i += 1) ...[
            Expanded(
              child: _MomentThumb(
                imageUrl: photoUrls[i],
                onTap: () => _openPhotoViewer(context, photoUrls, i),
              ),
            ),
            if (i != photoUrls.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  void _openPhotoViewer(
    BuildContext context,
    List<String> photoUrls,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _RecentMomentsViewer(
          photoUrls: photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _MomentThumb extends StatelessWidget {
  const _MomentThumb({required this.imageUrl, required this.onTap});

  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1.34,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                );
              },
              errorBuilder: (_, _, _) => const ColoredBox(
                color: AppColors.surfaceWarm,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentMomentsViewer extends StatefulWidget {
  const _RecentMomentsViewer({
    required this.photoUrls,
    required this.initialIndex,
  });

  final List<String> photoUrls;
  final int initialIndex;

  @override
  State<_RecentMomentsViewer> createState() => _RecentMomentsViewerState();
}

class _RecentMomentsViewerState extends State<_RecentMomentsViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photoUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 3.5,
                    child: Image.network(
                      widget.photoUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 42,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.photoUrls.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailActions extends StatelessWidget {
  const _DetailActions({required this.detail});

  final _SlamDetailData detail;

  List<_SlamIdeaOccasion> get _availableOccasions {
    final occasions = <_SlamIdeaOccasion>[];
    final birthday = detail.dateOfBirth.trim();
    final anniversary = detail.anniversary.trim();

    if (birthday.isNotEmpty) {
      occasions.add(
        _SlamIdeaOccasion(
          title: 'Birthday',
          apiValue: 'Birthday',
          date: birthday,
          icon: Icons.cake_outlined,
        ),
      );
    }

    if (anniversary.isNotEmpty) {
      occasions.add(
        _SlamIdeaOccasion(
          title: 'Anniversary',
          apiValue: 'Anniversary',
          date: anniversary,
          icon: Icons.favorite_border_rounded,
        ),
      );
    }

    return occasions;
  }

  Future<_SlamIdeaOccasion?> _resolveOccasion(BuildContext context) async {
    final occasions = _availableOccasions;
    if (occasions.length == 1) {
      return occasions.first;
    }

    if (occasions.isEmpty) {
      return const _SlamIdeaOccasion(
        title: 'Birthday',
        apiValue: 'Birthday',
        date: null,
        icon: Icons.cake_outlined,
      );
    }

    return showModalBottomSheet<_SlamIdeaOccasion>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _OccasionPickerSheet(occasions: occasions),
    );
  }

  Future<void> _openGiftIdeas(BuildContext context) async {
    final occasion = await _resolveOccasion(context);
    if (occasion == null || !context.mounted) {
      return;
    }

    final relation = detail.displayRelation == 'My Slam'
        ? null
        : detail.displayRelation;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GiftIdeasScreen(
          friendName: detail.fullName,
          relation: relation,
          gender: detail.gender,
          occasion: occasion.apiValue,
          occasionDate: occasion.date,
          interests: detail.interests,
          favoriteColor: detail.favourites['colour'],
          source: 'slam_detail',
        ),
      ),
    );
  }

  Future<void> _openMessageIdeas(BuildContext context) async {
    final occasion = await _resolveOccasion(context);
    if (occasion == null || !context.mounted) {
      return;
    }

    final relation = detail.displayRelation == 'My Slam'
        ? null
        : detail.displayRelation;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MessageIdeasScreen(
          friendName: detail.fullName,
          relation: relation,
          gender: detail.gender,
          occasion: occasion.apiValue,
          occasionDate: occasion.date,
          interests: detail.interests,
          favoriteColor: detail.favourites['colour'],
          source: 'slam_detail',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () => _openGiftIdeas(context),
              label: Text(
                'Find Gift Ideas ✨',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 45,
            child: OutlinedButton.icon(
              onPressed: () => _openMessageIdeas(context),

              label: Text(
                'Message Ideas ✨',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.normal,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SlamIdeaOccasion {
  const _SlamIdeaOccasion({
    required this.title,
    required this.apiValue,
    required this.date,
    required this.icon,
  });

  final String title;
  final String apiValue;
  final String? date;
  final IconData icon;
}

class _OccasionPickerSheet extends StatelessWidget {
  const _OccasionPickerSheet({required this.occasions});

  final List<_SlamIdeaOccasion> occasions;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, 14, 18, 16 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
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
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          18.h,
          Text(
            'Choose occasion',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _detailTextSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          6.h,
          Text(
            'We will use this to make the ideas more personal.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _detailTextMuted,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          16.h,
          for (final occasion in occasions) ...[
            _OccasionPickerTile(occasion: occasion),
            10.h,
          ],
        ],
      ),
    );
  }
}

class _OccasionPickerTile extends StatelessWidget {
  const _OccasionPickerTile({required this.occasion});

  final _SlamIdeaOccasion occasion;

  @override
  Widget build(BuildContext context) {
    final date = occasion.date?.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).pop(occasion),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(occasion.icon, color: AppColors.coral, size: 23),
            ),
            12.w,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    occasion.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _detailTextSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (date != null && date.isNotEmpty) ...[
                    2.h,
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _detailTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
