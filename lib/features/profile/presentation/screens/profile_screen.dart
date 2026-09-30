import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import '/core/extensions/spacing_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/user_profile_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import '../widgets/profile_setting_tile.dart';

const _settingsTextSoft = Color(0xFF2B4774);
const _settingsTextMuted = Color(0xFF74819A);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 390 ? 16.0 : 24.0;

    return SafeArea(
      bottom: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              10.h,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.profileSettingsTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 20,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  /*IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined),
                    color: AppColors.primary,
                    iconSize: 24,
                  ),*/
                ],
              ),
              20.h,
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _ProfileHeader(),
                        20.h,
                        ProfileSettingTile(
                          icon: HugeIcons.strokeRoundedNotification01,
                          title: l10n.notificationSettings,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const NotificationSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        ProfileSettingTile(
                          icon: HugeIcons.strokeRoundedCircleLock02,
                          title: l10n.privacy,
                          onTap: () => _openLegalLink(
                            context,
                            url: 'https://slamora.com/privacy',
                            errorMessage: l10n.couldNotOpenPrivacy,
                          ),
                        ),
                        ProfileSettingTile(
                          icon: HugeIcons.strokeRoundedHelpCircle,
                          title: l10n.helpSupport,
                          onTap: () => _openSupportEmail(context),
                        ),
                        ProfileSettingTile(
                          icon: HugeIcons.strokeRoundedShare08,
                          title: l10n.shareApp,
                          onTap: () => _shareApp(context),
                        ),
                        ProfileSettingTile(
                          icon: HugeIcons.strokeRoundedPolicy,
                          title: l10n.termsOfService,
                          onTap: () => _openLegalLink(
                            context,
                            url: 'https://slamora.com/terms',
                            errorMessage: l10n.couldNotOpenTerms,
                          ),
                          showDivider: false,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                          child: Column(
                            children: [
                              _AccountActionButton(
                                label: l10n.logOut,
                                icon: Icons.logout_rounded,
                                onPressed: () => _showLogoutDialog(context),
                              ),
                              12.h,
                              _AccountActionButton(
                                label: l10n.deleteAccount,
                                icon: Icons.delete_outline_rounded,
                                isDestructive: true,
                                onPressed: () =>
                                    _showDeleteAccountDialog(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              90.h,
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountActionButton extends StatelessWidget {
  const _AccountActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.coral : AppColors.primary;
    final backgroundColor = isDestructive
        ? AppColors.coral.withValues(alpha: .06)
        : Colors.transparent;

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: color,
          side: BorderSide(
            color: color.withValues(alpha: isDestructive ? .72 : .42),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

Future<void> _showLogoutDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .42),
    builder: (context) => const _LogoutDialog(),
  );
}

Future<void> _showDeleteAccountDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .42),
    builder: (context) => const _DeleteAccountDialog(),
  );
}

Future<void> _openLegalLink(
  BuildContext context, {
  required String url,
  required String errorMessage,
}) async {
  final uri = Uri.parse(url);

  final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  if (opened || !context.mounted) {
    return;
  }

  final fallbackOpened = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
  if (fallbackOpened || !context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.coral,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(errorMessage),
    ),
  );
}

Future<void> _shareApp(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.smartappsin.slamora';
  final message = l10n.shareAppMessage(playStoreUrl);

  await SharePlus.instance.share(
    ShareParams(subject: l10n.trySlamora, text: message),
  );
}

Future<void> _openSupportEmail(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final uri = Uri.parse(
    'mailto:hello@slamora.com'
    '?subject=${Uri.encodeComponent(l10n.supportEmailSubject)}'
    '&body=${Uri.encodeComponent(l10n.supportEmailBody)}',
  );

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (opened || !context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.coral,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(l10n.couldNotOpenEmail),
    ),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    if (_isDeleting) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await AnalyticsService.instance.deleteAccountConfirmed();
      await AuthService.instance.deleteAccount();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isDeleting = false);
      final message = error.code == 'requires-recent-login'
          ? 'Please log out, sign in again, and then delete your account.'
          : 'Could not delete account. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.coral,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(message),
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
          content: const Text('Could not delete account. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.coral,
                size: 34,
              ),
            ),
            18.h,
            Text(
              'Delete your account?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _settingsTextSoft,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            10.h,
            Text(
              'This will remove your profile, slams, memory photos, and reminders. This cannot be undone.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _settingsTextMuted,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            20.h,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isDeleting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _settingsTextSoft,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        color: _settingsTextSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                10.w,
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDeleting ? null : _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Delete',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
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

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const Positioned(
                  right: 8,
                  top: 6,
                  child: Icon(
                    Icons.favorite_rounded,
                    color: AppColors.coral,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Log out of Slamora?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _settingsTextSoft,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            10.h,
            Text(
              'Your memories will stay safe. You can come back and continue anytime.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _settingsTextMuted,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            20.h,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _settingsTextSoft,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Stay',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 12,
                        color: _settingsTextSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                10.w,
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await AuthService.instance.logout();

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const AuthScreen(),
                        ),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Log Out',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return StreamBuilder(
      stream: AuthService.instance.currentUserProfileStream(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final rawName = data['name']?.toString().trim().isNotEmpty == true
            ? data['name']?.toString().trim()
            : user?.displayName?.trim();
        final fallbackName = user?.email?.split('@').first.trim();
        final name = rawName == null || rawName.isEmpty
            ? fallbackName == null || fallbackName.isEmpty
                  ? ''
                  : fallbackName
            : rawName;
        final email = data['email']?.toString().trim().isNotEmpty == true
            ? data['email']?.toString().trim()
            : user?.email?.trim();
        final photoUrl = data['photoUrl']?.toString().trim().isNotEmpty == true
            ? data['photoUrl']?.toString().trim()
            : user?.photoURL;

        return Container(
          width: double.infinity,
          color: AppColors.primary,
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
                        AppColors.primary.withValues(alpha: .88),
                        AppColors.primaryDark.withValues(alpha: .82),
                        AppColors.coralDeep.withValues(alpha: .22),
                      ],
                      stops: const [0, .68, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 26, 24, 26),
                child: Row(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: UserProfileAvatar(
                        name: name,
                        photoUrl: photoUrl,
                        size: 76,
                        borderColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email == null || email.isEmpty
                                ? 'alex.sharma@mail.com'
                                : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: .72),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<bool>(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Edit Profile',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
