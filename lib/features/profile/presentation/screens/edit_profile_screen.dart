import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:slamora/core/extensions/spacing_extensions.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/capitalize_first_letter_formatter.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/user_profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _photoUrl = '';
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = AuthService.instance.currentUser;
    _nameController.text = user?.displayName?.trim() ?? '';
    _emailController.text = user?.email?.trim() ?? '';
    _photoUrl = user?.photoURL?.trim() ?? '';

    try {
      final snapshot = await AuthService.instance.getCurrentUserProfile();
      final data = snapshot.data() ?? <String, dynamic>{};
      _nameController.text = _stringValue(
        data['name'],
        fallback: _nameController.text,
      );
      _usernameController.text = _stringValue(data['username']);
      _phoneController.text = _stringValue(data['phone']);
      _emailController.text = _stringValue(
        data['email'],
        fallback: _emailController.text,
      );
      _photoUrl = _stringValue(data['photoUrl'], fallback: _photoUrl);
    } catch (_) {
      // Auth values above are enough to let the user keep editing offline-ish.
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AuthService.instance.updateUserProfile(
        name: _nameController.text,
        username: _usernameController.text,
        phone: _phoneController.text,
        localPhotoPath: _localPhotoPath,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text('Profile updated.'),
        ),
      );
      Navigator.of(context).pop(true);
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
          content: const Text('Could not update profile. Please try again.'),
        ),
      );
    }
  }

  Future<void> _pickProfilePhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) {
      return;
    }

    final compressedPath = await _compressedProfilePhotoPath(image);
    if (compressedPath == null || !mounted) {
      _showError('Could not prepare this photo. Please try another one.');
      return;
    }

    setState(() => _localPhotoPath = compressedPath);
  }

  Future<String?> _compressedProfilePhotoPath(XFile image) async {
    final sourcePath = image.path;
    final targetPath =
        '${sourcePath.substring(0, sourcePath.lastIndexOf('.'))}_slamora_profile.jpg';
    var quality = 84;

    while (quality >= 45) {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        minWidth: 720,
        minHeight: 720,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (compressed == null) {
        return null;
      }

      final file = File(compressed.path);
      if (await file.length() <= 1024 * 1024) {
        return compressed.path;
      }
      quality -= 12;
    }

    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.coral,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 390 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.primary,
          iconSize: 20,
          tooltip: 'Back',
        ),
        centerTitle: true,
        title: Text(
          'Edit Profile',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                18.h,
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _ProfilePhotoPreview(
                                  name: _nameController.text,
                                  photoUrl: _photoUrl,
                                  localPhotoPath: _localPhotoPath,
                                  onTap: _pickProfilePhoto,
                                ),
                                22.h,
                                _ProfileTextField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  hintText: 'Enter your full name',
                                  icon: HugeIcons.strokeRoundedUser,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value.trim().isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                14.h,
                                _ProfileTextField(
                                  controller: _usernameController,
                                  label: 'Username',
                                  hintText: 'Choose a username',
                                  icon: HugeIcons.strokeRoundedAt,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value.trim().isEmpty) {
                                      return 'Please enter a username';
                                    }
                                    if (value.trim().length < 3) {
                                      return 'Username should be at least 3 characters';
                                    }
                                    return null;
                                  },
                                ),
                                14.h,
                                _ProfileTextField(
                                  controller: _phoneController,
                                  label: 'Phone Number',
                                  hintText: 'Add your phone number',
                                  icon: HugeIcons.strokeRoundedCall02,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                ),
                                14.h,
                                _ProfileTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hintText: 'Email address',
                                  icon: HugeIcons.strokeRoundedMail01,
                                  keyboardType: TextInputType.emailAddress,
                                  readOnly: true,
                                ),
                                28.h,
                              ],
                            ),
                          ),
                        ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: .72,
                      ),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class _ProfilePhotoPreview extends StatelessWidget {
  const _ProfilePhotoPreview({
    required this.name,
    required this.photoUrl,
    required this.localPhotoPath,
    required this.onTap,
  });

  final String name;
  final String photoUrl;
  final String? localPhotoPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _EditableAvatar(
                  name: name.isEmpty ? 'Slamora' : name,
                  photoUrl: photoUrl,
                  localPhotoPath: localPhotoPath,
                ),
                Positioned(
                  right: -2,
                  bottom: 0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
          14.h,
          Text(
            'Change profile photo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          4.h,
          Text(
            'Photos are compressed before upload.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.name,
    required this.photoUrl,
    required this.localPhotoPath,
  });

  final String name;
  final String photoUrl;
  final String? localPhotoPath;

  @override
  Widget build(BuildContext context) {
    if (localPhotoPath == null) {
      return UserProfileAvatar(
        name: name,
        photoUrl: photoUrl,
        size: 104,
        borderColor: AppColors.coral.withValues(alpha: .42),
      );
    }

    return Container(
      width: 104,
      height: 104,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.coral.withValues(alpha: .42)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.file(File(localPhotoPath!), fit: BoxFit.cover),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final List<List<dynamic>> icon;
  final String? Function(String value)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: keyboardType == TextInputType.emailAddress
          ? TextCapitalization.none
          : TextCapitalization.sentences,
      inputFormatters: readOnly || keyboardType == TextInputType.emailAddress
          ? null
          : const [CapitalizeFirstLetterFormatter()],
      validator: validator == null ? null : (value) => validator!(value ?? ''),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: readOnly ? AppColors.textSecondary : AppColors.primary,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: readOnly
            ? AppColors.surfaceWarm.withValues(alpha: .6)
            : AppColors.surface,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(14),
          child: HugeIcon(icon: icon, color: AppColors.primary, size: 22),
        ),
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary.withValues(alpha: .72),
          fontWeight: FontWeight.w700,
        ),
        errorStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.coral,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.4),
        ),
      ),
    );
  }
}
