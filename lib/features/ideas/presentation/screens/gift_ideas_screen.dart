import 'dart:async';

import 'package:flutter/material.dart';
import 'package:slamora/core/extensions/spacing_extensions.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/analytics_service.dart';
import '../../data/idea_models.dart';
import '../../data/ideas_api_service.dart';
import '../../data/ideas_request.dart';
import '../widgets/idea_widgets.dart';

class GiftIdeasScreen extends StatefulWidget {
  const GiftIdeasScreen({
    required this.friendName,
    this.relation,
    this.gender,
    this.occasion = 'Birthday',
    this.occasionDate,
    this.interests = const [],
    this.favoriteColor,
    this.source = 'unknown',
    super.key,
  });

  final String friendName;
  final String? relation;
  final String? gender;
  final String occasion;
  final String? occasionDate;
  final List<String> interests;
  final String? favoriteColor;
  final String source;

  @override
  State<GiftIdeasScreen> createState() => _GiftIdeasScreenState();
}

class _GiftIdeasScreenState extends State<GiftIdeasScreen> {
  late Future<List<GiftIdea>> _giftIdeasFuture;

  @override
  void initState() {
    super.initState();
    _giftIdeasFuture = _fetchGiftIdeas();
  }

  Future<List<GiftIdea>> _fetchGiftIdeas() async {
    final ideas = await IdeasApiService.instance.fetchGiftIdeas(
      IdeasRequest(
        name: widget.friendName,
        dob: widget.occasionDate,
        event: widget.occasion,
        relation: widget.relation,
        gender: widget.gender,
        interests: widget.interests,
        favoriteColor: widget.favoriteColor,
      ),
    );
    await AnalyticsService.instance.giftIdeasLoaded(
      occasion: widget.occasion,
      source: widget.source,
      count: ideas.length,
    );
    return ideas;
  }

  void _retry() {
    setState(() {
      _giftIdeasFuture = _fetchGiftIdeas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final relation = widget.relation?.trim();
    final subtitle = relation == null || relation.isEmpty
        ? '${widget.occasion} ideas that feel personal.'
        : '${widget.occasion} ideas for your $relation.';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppColors.primary,
          iconSize: 34,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gift Ideas',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: ideaTextSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
            2.h,
            Text(
              'Find something thoughtful for ${widget.friendName}.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ideaTextMuted,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              IdeasHeroCard(
                icon: Icons.card_giftcard_rounded,
                title: widget.friendName,
                subtitle: subtitle,
              ),
              20.h,
              const IdeaSectionTitle(title: 'Recommended'),
              10.h,
              FutureBuilder<List<GiftIdea>>(
                future: _giftIdeasFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _IdeasLoadingState(
                      messages: [
                        'Reading their little details...',
                        'Looking for something thoughtful...',
                        'Balancing useful with personal...',
                        'Almost there with a few warm ideas...',
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return _IdeasErrorState(onRetry: _retry);
                  }

                  final suggestions = snapshot.data ?? const <GiftIdea>[];
                  if (suggestions.isEmpty) {
                    return _IdeasEmptyState(onRetry: _retry);
                  }

                  return Column(
                    children: [
                      for (final suggestion in suggestions) ...[
                        _GiftIdeaTile(suggestion: suggestion),
                        10.h,
                      ],
                    ],
                  );
                },
              ),
              10.h,
              _ThoughtfulTip(friendName: widget.friendName),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiftIdeaTile extends StatelessWidget {
  const _GiftIdeaTile({required this.suggestion});

  final GiftIdea suggestion;

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
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                suggestion.icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          12.w,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ideaTextSoft,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.h,
                Text(
                  suggestion.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ideaTextMuted,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
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

class _ThoughtfulTip extends StatelessWidget {
  const _ThoughtfulTip({required this.friendName});

  final String friendName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_rounded, color: AppColors.coral),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add a handwritten note with one specific memory. That small detail will make ${friendName.split(' ').first} remember the gift longer.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ideaTextSoft,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdeasLoadingState extends StatefulWidget {
  const _IdeasLoadingState({required this.messages});

  final List<String> messages;

  @override
  State<_IdeasLoadingState> createState() => _IdeasLoadingStateState();
}

class _IdeasLoadingStateState extends State<_IdeasLoadingState> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.messages.isNotEmpty) {
      _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
        if (!mounted) {
          return;
        }
        setState(() => _index = (_index + 1) % widget.messages.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.messages.isEmpty
        ? 'Finding thoughtful ideas...'
        : widget.messages[_index];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
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
          const AnimatedSlamoraMark(),
          14.h,
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Text(
              message,
              key: ValueKey(message),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ideaTextSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          6.h,
          Text(
            'This usually takes a few seconds.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ideaTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdeasErrorState extends StatelessWidget {
  const _IdeasErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _IdeasStateCard(
      icon: Icons.wifi_off_rounded,
      title: 'Could not load ideas',
      message: 'Please check your connection and try again.',
      onRetry: onRetry,
    );
  }
}

class _IdeasEmptyState extends StatelessWidget {
  const _IdeasEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _IdeasStateCard(
      icon: Icons.card_giftcard_rounded,
      title: 'No ideas found',
      message: 'Try again in a moment.',
      onRetry: onRetry,
    );
  }
}

class _IdeasStateCard extends StatelessWidget {
  const _IdeasStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.coral, size: 30),
          10.h,
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ideaTextSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          4.h,
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ideaTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          12.h,
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
