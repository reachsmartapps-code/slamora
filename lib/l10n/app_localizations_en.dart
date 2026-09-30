// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Slamora';

  @override
  String get profileSettingsTitle => 'Profile / Settings';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get privacy => 'Privacy';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get shareApp => 'Share App';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get logOut => 'Log Out';

  @override
  String get trySlamora => 'Try Slamora';

  @override
  String shareAppMessage(String playStoreUrl) {
    return 'I found Slamora, a sweet app to save memories, create slams, and get gift or message ideas for your people.\n\nDownload it here:\n$playStoreUrl';
  }

  @override
  String get couldNotOpenPrivacy => 'Could not open privacy policy.';

  @override
  String get couldNotOpenTerms => 'Could not open terms of service.';

  @override
  String get couldNotOpenEmail => 'Could not open email app.';

  @override
  String get supportEmailSubject => 'Slamora support';

  @override
  String get supportEmailBody => 'Hi Team,\n\n';
}
