import 'package:firebase_analytics/firebase_analytics.dart';

import '../firebase/firebase_bootstrap.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? get _analytics {
    if (!FirebaseBootstrap.isConfigured) {
      return null;
    }
    return FirebaseAnalytics.instance;
  }

  Future<void> log(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Analytics should never block the user journey.
    }
  }

  Future<void> signupSuccess({required String method}) {
    return log('signup_success', parameters: {'method': method});
  }

  Future<void> loginSuccess({required String method}) {
    return log('login_success', parameters: {'method': method});
  }

  Future<void> homeViewed() {
    return log('home_viewed');
  }

  Future<void> createSlamStarted({required String source}) {
    return log('create_slam_started', parameters: {'source': source});
  }

  Future<void> createSlamSaved({required String source}) {
    return log('create_slam_saved', parameters: {'source': source});
  }

  Future<void> createSlamAbandoned({required String source}) {
    return log('create_slam_abandoned', parameters: {'source': source});
  }

  Future<void> inviteFriendClicked() {
    return log('invite_friend_clicked');
  }

  Future<void> inviteLinkOpened() {
    return log('invite_link_opened');
  }

  Future<void> inviteSlamSaved() {
    return log('invite_slam_saved');
  }

  Future<void> quickIdeasSubmitted({
    required String type,
    required String occasion,
    String? gender,
  }) {
    return log(
      'quick_ideas_submitted',
      parameters: {
        'type': type,
        'occasion': occasion,
        if (gender != null && gender.trim().isNotEmpty) 'gender': gender,
      },
    );
  }

  Future<void> giftIdeasLoaded({
    required String occasion,
    String? source,
    int? count,
  }) {
    return log(
      'gift_ideas_loaded',
      parameters: {
        'occasion': occasion,
        if (source != null && source.trim().isNotEmpty) 'source': source,
        if (count != null) 'count': count,
      },
    );
  }

  Future<void> messageIdeasLoaded({
    required String occasion,
    String? source,
    int? count,
  }) {
    return log(
      'message_ideas_loaded',
      parameters: {
        'occasion': occasion,
        if (source != null && source.trim().isNotEmpty) 'source': source,
        if (count != null) 'count': count,
      },
    );
  }

  Future<void> reminderSet({required String type}) {
    return log('reminder_set', parameters: {'type': type});
  }

  Future<void> deleteAccountConfirmed() {
    return log('delete_account_confirmed');
  }
}
