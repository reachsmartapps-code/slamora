import 'package:flutter/material.dart';

import 'app_navigator.dart';
import 'theme/app_colors.dart';
import '../features/auth/presentation/screens/auth_gate.dart';
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '/app/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.startupTask});

  final Future<void> Function()? startupTask;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      navigatorKey: appNavigatorKey,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _StartupGate(startupTask: startupTask, child: const AuthGate()),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({required this.startupTask, required this.child});

  final Future<void> Function()? startupTask;
  final Widget child;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  static const _minimumSplashDuration = Duration(seconds: 2);

  Future<void>? _startupFuture;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant _StartupGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startupTask != widget.startupTask) {
      _start();
    }
  }

  void _start() {
    final startupTask = widget.startupTask;
    if (startupTask == null) {
      _startupFuture = Future<void>.value();
      return;
    }

    _startupFuture = Future.wait<void>([
      startupTask(),
      Future<void>.delayed(_minimumSplashDuration),
    ]);
  }

  void _retry() {
    setState(_start);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          return SplashScreen(hasError: true, onRetry: _retry);
        }

        return widget.child;
      },
    );
  }
}
