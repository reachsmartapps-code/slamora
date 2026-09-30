import 'dart:async';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/capitalize_first_letter_formatter.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/slam_firestore_service.dart';
import '../widgets/slam_flow_widgets.dart';

class CreateSlamFlowScreen extends StatefulWidget {
  const CreateSlamFlowScreen({this.inviteCode, super.key});

  final String? inviteCode;

  @override
  State<CreateSlamFlowScreen> createState() => _CreateSlamFlowScreenState();
}

class _CreateSlamFlowScreenState extends State<CreateSlamFlowScreen> {
  int _index = 0;
  bool _isSaving = false;
  bool _allowRoutePop = false;
  String? _friendProfileImagePath;
  String _selectedGender = '';
  final List<String> _memoryPhotoPaths = [];

  final _fullNameController = TextEditingController(text: '');
  final _nicknameController = TextEditingController(text: '');
  final _relationController = TextEditingController(text: '');
  final _dobController = TextEditingController();
  final _anniversaryController = TextEditingController();
  final _favoriteFoodController = TextEditingController(text: '');
  final _favoriteColorController = TextEditingController(text: '');
  final _favoriteMovieController = TextEditingController(text: '');
  final _favoriteBrandController = TextEditingController(text: '');
  final _dreamDestinationController = TextEditingController(text: '');
  final _momentController = TextEditingController(text: '');
  final _complimentController = TextEditingController(text: '');
  final _messageController = TextEditingController(text: "");

  final Set<String> _selectedInterests = {'Travel', 'Music', 'Sports'};
  final List<String> _customInterests = [];

  static const _stepNumbers = [1, 2, 3, 4, 5];
  static const _maxMemoryPhotos = 5;
  static const _maxCompressedPhotoBytes = 1024 * 1024;
  static const _defaultInterestLabels = [
    'Travel',
    'Photography',
    'Reading',
    'Music',
    'Movies',
    'Cooking',
    'Gaming',
    'Sports',
    'Fitness',
    'Art',
    'Fashion',
    'Writing',
  ];

  bool get _isFriendFilling => widget.inviteCode != null;

  String get _analyticsSource => _isFriendFilling ? 'invite_link' : 'own_phone';

  _CreateSlamFlowCopy get _copy => _isFriendFilling
      ? _CreateSlamFlowCopy.friendFilling
      : _CreateSlamFlowCopy.ownerCreating;

  String? get _currentUserPhotoUrl =>
      AuthService.instance.currentUser?.photoURL?.trim();

  String get _profilePhotoUrl {
    if (!_isFriendFilling) {
      return '';
    }

    return _currentUserPhotoUrl ?? '';
  }

  bool get _hasResolvedProfilePicture {
    if (_isFriendFilling) {
      return _profilePhotoUrl.isNotEmpty;
    }

    return _friendProfileImagePath != null;
  }

  @override
  void initState() {
    super.initState();
    unawaited(
      AnalyticsService.instance.createSlamStarted(source: _analyticsSource),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicknameController.dispose();
    _relationController.dispose();
    _dobController.dispose();
    _anniversaryController.dispose();
    _favoriteFoodController.dispose();
    _favoriteColorController.dispose();
    _favoriteMovieController.dispose();
    _favoriteBrandController.dispose();
    _dreamDestinationController.dispose();
    _momentController.dispose();
    _complimentController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _next() {
    final error = _validationMessageForStep(_index);
    if (error != null) {
      _showMessage(error);
      return;
    }

    if (_index == _stepNumbers.length) {
      _closeFlow();
      return;
    }

    setState(() => _index += 1);
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    final error = _firstValidationMessage();
    if (error != null) {
      _showMessage(error);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = AuthService.instance.currentUser;
      final userId = user?.uid;
      final inviteCode = widget.inviteCode;
      final slam = _buildSlamPayload(ownerUserId: userId ?? '');

      if (inviteCode != null) {
        await SlamFirestoreService.instance.saveSlam(
          inviteCode: inviteCode,
          slam: slam,
        );
      } else if (userId != null) {
        await SlamFirestoreService.instance.saveOwnSlam(
          ownerUserId: userId,
          slam: slam,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.coral,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text('Could not save this slam. Please try again.'),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    unawaited(
      AnalyticsService.instance.createSlamSaved(source: _analyticsSource),
    );
    if (widget.inviteCode != null) {
      unawaited(AnalyticsService.instance.inviteSlamSaved());
    }
    _closeFlow();
  }

  Map<String, Object?> _buildSlamPayload({required String ownerUserId}) {
    return {
      'ownerUserId': ownerUserId,
      'templateId': 'default',
      'fullName': _fullNameController.text.trim(),
      'nickname': _nicknameController.text.trim(),
      'relation': _relationController.text.trim(),
      'gender': _selectedGender,
      'dateOfBirth': _dobController.text.trim(),
      'anniversary': _anniversaryController.text.trim(),
      'hasProfilePicture': _hasResolvedProfilePicture,
      'photoUrl': _profilePhotoUrl,
      'localPhotoPath': _friendProfileImagePath ?? '',
      'memoryPhotoPaths': List<String>.from(_memoryPhotoPaths),
      'interests': _selectedInterests.toList()..sort(),
      'favourites': {
        'food': _favoriteFoodController.text.trim(),
        'colour': _favoriteColorController.text.trim(),
        'movieOrSeries': _favoriteMovieController.text.trim(),
        'brand': _favoriteBrandController.text.trim(),
        'dreamDestination': _dreamDestinationController.text.trim(),
      },
      'memories': {
        'moment': _momentController.text.trim(),
        'compliment': _complimentController.text.trim(),
        'message': _messageController.text.trim(),
      },
      'photoCount': _memoryPhotoPaths.length,
    };
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  Future<void> _showAddInterestDialog() async {
    final interest = await showDialog<String>(
      context: context,
      builder: (context) => const _AddInterestDialog(),
    );

    final trimmedInterest = interest?.trim();
    if (trimmedInterest == null || trimmedInterest.isEmpty || !mounted) {
      return;
    }

    final existingInterest = _existingInterestLabel(trimmedInterest);
    setState(() {
      if (existingInterest != null) {
        _selectedInterests.add(existingInterest);
      } else {
        _customInterests.add(trimmedInterest);
        _selectedInterests.add(trimmedInterest);
      }
    });
  }

  String? _existingInterestLabel(String interest) {
    final normalized = interest.trim().toLowerCase();
    for (final existing in [..._defaultInterestLabels, ..._customInterests]) {
      if (existing.toLowerCase() == normalized) {
        return existing;
      }
    }

    return null;
  }

  Future<void> _pickMemoryPhotos() async {
    final remainingSlots = _maxMemoryPhotos - _memoryPhotoPaths.length;
    if (remainingSlots <= 0) {
      _showMessage('You can add up to 5 photos.');
      return;
    }

    final images = await ImagePicker().pickMultiImage(
      imageQuality: 92,
      maxWidth: 1800,
      maxHeight: 1800,
      limit: remainingSlots,
    );

    if (images.isEmpty || !mounted) {
      return;
    }

    final compressedPaths = <String>[];
    var skipped = 0;

    for (final image in images.take(remainingSlots)) {
      final compressedPath = await _compressedMemoryPhotoPath(image);
      if (compressedPath == null) {
        skipped += 1;
        continue;
      }

      compressedPaths.add(compressedPath);
    }

    if (!mounted) {
      return;
    }

    if (compressedPaths.isNotEmpty) {
      setState(() => _memoryPhotoPaths.addAll(compressedPaths));
    }

    if (skipped > 0) {
      _showMessage(
        skipped == 1
            ? '1 photo could not be reduced under 1 MB.'
            : '$skipped photos could not be reduced under 1 MB.',
      );
    }
  }

  Future<String?> _compressedMemoryPhotoPath(XFile image) async {
    final sourcePath = image.path;
    const qualities = [82, 70, 58, 46, 34, 22];

    for (final quality in qualities) {
      final targetPath =
          '${Directory.systemTemp.path}/slamora_memory_${DateTime.now().microsecondsSinceEpoch}_$quality.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: quality,
        minWidth: 1200,
        minHeight: 1200,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) {
        continue;
      }

      final file = File(compressed.path);
      if (await file.length() <= _maxCompressedPhotoBytes) {
        return file.path;
      }
    }

    return null;
  }

  void _removeMemoryPhoto(int index) {
    if (index < 0 || index >= _memoryPhotoPaths.length) {
      return;
    }

    setState(() => _memoryPhotoPaths.removeAt(index));
  }

  Future<void> _pickProfilePicture() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _friendProfileImagePath = image.path;
    });
  }

  void _removeProfilePicture() {
    setState(() => _friendProfileImagePath = null);
  }

  String? _validationMessageForStep(int stepIndex) {
    switch (stepIndex) {
      case 0:
        if (_isBlank(_fullNameController)) {
          return 'Please enter full name.';
        }
        if (_isBlank(_dobController)) {
          return 'Please select date of birth.';
        }
      case 1:
        if (_selectedInterests.isEmpty) {
          return 'Please select at least one interest.';
        }
      case 2:
        if (_isBlank(_favoriteFoodController)) {
          return 'Please enter favourite food.';
        }
        if (_isBlank(_favoriteColorController)) {
          return 'Please enter favourite colour.';
        }
        if (_isBlank(_favoriteMovieController)) {
          return 'Please enter favourite movie or series.';
        }
        if (_isBlank(_dreamDestinationController)) {
          return 'Please enter dream destination.';
        }
      case 3:
        if (_isBlank(_momentController)) {
          return 'Please add one memory you would relive.';
        }
        if (_isBlank(_complimentController)) {
          return 'Please add something you like.';
        }
        if (_isBlank(_messageController)) {
          return 'Please leave a message.';
        }
    }

    return null;
  }

  bool _isBlank(TextEditingController controller) {
    return controller.text.trim().isEmpty;
  }

  String? _firstValidationMessage() {
    for (var i = 0; i < _stepNumbers.length; i += 1) {
      final error = _validationMessageForStep(i);
      if (error != null) {
        return error;
      }
    }

    return null;
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 9, 12),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
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

    controller.text = _formatDate(selected);
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.coral,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message),
      ),
    );
  }

  void _back() {
    if (_index == 0) {
      _confirmCloseFlow();
      return;
    }

    setState(() => _index -= 1);
  }

  void _closeFlow() {
    _allowRoutePop = true;
    Navigator.of(context).pop();
  }

  Future<void> _confirmCloseFlow() async {
    if (_isSaving) {
      return;
    }

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => const _CloseCreateSlamDialog(),
    );

    if (shouldClose == true && mounted) {
      unawaited(
        AnalyticsService.instance.createSlamAbandoned(source: _analyticsSource),
      );
      _closeFlow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _AboutYouStep(
        copy: _copy,
        showProfilePictureOption: !_isFriendFilling,
        profileImagePath: _friendProfileImagePath,
        fullNameController: _fullNameController,
        nicknameController: _nicknameController,
        relationController: _relationController,
        selectedGender: _selectedGender,
        onGenderChanged: (gender) => setState(() => _selectedGender = gender),
        dobController: _dobController,
        anniversaryController: _anniversaryController,
        onPickProfilePicture: _pickProfilePicture,
        onRemoveProfilePicture: _removeProfilePicture,
        onPickDob: () => _pickDate(_dobController),
        onPickAnniversary: () => _pickDate(_anniversaryController),
        onBack: _back,
        onNext: _next,
      ),
      _InterestsStep(
        copy: _copy,
        selectedInterests: _selectedInterests,
        customInterests: _customInterests,
        onToggleInterest: _toggleInterest,
        onAddInterest: _showAddInterestDialog,
        onBack: _back,
        onNext: _next,
      ),
      _FavouritesStep(
        copy: _copy,
        favoriteFoodController: _favoriteFoodController,
        favoriteColorController: _favoriteColorController,
        favoriteMovieController: _favoriteMovieController,
        favoriteBrandController: _favoriteBrandController,
        dreamDestinationController: _dreamDestinationController,
        onBack: _back,
        onNext: _next,
      ),
      _HeartfeltQuestionsStep(
        copy: _copy,
        momentController: _momentController,
        complimentController: _complimentController,
        messageController: _messageController,
        onBack: _back,
        onNext: _next,
      ),
      _PhotosStep(
        copy: _copy,
        photoPaths: _memoryPhotoPaths,
        onAddPhoto: _pickMemoryPhotos,
        onRemovePhoto: _removeMemoryPhoto,
        onBack: _back,
        onNext: _next,
      ),
      _ReviewStep(
        copy: _copy,
        hasProfilePicture: _hasResolvedProfilePicture,
        showProfilePictureSummary: !_isFriendFilling,
        fullName: _fullNameController.text.trim(),
        gender: _selectedGender,
        dateOfBirth: _dobController.text.trim(),
        interests: _selectedInterests.toList()..sort(),
        favoriteFood: _favoriteFoodController.text.trim(),
        favoriteColor: _favoriteColorController.text.trim(),
        moment: _momentController.text.trim(),
        photoCount: _memoryPhotoPaths.length,
        onBack: _back,
        onSave: () {
          _save();
        },
        isSaving: _isSaving,
      ),
    ];

    return PopScope<Object?>(
      canPop: _allowRoutePop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        _confirmCloseFlow();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
        ),
      ),
    );
  }
}

class _CloseCreateSlamDialog extends StatelessWidget {
  const _CloseCreateSlamDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.coral,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Close create slam?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your current progress will be lost. Stay here if you tapped back by mistake.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          /*Row(children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Keep editing'),
                ),
              ),
            ),
            10.w,
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.coral,
                    side: BorderSide(color: AppColors.coral.withValues(alpha: .55)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],)*/
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Keep editing'),
        ),
      ],
    );
  }
}

class _AddInterestDialog extends StatefulWidget {
  const _AddInterestDialog();

  @override
  State<_AddInterestDialog> createState() => _AddInterestDialogState();
}

class _AddInterestDialogState extends State<_AddInterestDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        'Add interest',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        inputFormatters: const [CapitalizeFirstLetterFormatter()],
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: 'E.g. Dancing',
          prefixIcon: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
          ),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _CreateSlamFlowCopy {
  const _CreateSlamFlowCopy({
    required this.aboutTitle,
    required this.aboutSubtitle,
    required this.fullNameLabel,
    required this.fullNameHint,
    required this.nicknameLabel,
    required this.nicknameHint,
    required this.relationLabel,
    required this.relationHint,
    required this.dobLabel,
    required this.dobHint,
    required this.profilePictureTitle,
    required this.profilePictureSubtitle,
    required this.profilePictureAdded,
    required this.interestsTitle,
    required this.interestsSubtitle,
    required this.favouritesTitle,
    required this.favouritesSubtitle,
    required this.heartTitle,
    required this.heartSubtitle,
    required this.momentLabel,
    required this.momentHint,
    required this.complimentLabel,
    required this.complimentHint,
    required this.messageLabel,
    required this.messageHint,
    required this.photosTitle,
    required this.photosSubtitle,
    required this.reviewSubtitle,
    required this.aboutReviewTitle,
  });

  final String aboutTitle;
  final String aboutSubtitle;
  final String fullNameLabel;
  final String fullNameHint;
  final String nicknameLabel;
  final String nicknameHint;
  final String relationLabel;
  final String relationHint;
  final String dobLabel;
  final String dobHint;
  final String profilePictureTitle;
  final String profilePictureSubtitle;
  final String profilePictureAdded;
  final String interestsTitle;
  final String interestsSubtitle;
  final String favouritesTitle;
  final String favouritesSubtitle;
  final String heartTitle;
  final String heartSubtitle;
  final String momentLabel;
  final String momentHint;
  final String complimentLabel;
  final String complimentHint;
  final String messageLabel;
  final String messageHint;
  final String photosTitle;
  final String photosSubtitle;
  final String reviewSubtitle;
  final String aboutReviewTitle;

  static const ownerCreating = _CreateSlamFlowCopy(
    aboutTitle: "Let's create your slam",
    aboutSubtitle: 'Your friend will save these details as a memory of you.',
    fullNameLabel: 'Full name',
    fullNameHint: 'Enter your full name',
    nicknameLabel: 'Nickname',
    nicknameHint: 'Enter your nickname',
    relationLabel: 'Your relation with them',
    relationHint: 'E.g. Best friend, Cousin, Brother',
    dobLabel: 'Date of birth',
    dobHint: 'Select your date of birth',
    profilePictureTitle: 'Profile picture',
    profilePictureSubtitle: 'Add your profile picture.',
    profilePictureAdded: 'Profile picture added',
    interestsTitle: 'What are you into?',
    interestsSubtitle: 'Pick the things you love.',
    favouritesTitle: 'Your favourites',
    favouritesSubtitle: 'The little details that make you, you.',
    heartTitle: 'A few heartfelt questions',
    heartSubtitle: 'Share your thoughts, memories and messages.',
    momentLabel: "What's one moment with them you'd happily relive?",
    momentHint: 'Write a memory you both would smile about',
    complimentLabel: 'Something you like about them?',
    complimentHint: 'Write something warm and honest',
    messageLabel: 'Leave them a message',
    messageHint: 'Leave a message for this slam',
    photosTitle: 'Add some photos',
    photosSubtitle: 'Upload a few photos for this slam (optional).',
    reviewSubtitle: 'Take a quick look before saving your slam.',
    aboutReviewTitle: 'About You',
  );

  static const friendFilling = _CreateSlamFlowCopy(
    aboutTitle: "Let's get to know you",
    aboutSubtitle:
        'Tell us the basics so the person who invited you can remember the real you.',
    fullNameLabel: 'Full name',
    fullNameHint: 'Enter full name',
    nicknameLabel: 'Nickname',
    nicknameHint: 'Enter nickname',
    relationLabel: 'Your relation with them',
    relationHint: 'E.g. Best friend, Cousin, College friend',
    dobLabel: 'Date of birth',
    dobHint: 'Select date of birth',
    profilePictureTitle: 'Profile picture',
    profilePictureSubtitle: 'Add your profile picture.',
    profilePictureAdded: 'Profile picture added',
    interestsTitle: 'What are you into?',
    interestsSubtitle: 'Pick the things you love (you can choose multiple).',
    favouritesTitle: 'Your favourites',
    favouritesSubtitle: 'The little things that make you, you.',
    heartTitle: 'A few heartfelt questions',
    heartSubtitle: 'Share your thoughts, memories and messages.',
    momentLabel: "What's one moment with them you'd happily relive?",
    momentHint: 'Write a memory you both would smile about',
    complimentLabel: 'Something you like about them?',
    complimentHint: 'Write something warm and honest',
    messageLabel: 'Leave them a message',
    messageHint: 'Leave a message for this slam',
    photosTitle: 'Add some photos',
    photosSubtitle: 'Upload a few photos (optional).',
    reviewSubtitle: 'Take a quick look before saving it.',
    aboutReviewTitle: 'About You',
  );
}

class _AboutYouStep extends StatelessWidget {
  const _AboutYouStep({
    required this.copy,
    required this.showProfilePictureOption,
    required this.profileImagePath,
    required this.fullNameController,
    required this.nicknameController,
    required this.relationController,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.dobController,
    required this.anniversaryController,
    required this.onPickProfilePicture,
    required this.onRemoveProfilePicture,
    required this.onPickDob,
    required this.onPickAnniversary,
    required this.onBack,
    required this.onNext,
  });

  final _CreateSlamFlowCopy copy;
  final bool showProfilePictureOption;
  final String? profileImagePath;
  final TextEditingController fullNameController;
  final TextEditingController nicknameController;
  final TextEditingController relationController;
  final String selectedGender;
  final ValueChanged<String> onGenderChanged;
  final TextEditingController dobController;
  final TextEditingController anniversaryController;
  final VoidCallback onPickProfilePicture;
  final VoidCallback onRemoveProfilePicture;
  final VoidCallback onPickDob;
  final VoidCallback onPickAnniversary;

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SlamFlowScaffold(
      stepLabel: 'Step 1 of 5',
      progress: 1 / 5,
      title: copy.aboutTitle,
      subtitle: copy.aboutSubtitle,
      primaryLabel: 'Continue',
      onPrimaryPressed: onNext,
      onBackPressed: onBack,
      children: [
        if (showProfilePictureOption)
          _ProfilePictureOption(
            imagePath: profileImagePath,
            title: copy.profilePictureTitle,
            subtitle: copy.profilePictureSubtitle,
            selectedLabel: copy.profilePictureAdded,
            onPick: onPickProfilePicture,
            onRemove: onRemoveProfilePicture,
          ),
        SlamEditableField(
          label: copy.fullNameLabel,
          controller: fullNameController,
          hintText: copy.fullNameHint,
          required: true,
          keyboardType: TextInputType.name,
        ),
        SlamEditableField(
          label: copy.nicknameLabel,
          controller: nicknameController,
          hintText: copy.nicknameHint,
          keyboardType: TextInputType.name,
        ),
        SlamEditableField(
          label: copy.relationLabel,
          controller: relationController,
          hintText: copy.relationHint,
          keyboardType: TextInputType.text,
        ),
        _GenderSelector(
          selectedGender: selectedGender,
          onChanged: onGenderChanged,
        ),
        SlamEditableField(
          label: copy.dobLabel,
          controller: dobController,
          hintText: copy.dobHint,
          required: true,
          readOnly: true,
          onTap: onPickDob,
          icon: Icons.calendar_month_outlined,
        ),
        SlamEditableField(
          label: 'Anniversary (optional)',
          controller: anniversaryController,
          hintText: 'Select date',
          readOnly: true,
          onTap: onPickAnniversary,
          icon: Icons.calendar_month_outlined,
        ),
      ],
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({
    required this.selectedGender,
    required this.onChanged,
  });

  final String selectedGender;
  final ValueChanged<String> onChanged;

  static const _options = [
    (Icons.female_rounded, 'Female', 'Female'),
    (Icons.male_rounded, 'Male', 'Male'),
    (Icons.person_outline_rounded, 'Prefer not', 'Prefer not to say'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final option in _options) ...[
                Expanded(
                  child: _GenderOptionTile(
                    icon: option.$1,
                    label: option.$2,
                    selected: selectedGender == option.$3,
                    onTap: () =>
                        onChanged(selectedGender == option.$3 ? '' : option.$3),
                  ),
                ),
                if (option != _options.last) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderOptionTile extends StatelessWidget {
  const _GenderOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.accent : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w800,
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

class _InterestsStep extends StatelessWidget {
  const _InterestsStep({
    required this.copy,
    required this.selectedInterests,
    required this.customInterests,
    required this.onToggleInterest,
    required this.onAddInterest,
    required this.onBack,
    required this.onNext,
  });

  final _CreateSlamFlowCopy copy;
  final Set<String> selectedInterests;
  final List<String> customInterests;
  final ValueChanged<String> onToggleInterest;
  final VoidCallback onAddInterest;

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const defaultChoices = [
      (Icons.travel_explore_rounded, 'Travel', true),
      (Icons.camera_alt_outlined, 'Photography', false),
      (Icons.menu_book_outlined, 'Reading', false),
      (Icons.music_note_rounded, 'Music', true),
      (Icons.movie_outlined, 'Movies', false),
      (Icons.cake_outlined, 'Cooking', false),
      (Icons.sports_esports_outlined, 'Gaming', false),
      (Icons.sports_cricket_rounded, 'Sports', true),
      (Icons.fitness_center_rounded, 'Fitness', false),
      (Icons.water_drop_outlined, 'Art', false),
      (Icons.circle_outlined, 'Fashion', false),
      (Icons.edit_outlined, 'Writing', false),
    ];
    final choices = [
      ...defaultChoices,
      for (final interest in customInterests)
        (Icons.auto_awesome_rounded, interest, false),
    ];

    return SlamFlowScaffold(
      stepLabel: 'Step 2 of 5',
      progress: 2 / 5,
      title: copy.interestsTitle,
      subtitle: copy.interestsSubtitle,
      primaryLabel: 'Continue',
      onPrimaryPressed: onNext,
      onBackPressed: onBack,
      children: [
        GridView.builder(
          itemCount: choices.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3.2,
          ),
          itemBuilder: (context, index) {
            final choice = choices[index];
            return SlamChoiceChip(
              icon: choice.$1,
              label: choice.$2,
              selected: selectedInterests.contains(choice.$2),
              onTap: () => onToggleInterest(choice.$2),
            );
          },
        ),
        const SizedBox(height: 14),
        SlamChoiceChip(
          icon: Icons.add_circle_outline_rounded,
          label: 'Add another',
          onTap: onAddInterest,
        ),
      ],
    );
  }
}

class _FavouritesStep extends StatelessWidget {
  const _FavouritesStep({
    required this.copy,
    required this.favoriteFoodController,
    required this.favoriteColorController,
    required this.favoriteMovieController,
    required this.favoriteBrandController,
    required this.dreamDestinationController,
    required this.onBack,
    required this.onNext,
  });

  final _CreateSlamFlowCopy copy;
  final TextEditingController favoriteFoodController;
  final TextEditingController favoriteColorController;
  final TextEditingController favoriteMovieController;
  final TextEditingController favoriteBrandController;
  final TextEditingController dreamDestinationController;

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SlamFlowScaffold(
      stepLabel: 'Step 3 of 5',
      progress: 3 / 5,
      title: copy.favouritesTitle,
      subtitle: copy.favouritesSubtitle,
      primaryLabel: 'Continue',
      onPrimaryPressed: onNext,
      onBackPressed: onBack,
      children: [
        SlamEditableField(
          label: 'Favourite food',
          controller: favoriteFoodController,
          hintText: 'E.g. Pasta, Sushi, Rajma chawal',
          required: true,
          icon: Icons.ramen_dining_outlined,
        ),
        SlamEditableField(
          label: 'Favourite colour',
          controller: favoriteColorController,
          hintText: 'E.g. Peach, Blue, Purple',
          required: true,
          icon: Icons.circle_outlined,
        ),
        SlamEditableField(
          label: 'Favourite movie / series',
          controller: favoriteMovieController,
          hintText: 'E.g. Interstellar',
          required: true,
          icon: Icons.movie_creation_outlined,
        ),
        SlamEditableField(
          label: 'Favourite brand (optional)',
          controller: favoriteBrandController,
          hintText: 'E.g. Apple, Nike',
          icon: Icons.apple,
        ),
        SlamEditableField(
          label: 'Dream destination',
          controller: dreamDestinationController,
          hintText: 'E.g. Iceland, Goa, Switzerland',
          required: true,
          icon: Icons.public_rounded,
        ),
      ],
    );
  }
}

class _HeartfeltQuestionsStep extends StatelessWidget {
  const _HeartfeltQuestionsStep({
    required this.copy,
    required this.momentController,
    required this.complimentController,
    required this.messageController,
    required this.onBack,
    required this.onNext,
  });

  final _CreateSlamFlowCopy copy;
  final TextEditingController momentController;
  final TextEditingController complimentController;
  final TextEditingController messageController;

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SlamFlowScaffold(
      stepLabel: 'Step 4 of 5',
      progress: 4 / 5,
      title: copy.heartTitle,
      subtitle: copy.heartSubtitle,
      primaryLabel: 'Continue',
      onPrimaryPressed: onNext,
      onBackPressed: onBack,
      children: [
        SlamEditableField(
          label: copy.momentLabel,
          controller: momentController,
          hintText: copy.momentHint,
          required: true,
          maxLines: 3,
        ),
        SlamEditableField(
          label: copy.complimentLabel,
          controller: complimentController,
          hintText: copy.complimentHint,
          required: true,
          maxLines: 3,
        ),
        SlamEditableField(
          label: copy.messageLabel,
          controller: messageController,
          hintText: copy.messageHint,
          required: true,
          maxLines: 3,
        ),
      ],
    );
  }
}

class _PhotosStep extends StatelessWidget {
  const _PhotosStep({
    required this.copy,
    required this.photoPaths,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onBack,
    required this.onNext,
  });

  final _CreateSlamFlowCopy copy;
  final List<String> photoPaths;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SlamFlowScaffold(
      stepLabel: 'Step 5 of 5',
      progress: 1,
      title: copy.photosTitle,
      subtitle: copy.photosSubtitle,
      primaryLabel: 'Continue',
      onPrimaryPressed: onNext,
      onBackPressed: onBack,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: .95,
          children: [
            for (var i = 0; i < photoPaths.length; i += 1)
              _PhotoTile(
                imagePath: photoPaths[i],
                onRemove: () => onRemovePhoto(i),
              ),
            if (photoPaths.length < _CreateSlamFlowScreenState._maxMemoryPhotos)
              _AddPhotoTile(onTap: onAddPhoto),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'You can add up to 5 photos. Each photo is compressed under 1 MB.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.copy,
    required this.hasProfilePicture,
    required this.showProfilePictureSummary,
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    required this.interests,
    required this.favoriteFood,
    required this.favoriteColor,
    required this.moment,
    required this.photoCount,
    required this.onBack,
    required this.onSave,
    required this.isSaving,
  });

  final _CreateSlamFlowCopy copy;
  final bool hasProfilePicture;
  final bool showProfilePictureSummary;
  final String fullName;
  final String gender;
  final String dateOfBirth;
  final List<String> interests;
  final String favoriteFood;
  final String favoriteColor;
  final String moment;
  final int photoCount;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return SlamFlowScaffold(
      stepLabel: 'Review',
      progress: 1,
      title: 'Review your slam',
      subtitle: copy.reviewSubtitle,
      primaryLabel: isSaving ? 'Saving...' : 'Save This Memory',
      primaryIcon: Icons.favorite_rounded,
      onPrimaryPressed: onSave,
      onBackPressed: onBack,
      children: [
        SlamReviewTile(
          icon: Icons.face_retouching_natural_rounded,
          title: copy.aboutReviewTitle,
          subtitle: '${fullName.isEmpty ? 'No name' : fullName}, $dateOfBirth',
        ),
        SlamReviewTile(
          icon: Icons.person_outline_rounded,
          title: 'Gender',
          subtitle: gender.isEmpty ? 'Not selected' : gender,
        ),
        if (showProfilePictureSummary)
          SlamReviewTile(
            icon: Icons.account_circle_outlined,
            title: 'Profile Picture',
            subtitle: hasProfilePicture
                ? copy.profilePictureAdded
                : 'Not added',
          ),
        SlamReviewTile(
          icon: Icons.diversity_3_rounded,
          title: 'Interests',
          subtitle: interests.isEmpty
              ? 'No interests selected'
              : interests.join(', '),
        ),
        SlamReviewTile(
          icon: Icons.auto_stories_rounded,
          title: 'Favourites',
          subtitle: '$favoriteFood, $favoriteColor',
        ),
        SlamReviewTile(
          icon: Icons.favorite_rounded,
          title: 'Our Memories',
          subtitle: moment.isEmpty ? 'No memory added' : moment,
        ),
        SlamReviewTile(
          icon: Icons.photo_library_outlined,
          title: 'Photos',
          subtitle: '$photoCount photos',
        ),
      ],
    );
  }
}

class _ProfilePictureOption extends StatelessWidget {
  const _ProfilePictureOption({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.selectedLabel,
    required this.onPick,
    required this.onRemove,
  });

  final String? imagePath;
  final String title;
  final String subtitle;
  final String selectedLabel;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = imagePath != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.coral : AppColors.divider,
                width: selected ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: .08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.peach, Color(0xFFF6B39B)],
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: .12),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: selected
                      ? Image.file(File(imagePath!), fit: BoxFit.cover)
                      : const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.coral,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selected ? selectedLabel : subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.coral,
                    tooltip: 'Remove profile picture',
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.imagePath, required this.onRemove});

  final String imagePath;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Image.file(
            File(imagePath),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: AppColors.primary, size: 34),
              const SizedBox(height: 10),
              Text(
                'Add Photo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
