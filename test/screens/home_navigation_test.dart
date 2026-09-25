import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:potty_tracker/models/caregiver_profile.dart';
import 'package:potty_tracker/screens/home_screen.dart';
import 'package:potty_tracker/screens/login_screen.dart';
import 'package:potty_tracker/services/auth_service.dart';
import 'package:potty_tracker/services/firestore_service.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/widgets/diary_title.dart';

void main() {
  testWidgets('centered diary title switches babies while preserving the day',
      (tester) async {
    tester.view.physicalSize = const Size(480, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final diary = FirestoreService(db: FakeFirebaseFirestore());
    await diary.saveCaregiverProfile(const CaregiverProfile(
        uid: 'caregiver', name: 'Sam', email: 'sam@example.com'));
    final first = await diary.addBaby('caregiver', 'Ada', consentGiven: true);
    final second = await diary.addBaby(
        'caregiver', 'Alexander Sebastian Montgomery',
        consentGiven: true);
    for (final baby in [first, second]) {
      await diary.addEntry(
          uid: 'caregiver',
          babyId: baby.id,
          timestamp: DateTime.now(),
          consistency: Consistency.soft,
          notes: baby.id == first.id ? 'First diary' : 'Second diary');
    }
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<AuthService>.value(
            value: AuthService(
                auth: MockFirebaseAuth(
                    signedIn: true, mockUser: MockUser(uid: 'caregiver')))),
        Provider<FirestoreService>.value(value: diary),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.switch_account), findsNothing);
    final title = tester.widget<DiaryTitle>(find.byType(DiaryTitle));
    final initialNote =
        title.baby.id == first.id ? 'First diary' : 'Second diary';
    final otherNote =
        title.baby.id == first.id ? 'Second diary' : 'First diary';
    expect(find.text(initialNote), findsOneWidget);
    final other = title.baby.id == first.id ? second : first;
    expect(tester.getCenter(find.byType(DiaryTitle)).dx, 240);
    await tester.tap(find.byType(DiaryTitle));
    await tester.pumpAndSettle();
    final popup = tester.getRect(find.descendant(
        of: find.byType(Dialog), matching: find.byType(Material)));
    expect(popup.center, const Offset(240, 422));
    await tester.tap(find.text(other.name));
    await tester.pumpAndSettle();
    expect(find.text("${other.name}'s diary"), findsOneWidget);
    expect(find.text(otherNote), findsOneWidget);
    expect(find.text(initialNote), findsNothing);
    expect(tester.getCenter(find.byType(DiaryTitle)).dx, 240);
    await tester.tap(find.byType(DiaryTitle));
    await tester.pumpAndSettle();
    expect(
        tester.getRect(find.descendant(
            of: find.byType(Dialog), matching: find.byType(Material))),
        popup);
    // Dismissing the picker leaves the current diary selected.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text("${other.name}'s diary"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-in clears stale routes and the diary has no back button',
      (tester) async {
    final diary = FirestoreService(db: FakeFirebaseFirestore());
    await diary.saveCaregiverProfile(const CaregiverProfile(
        uid: 'caregiver', name: 'Sam', email: 'sam@example.com'));
    await diary.addBaby('caregiver', 'Ada', consentGiven: true);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<AuthService>.value(
            value: AuthService(
                auth: MockFirebaseAuth(
                    mockUser:
                        MockUser(uid: 'caregiver', email: 'sam@example.com')))),
        Provider<FirestoreService>.value(value: diary),
      ],
      child: MaterialApp(
        navigatorKey: navigator,
        initialRoute: '/login',
        routes: {
          '/': (_) => const Scaffold(body: Text('Stale loading screen')),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
        },
      ),
    ));
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isTrue);
    await tester.enterText(find.byType(TextFormField).at(0), 'sam@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text("Ada's diary"), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    await tester.tap(find.text("Ada's diary"));
    await tester.pumpAndSettle();
    expect(find.byType(BabyDiaryPicker), findsNothing);
    expect(navigator.currentState!.canPop(), isFalse);
    expect(await navigator.currentState!.maybePop(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Stale loading screen'), findsNothing);
    expect(find.text("Ada's diary"), findsOneWidget);

    // Detail screens still return to the diary normally.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text("Ada's diary"), findsOneWidget);
    expect(navigator.currentState!.canPop(), isFalse);
  });
}
