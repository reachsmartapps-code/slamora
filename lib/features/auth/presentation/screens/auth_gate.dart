import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/invite_link_service.dart';
import '../../../../core/services/reminder_notification_service.dart';
import '../../../../core/widgets/app_update_dialog.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../onboarding/presentation/screens/splash_screen.dart';
import 'auth_screen.dart';
import 'verify_email_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastRescheduledUserId;
  bool _hasCheckedForUpdate = false;

  void _refreshAfterAuthChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _rescheduleReminders(User user) {
    if (_lastRescheduledUserId == user.uid) {
      return;
    }

    _lastRescheduledUserId = user.uid;
    ReminderNotificationService.instance.rescheduleForUser(user.uid);
  }

  void _checkForAppUpdate() {
    if (_hasCheckedForUpdate || !FirebaseBootstrap.isConfigured) {
      return;
    }

    _hasCheckedForUpdate = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      try {
        final updateInfo = await AppUpdateService.instance.getUpdateInfo();
        if (updateInfo == null || !mounted) {
          return;
        }

        await showDialog<void>(
          context: context,
          barrierDismissible: !updateInfo.forceUpdate,
          barrierColor: Colors.black.withValues(alpha: .42),
          builder: (_) => AppUpdateDialog(updateInfo: updateInfo),
        );
      } catch (_) {
        // App updates should never block opening the app.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isConfigured) {
      return AuthScreen(onAuthChanged: _refreshAfterAuthChange);
    }

    _checkForAppUpdate();

    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snapshot.data;
        final currentUser = AuthService.instance.currentUser ?? user;
        if (currentUser == null) {
          _lastRescheduledUserId = null;
          return AuthScreen(onAuthChanged: _refreshAfterAuthChange);
        }

        if (AuthService.instance.requiresEmailVerification(currentUser)) {
          _lastRescheduledUserId = null;
          return VerifyEmailScreen(
            email: currentUser.email ?? '',
            onVerified: () => setState(() {}),
          );
        }

        _rescheduleReminders(currentUser);
        InviteLinkService.instance.openPendingInviteAfterLogin();
        return const HomeScreen();
      },
    );
  }
}
