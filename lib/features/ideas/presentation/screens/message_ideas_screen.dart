import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '/core/extensions/spacing_extensions.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_theme.dart';
import '../../../../core/services/analytics_service.dart';
import '../../data/idea_models.dart';
import '../../data/ideas_api_service.dart';
import '../../data/ideas_request.dart';
import '../widgets/idea_widgets.dart';

class MessageIdeasScreen extends StatefulWidget {
  const MessageIdeasScreen({
    required this.friendName,
    this.relation,
    this.gender,
    this.occasion = 'birthday',
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
  State<MessageIdeasScreen> createState() => _MessageIdeasScreenState();
}

class _MessageIdeasScreenState extends State<MessageIdeasScreen> {
  static const _primaryLanguageOptions = [
    'English',
    'Spanish',
    'French',
    'German',
    'Arabic',
    'Hindi',
    'Hinglish',
  ];

  static const _moreLanguageOptions = [
    'Bengali',
    'Tamil',
    'Telugu',
    'Marathi',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Urdu',
  ];

  late Future<List<MessageIdea>> _messageIdeasFuture;
  String _selectedLanguage = 'English';

  String get _apiLanguage {
    return switch (_selectedLanguage) {
      'Hindi' => 'Hindi in Devanagari script',
      'Bengali' => 'Bengali in Bengali script',
      'Tamil' => 'Tamil in Tamil script',
      'Telugu' => 'Telugu in Telugu script',
      'Marathi' => 'Marathi in Devanagari script',
      'Gujarati' => 'Gujarati in Gujarati script',
      'Kannada' => 'Kannada in Kannada script',
      'Malayalam' => 'Malayalam in Malayalam script',
      'Punjabi' => 'Punjabi in Gurmukhi script',
      'Urdu' => 'Urdu in Urdu script',
      'Arabic' => 'Arabic in Arabic script',
      'Hinglish' => 'Hinglish using English characters',
      _ => _selectedLanguage,
    };
  }

  @override
  void initState() {
    super.initState();
    _messageIdeasFuture = _fetchMessageIdeas();
  }

  Future<List<MessageIdea>> _fetchMessageIdeas() async {
    final ideas = await IdeasApiService.instance.fetchMessageIdeas(
      IdeasRequest(
        name: widget.friendName,
        dob: widget.occasionDate,
        event: widget.occasion,
        relation: widget.relation,
        gender: widget.gender,
        language: _apiLanguage,
        interests: widget.interests,
        favoriteColor: widget.favoriteColor,
      ),
    );
    await AnalyticsService.instance.messageIdeasLoaded(
      occasion: widget.occasion,
      source: widget.source,
      count: ideas.length,
    );
    return ideas;
  }

  void _retry() {
    setState(() {
      _messageIdeasFuture = _fetchMessageIdeas();
    });
  }

  void _changeLanguage(String language) {
    if (language == _selectedLanguage) {
      return;
    }

    setState(() {
      _selectedLanguage = language;
      _messageIdeasFuture = _fetchMessageIdeas();
    });
  }

  Future<void> _openMoreLanguages() async {
    final language = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MoreLanguagesSheet(
        languages: _moreLanguageOptions,
        selectedLanguage: _selectedLanguage,
      ),
    );

    if (language == null || !mounted) {
      return;
    }

    _changeLanguage(language);
  }

  @override
  Widget build(BuildContext context) {
    final relation = widget.relation?.trim();
    final subtitle = relation == null || relation.isEmpty
        ? 'Pick a message style and copy your favourite.'
        : 'Message ideas for your $relation.';

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
              'Message Ideas',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: ideaTextSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
            2.h,
            Text(
              'Write something memorable for ${widget.friendName}.',
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
                icon: Icons.edit_note_rounded,
                title: widget.friendName,
                subtitle: subtitle,
              ),
              const SizedBox(height: 18),
              _MessageLanguageSelector(
                languages: _primaryLanguageOptions,
                moreLanguages: _moreLanguageOptions,
                selectedLanguage: _selectedLanguage,
                onChanged: _changeLanguage,
                onMoreTap: _openMoreLanguages,
              ),
              const SizedBox(height: 22),
              const IdeaSectionTitle(title: 'Ready to send'),
              const SizedBox(height: 12),
              FutureBuilder<List<MessageIdea>>(
                future: _messageIdeasFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _MessagesLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _MessagesErrorState(onRetry: _retry);
                  }

                  final messages = snapshot.data ?? const <MessageIdea>[];
                  if (messages.isEmpty) {
                    return _MessagesEmptyState(onRetry: _retry);
                  }

                  return Column(
                    children: [
                      for (final message in messages) ...[
                        _MessageIdeaCard(message: message.wish),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesLoadingState extends StatefulWidget {
  const _MessagesLoadingState();

  @override
  State<_MessagesLoadingState> createState() => _MessagesLoadingStateState();
}

class _MessagesLoadingStateState extends State<_MessagesLoadingState> {
  static const _messages = [
    'Finding the right words...',
    'Making it sound warm, not generic...',
    'Adding a little heart...',
    'Polishing a few message ideas...',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _index = (_index + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = _messages[_index];

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
          const SizedBox(height: 14),
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
          const SizedBox(height: 6),
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

class _MessageLanguageSelector extends StatelessWidget {
  const _MessageLanguageSelector({
    required this.languages,
    required this.moreLanguages,
    required this.selectedLanguage,
    required this.onChanged,
    required this.onMoreTap,
  });

  final List<String> languages;
  final List<String> moreLanguages;
  final String selectedLanguage;
  final ValueChanged<String> onChanged;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visibleLanguages = moreLanguages.contains(selectedLanguage)
        ? [selectedLanguage, ...languages]
        : languages;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: AppColors.coral,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Language',
                style: textTheme.titleMedium?.copyWith(
                  color: ideaTextSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                selectedLanguage,
                style: textTheme.bodySmall?.copyWith(
                  color: ideaTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final language in visibleLanguages) ...[
                  _LanguageChip(
                    label: language,
                    selected: language == selectedLanguage,
                    onTap: () => onChanged(language),
                  ),
                  const SizedBox(width: 8),
                ],
                _LanguageChip(
                  label: 'More',
                  selected: false,
                  icon: Icons.keyboard_arrow_down_rounded,
                  onTap: onMoreTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceWarm,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.divider.withValues(alpha: .9),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.surface,
                  size: 15,
                ),
                const SizedBox(width: 5),
              ],
              if (!selected && icon != null) ...[
                Icon(icon, color: ideaTextSoft, size: 16),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? AppColors.surface : ideaTextSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreLanguagesSheet extends StatelessWidget {
  const _MoreLanguagesSheet({
    required this.languages,
    required this.selectedLanguage,
  });

  final List<String> languages;
  final String selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 20,
                offset: Offset(0, 10),
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
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'More languages',
                style: textTheme.titleLarge?.copyWith(
                  color: ideaTextSoft,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the language for your message ideas.',
                style: textTheme.bodySmall?.copyWith(
                  color: ideaTextMuted,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      for (final language in languages)
                        _LanguageChip(
                          label: language,
                          selected: language == selectedLanguage,
                          onTap: () => Navigator.of(context).pop(language),
                        ),
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

class _MessagesErrorState extends StatelessWidget {
  const _MessagesErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _MessagesStateCard(
      icon: Icons.wifi_off_rounded,
      title: 'Could not load messages',
      message: 'Please check your connection and try again.',
      onRetry: onRetry,
    );
  }
}

class _MessagesEmptyState extends StatelessWidget {
  const _MessagesEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _MessagesStateCard(
      icon: Icons.edit_note_rounded,
      title: 'No messages found',
      message: 'Try again in a moment.',
      onRetry: onRetry,
    );
  }
}

class _MessagesStateCard extends StatelessWidget {
  const _MessagesStateCard({
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
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ideaTextSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ideaTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _MessageIdeaCard extends StatelessWidget {
  const _MessageIdeaCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“$message”',
            style: AppTextTheme.memoryText.copyWith(
              color: ideaTextSoft,
              fontSize: 23,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 6,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CopyButton(text: message),
                TextButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(ShareParams(text: message));
                  },
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Share'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
