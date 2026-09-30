import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../firebase/firebase_bootstrap.dart';
import '../firebase/firestore_collections.dart';

class ReminderNotificationService {
  ReminderNotificationService._();

  static final ReminderNotificationService instance =
      ReminderNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _channelId = 'slamora_reminders';
  static const _channelName = 'Slamora reminders';
  static const _channelDescription = 'Birthday and anniversary reminders';
  static const _androidSmallIcon = '@drawable/notification_icon';

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(_androidSmallIcon);
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();
    if (kIsWeb) {
      return false;
    }

    final androidGranted = await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final iosGranted = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final macGranted = await _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return androidGranted ?? iosGranted ?? macGranted ?? true;
  }

  Future<void> scheduleReminder({
    required String ownerUserId,
    required String slamId,
    required String reminderType,
    required String friendName,
    required String eventDate,
    required int remindBeforeDays,
  }) async {
    await initialize();
    await cancelReminder(slamId: slamId, reminderType: reminderType);

    if (await areReminderNotificationsPaused(ownerUserId)) {
      return;
    }

    final permissionGranted = await requestPermissions();
    if (!permissionGranted) {
      return;
    }

    final scheduledAt = nextReminderDate(eventDate, remindBeforeDays);
    if (scheduledAt == null) {
      return;
    }

    await _notifications.zonedSchedule(
      id: notificationId(slamId: slamId, reminderType: reminderType),
      title: _titleFor(reminderType, friendName),
      body: _bodyFor(reminderType, friendName, remindBeforeDays),
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          icon: _androidSmallIcon,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: 'slam:$ownerUserId:$slamId:$reminderType',
    );
  }

  Future<void> cancelReminder({
    required String slamId,
    required String reminderType,
  }) async {
    await initialize();
    await _notifications.cancel(
      id: notificationId(slamId: slamId, reminderType: reminderType),
    );
  }

  Future<void> rescheduleForUser(String ownerUserId) async {
    if (!FirebaseBootstrap.isConfigured) {
      return;
    }

    await initialize();

    if (await areReminderNotificationsPaused(ownerUserId)) {
      await _notifications.cancelAll();
      return;
    }

    final slams = await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(ownerUserId)
        .collection(FirestoreCollections.slams)
        .get();

    for (final slam in slams.docs) {
      final data = slam.data();
      final aboutData = await _aboutSectionData(ownerUserId, slam.id);
      final fullName = data['fullName']?.toString().trim() ?? 'Someone';
      final birthday = data['dateOfBirth']?.toString().trim().isNotEmpty == true
          ? data['dateOfBirth'].toString().trim()
          : aboutData['dateOfBirth']?.toString().trim() ?? '';
      final anniversary =
          data['anniversary']?.toString().trim().isNotEmpty == true
          ? data['anniversary'].toString().trim()
          : aboutData['anniversary']?.toString().trim() ?? '';
      final reminders = _mapValue(data['reminders']);

      await _rescheduleOne(
        ownerUserId: ownerUserId,
        slamId: slam.id,
        reminderType: 'birthday',
        friendName: fullName,
        eventDate: birthday,
        reminder: _mapValue(reminders['birthday']),
      );
      await _rescheduleOne(
        ownerUserId: ownerUserId,
        slamId: slam.id,
        reminderType: 'anniversary',
        friendName: fullName,
        eventDate: anniversary,
        reminder: _mapValue(reminders['anniversary']),
      );
    }
  }

  Stream<bool> watchReminderNotificationsPaused(String ownerUserId) {
    if (!FirebaseBootstrap.isConfigured) {
      return Stream<bool>.value(false);
    }

    return FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(ownerUserId)
        .snapshots()
        .map((snapshot) {
          final settings = _mapValue(snapshot.data()?['notificationSettings']);
          return settings['remindersPaused'] == true;
        });
  }

  Future<bool> areReminderNotificationsPaused(String ownerUserId) async {
    if (!FirebaseBootstrap.isConfigured) {
      return false;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(ownerUserId)
        .get();
    final settings = _mapValue(snapshot.data()?['notificationSettings']);
    return settings['remindersPaused'] == true;
  }

  Future<void> setReminderNotificationsPaused({
    required String ownerUserId,
    required bool paused,
  }) async {
    if (!FirebaseBootstrap.isConfigured) {
      return;
    }

    await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(ownerUserId)
        .set({
          'notificationSettings': {
            'remindersPaused': paused,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await initialize();
    if (paused) {
      await _notifications.cancelAll();
    } else {
      await rescheduleForUser(ownerUserId);
    }
  }

  DateTime? nextReminderDate(String eventDate, int remindBeforeDays) {
    final parsed = _parseDayMonth(eventDate);
    if (parsed == null) {
      return null;
    }

    final now = DateTime.now();
    var nextEvent = DateTime(now.year, parsed.$2, parsed.$1, 9);
    var nextReminder = nextEvent.subtract(Duration(days: remindBeforeDays));

    if (!nextReminder.isAfter(now)) {
      nextEvent = DateTime(now.year + 1, parsed.$2, parsed.$1, 9);
      nextReminder = nextEvent.subtract(Duration(days: remindBeforeDays));
    }

    return nextReminder;
  }

  int notificationId({required String slamId, required String reminderType}) {
    var hash = 0;
    final source = '$slamId:$reminderType';
    for (final codeUnit in source.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = hash ^ (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return max(1, hash);
  }

  Future<void> _rescheduleOne({
    required String ownerUserId,
    required String slamId,
    required String reminderType,
    required String friendName,
    required String eventDate,
    required Map<String, Object?> reminder,
  }) async {
    final enabled = reminder['enabled'] == true;
    final days = reminder['remindBeforeDays'];
    final remindBeforeDays = days is num ? days.toInt() : 1;

    if (!enabled) {
      await cancelReminder(slamId: slamId, reminderType: reminderType);
      return;
    }

    await scheduleReminder(
      ownerUserId: ownerUserId,
      slamId: slamId,
      reminderType: reminderType,
      friendName: friendName,
      eventDate: eventDate,
      remindBeforeDays: remindBeforeDays,
    );
  }

  Future<Map<String, Object?>> _aboutSectionData(
    String ownerUserId,
    String slamId,
  ) async {
    try {
      final aboutSnapshot = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(ownerUserId)
          .collection(FirestoreCollections.slams)
          .doc(slamId)
          .collection('sections')
          .doc('about')
          .get();
      return _mapValue(aboutSnapshot.data()?['data']);
    } catch (_) {
      return const {};
    }
  }

  String _titleFor(String reminderType, String friendName) {
    final firstName = _firstName(friendName);

    return reminderType == 'anniversary'
        ? "$firstName's anniversary is coming up"
        : "$firstName's birthday is coming up";
  }

  String _bodyFor(
    String reminderType,
    String friendName,
    int remindBeforeDays,
  ) {
    final firstName = friendName.trim().isEmpty
        ? 'them'
        : _firstName(friendName);

    final when = remindBeforeDays == 0
        ? 'today'
        : remindBeforeDays == 1
        ? 'tomorrow'
        : 'in $remindBeforeDays days';
    final occasion = reminderType == 'anniversary' ? 'anniversary' : 'birthday';

    return 'Send $firstName a little love. Their $occasion is $when.';
  }

  String _firstName(String friendName) {
    return friendName.trim().isEmpty
        ? 'Someone'
        : friendName.trim().split(RegExp(r'\s+')).first;
  }

  Map<String, Object?> _mapValue(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  (int, int)? _parseDayMonth(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return null;
    }

    final day = int.tryParse(parts.first);
    final month = _monthNumber(parts[1]);
    if (day == null || month == null) {
      return null;
    }

    return (day, month);
  }

  int? _monthNumber(String value) {
    return const {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    }[value.trim().toLowerCase()];
  }
}
