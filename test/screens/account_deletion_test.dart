import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:potty_tracker/models/caregiver_profile.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/screens/account_settings_screen.dart';
import 'package:potty_tracker/services/auth_service.dart';
import 'package:potty_tracker/services/firestore_service.dart';
import 'package:potty_tracker/services/verification_service.dart';

class StaleSessionAuth extends AuthService {
  StaleSessionAuth()
      : super(
          auth: MockFirebaseAuth(
            signedIn: true,
            mockUser: MockUser(uid: 'parent', email: 'parent@example.com'),
          ),
        );

  @override
  Future<void> deleteCurrentUser() async {
    throw FirebaseAuthException(code: 'requires-recent-login');
  }
}

void main() {
  testWidgets(
      'failed authentication leaves the account diary and profile intact',
      (tester) async {
    final db = FakeFirebaseFirestore();
    final service = FirestoreService(db: db);
    await service.saveCaregiverProfile(const CaregiverProfile(
        uid: 'parent', name: 'Sam', email: 'parent@example.com'));
    final baby = await service.addBaby('parent', 'Ada');
    await service.addEntry(
      uid: 'parent',
      babyId: baby.id,
      timestamp: DateTime(2026, 9, 24),
      consistency: Consistency.soft,
    );
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<AuthService>.value(value: StaleSessionAuth()),
        Provider<FirestoreService>.value(value: service),
        Provider<VerificationService>.value(value: VerificationService(db: db)),
      ],
      child: MaterialApp(home: AccountSettingsScreen(babies: [baby])),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete account'));
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Please sign in again, then try this action.'),
        findsOneWidget);
    expect((await service.getCaregiverProfile('parent'))?.name, 'Sam');
    expect((await service.babiesStream('parent').first).single.id, baby.id);
    expect((await service.entriesStream(baby.id).first).length, 1);
  });
}
