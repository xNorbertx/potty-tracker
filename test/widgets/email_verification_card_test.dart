import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:potty_tracker/services/auth_service.dart';
import 'package:potty_tracker/services/verification_service.dart';
import 'package:potty_tracker/widgets/email_verification_card.dart';

class FakeVerificationService extends VerificationService {
  FakeVerificationService(FakeFirebaseFirestore db) : super(db: db);
  int sends = 0;
  @override
  Future<void> resend() async {
    sends++;
  }
}

void main() {
  testWidgets(
      'SSO flag stays locked until app proof arrives, resend is available',
      (tester) async {
    final db = FakeFirebaseFirestore();
    final verification = FakeVerificationService(db);
    final user = MockUser(
        uid: 'parent', email: 'parent@example.com', isEmailVerified: true);
    final auth =
        AuthService(auth: MockFirebaseAuth(mockUser: user, signedIn: true));
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<AuthService>.value(value: auth),
          Provider<VerificationService>.value(value: verification),
        ],
        child:
            const MaterialApp(home: Scaffold(body: EmailVerificationCard()))));
    await tester.pumpAndSettle();
    expect(find.text('Verify your email'), findsOneWidget);
    await tester.tap(find.text('Resend verification email'));
    await tester.pumpAndSettle();
    expect(verification.sends, 1);
    expect(find.textContaining('Verification email sent'), findsOneWidget);
    await db
        .collection('verified_emails')
        .doc('parent')
        .set({'email': user.email});
    await tester.pumpAndSettle();
    expect(find.text('Email verified'), findsOneWidget);
    expect(find.text('Resend verification email'), findsNothing);
  });

  test('proof for a previous email does not verify a changed address',
      () async {
    final db = FakeFirebaseFirestore();
    await db
        .collection('verified_emails')
        .doc('parent')
        .set({'email': 'old@example.com'});
    final service = VerificationService(db: db);
    expect(
        await service.verifiedStream('parent', 'new@example.com').first, false);
  });
}
