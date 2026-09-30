import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/services/invite_link_service.dart';
import 'core/services/reminder_notification_service.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        CrashReportingService.instance.recordFlutterError(details);
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        CrashReportingService.instance.recordError(error, stackTrace);
        return true;
      };

      runApp(MyApp(startupTask: _bootstrapApp));
    },
    (error, stackTrace) {
      CrashReportingService.instance.recordError(error, stackTrace);
    },
  );
}

Future<void> _bootstrapApp() async {
  await FirebaseBootstrap.initialize();
  await CrashReportingService.instance.initialize();

  try {
    await ReminderNotificationService.instance.initialize();
  } catch (error, stackTrace) {
    CrashReportingService.instance.recordError(error, stackTrace);
  }

  await InviteLinkService.instance.start();
}
