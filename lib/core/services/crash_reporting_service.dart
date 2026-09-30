import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_bootstrap.dart';

class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService instance = CrashReportingService._();

  bool get _isAvailable => FirebaseBootstrap.isConfigured && !kIsWeb;

  Future<void> initialize() async {
    if (!_isAvailable) {
      return;
    }

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  }

  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!_isAvailable) {
      FlutterError.presentError(details);
      return;
    }

    await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = true,
  }) async {
    if (!_isAvailable) {
      return;
    }

    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: fatal,
    );
  }
}
