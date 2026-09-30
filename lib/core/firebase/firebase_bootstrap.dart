import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _isConfigured = false;

  static bool get isConfigured => _isConfigured;

  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) {
      _isConfigured = true;
      return;
    }

    try {
      await Firebase.initializeApp();
      _isConfigured = true;
    } on FirebaseException catch (error) {
      _isConfigured = false;
      debugPrint('Firebase is not configured yet: ${error.message}');
    }
  }
}
