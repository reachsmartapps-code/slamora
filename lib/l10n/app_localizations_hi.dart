// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Slamora';

  @override
  String get profileSettingsTitle => 'प्रोफाइल / सेटिंग्स';

  @override
  String get notificationSettings => 'नोटिफिकेशन सेटिंग्स';

  @override
  String get privacy => 'प्राइवेसी';

  @override
  String get helpSupport => 'हेल्प और सपोर्ट';

  @override
  String get shareApp => 'ऐप शेयर करें';

  @override
  String get deleteAccount => 'अकाउंट डिलीट करें';

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get logOut => 'लॉग आउट';

  @override
  String get trySlamora => 'Slamora आज़माएं';

  @override
  String shareAppMessage(String playStoreUrl) {
    return 'मुझे Slamora मिला, यादें सेव करने, स्लैम बनाने, और अपने लोगों के लिए गिफ्ट या मैसेज आइडिया पाने के लिए एक प्यारा ऐप।\n\nयहां से डाउनलोड करें:\n$playStoreUrl';
  }

  @override
  String get couldNotOpenPrivacy => 'प्राइवेसी पॉलिसी नहीं खुल सकी।';

  @override
  String get couldNotOpenTerms => 'सेवा की शर्तें नहीं खुल सकीं।';

  @override
  String get couldNotOpenEmail => 'ईमेल ऐप नहीं खुल सका।';

  @override
  String get supportEmailSubject => 'Slamora सपोर्ट';

  @override
  String get supportEmailBody => 'Hi Team,\n\n';
}
