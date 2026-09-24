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

void main() {
  testWidgets('sign-in clears stale routes and the diary has no back button',
      (tester) async {
    final diary = FirestoreService(db: FakeFirebaseFirestore());
    await diary.saveCaregiverProfile(const CaregiverProfile(
        uid: 'caregiver', name: 'Sam', email: 'sam@example.com'));
    await diary.addBaby('caregiver', 'Ada');
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
