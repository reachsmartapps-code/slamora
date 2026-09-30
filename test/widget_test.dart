import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slamora/app/app.dart';
import 'package:slamora/app/theme/app_theme.dart';
import 'package:slamora/core/formatters/capitalize_first_letter_formatter.dart';
import 'package:slamora/core/services/invite_link_service.dart';
import 'package:slamora/core/services/reminder_notification_service.dart';
import 'package:slamora/features/create_slam/presentation/screens/create_slam_flow_screen.dart';
import 'package:slamora/features/home/presentation/screens/home_screen.dart';
import 'package:slamora/l10n/app_localizations.dart';

void main() {
  test('CapitalizeFirstLetterFormatter capitalizes first typed letter', () {
    const formatter = CapitalizeFirstLetterFormatter();
    final value = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '  neha',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );

    expect(value.text, '  Neha');
    expect(value.selection.baseOffset, 6);
  });

  test(
    'ReminderNotificationService creates future reminder date and stable id',
    () {
      final service = ReminderNotificationService.instance;
      final reminderDate = service.nextReminderDate('12 Sep 1995', 1);
      final firstId = service.notificationId(
        slamId: 'slam-1',
        reminderType: 'birthday',
      );
      final secondId = service.notificationId(
        slamId: 'slam-1',
        reminderType: 'birthday',
      );

      expect(reminderDate, isNotNull);
      expect(reminderDate!.isAfter(DateTime.now()), isTrue);
      expect(firstId, secondId);
    },
  );

  test('InviteLinkService parses supported invite links', () {
    final service = InviteLinkService.instance;

    expect(
      service.parseInviteCode(Uri.parse('https://slamora.com/i/AbC123')),
      'AbC123',
    );
    expect(
      service.parseInviteCode(Uri.parse('slamora://invite/AbC123')),
      'AbC123',
    );
    expect(
      service.parseInviteCode(Uri.parse('https://slamora.com/x/AbC123')),
      isNull,
    );
    expect(service.parseInviteCodeFromReferrer('invite_code=AbC123'), 'AbC123');
    expect(
      service.parseInviteCodeFromReferrer('utm_source=whatsapp&invite_code=Z9'),
      'Z9',
    );
  });

  Future<void> openHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Auth screen opens on Login tab and switches to Sign Up', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('WELCOME TO'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Sign Up').first);
    await tester.pumpAndSettle();

    expect(find.text('JOIN'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home screen loads', (WidgetTester tester) async {
    await openHome(tester);

    expect(find.text('Hi Alex 👋'), findsOneWidget);
    expect(find.text('Upcoming Occasions'), findsOneWidget);
    expect(find.text('Find Gift Ideas ✨'), findsOneWidget);
  });

  testWidgets('Home screen fits Pixel 3 width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openHome(tester);

    expect(find.text('Hi Alex 👋'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My Slam opens from bottom navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openHome(tester);
    await tester.tap(find.byKey(const ValueKey('home-nav-my-slam')));
    await tester.pumpAndSettle();

    expect(find.text('My Slam'), findsWidgets);
    expect(find.text('Amit Sharma'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invite friend opens from Home card', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openHome(tester);
    await tester.tap(find.text('Invite a Friend'));
    await tester.pumpAndSettle();

    expect(find.text('Share the joy'), findsOneWidget);
    expect(find.text('Share on WhatsApp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home opens gift and message idea screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openHome(tester);
    await tester.tap(find.text('Find Gift Ideas ✨'));
    await tester.pumpAndSettle();

    expect(find.text('Gift Ideas'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message Ideas ✨'));
    await tester.pumpAndSettle();

    expect(find.text('Message Ideas'), findsOneWidget);
    expect(find.text('Ready to send'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile opens from bottom navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openHome(tester);
    await tester.tap(find.byKey(const ValueKey('home-nav-profile')));
    await tester.pumpAndSettle();

    expect(find.text('Profile / Settings'), findsOneWidget);
    expect(find.text('Alex Sharma'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Log out dialog opens from Profile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openHome(tester);
    await tester.tap(find.byKey(const ValueKey('home-nav-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(find.text('Log out of Slamora?'), findsOneWidget);
    expect(find.text('Stay'), findsOneWidget);
    expect(
      find.text(
        'Your memories will stay safe. You can come back and continue anytime.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();

    expect(find.text('Log out of Slamora?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Create slam asks before closing on device back', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openHome(tester);
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Create a slam for your friend'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Close create slam?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(find.text('Close create slam?'), findsNothing);
    expect(find.text('Create a slam for your friend'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Hi Alex 👋'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Create slam flow skips step 4 and saves to Home', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openHome(tester);
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Create a slam for your friend'), findsOneWidget);
    expect(find.text('Profile picture'), findsOneWidget);
    expect(find.text("Enter friend's full name"), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter full name.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    await tester.enterText(find.byType(TextField).at(0), 'Riya Kapoor');
    await tester.enterText(find.byType(TextField).at(1), 'Riya');
    await tester.enterText(find.byType(TextField).at(2), 'Best friend');
    await tester.ensureVisible(find.byType(TextField).at(3));
    await tester.tap(find.byType(TextField).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What are they into?'), findsOneWidget);
    await tester.tap(find.text('Photography'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add another'));
    await tester.pumpAndSettle();
    expect(find.text('Add interest'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Dancing');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Dancing'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Their favourites'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Pasta');
    await tester.enterText(find.byType(TextField).at(1), 'Peach');
    await tester.enterText(find.byType(TextField).at(2), 'Interstellar');
    await tester.enterText(find.byType(TextField).at(4), 'Switzerland');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Step 4 of 6'), findsNothing);
    expect(find.text('A few heartfelt notes'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).at(0),
      'That birthday surprise was unforgettable.',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'You make people feel seen.',
    );
    await tester.enterText(
      find.byType(TextField).at(2),
      'Thank you for being you.',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Add their photos'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Review your slam'), findsOneWidget);
    expect(find.text('Riya Kapoor, 12 Sep 1995'), findsOneWidget);
    expect(find.textContaining('Photography'), findsOneWidget);
    expect(find.textContaining('Dancing'), findsOneWidget);
    expect(find.text('Pasta, Peach'), findsOneWidget);
    expect(
      find.text('That birthday surprise was unforgettable.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Save This Memory'));
    await tester.pumpAndSettle();

    expect(find.text('Hi Alex 👋'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invite create slam flow hides profile picture option', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const CreateSlamFlowScreen(inviteCode: 'abc123'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Let's get to know you"), findsOneWidget);
    expect(find.text('Enter full name'), findsOneWidget);
    expect(find.text('Profile picture'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My Slam list item opens detail screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openHome(tester);
    await tester.tap(find.byKey(const ValueKey('home-nav-my-slam')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('my-slam-person-Neha Verma')));
    await tester.pumpAndSettle();

    expect(find.text('Neha Verma'), findsWidgets);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Birthday reminder'), findsOneWidget);
    expect(find.text('About Neha'), findsOneWidget);
    expect(find.text('Interests & Preferences'), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.text('Recent Moments'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
