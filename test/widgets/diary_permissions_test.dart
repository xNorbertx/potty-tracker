import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:potty_tracker/models/baby.dart';
import 'package:potty_tracker/services/auth_service.dart';
import 'package:potty_tracker/services/firestore_service.dart';
import 'package:potty_tracker/services/verification_service.dart';
import 'package:potty_tracker/widgets/delete_diary_button.dart';
import 'package:potty_tracker/widgets/diary_consent.dart';

class _Verification extends VerificationService {
  _Verification(FakeFirebaseFirestore db) : super(db: db);
  bool verified = false;
  int deletions = 0;
  bool fail = false;
  @override
  Future<bool> refresh(String uid, String? email) async => verified;
  @override
  Future<void> deleteDiary(String id) async {
    if (fail) throw StateError('Offline');
    deletions++;
  }
}

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreService diaries;
  late _Verification verification;
  late AuthService auth;
  setUp(() {
    db = FakeFirebaseFirestore();
    diaries = FirestoreService(db: db);
    verification = _Verification(db);
    auth = AuthService(
        auth: MockFirebaseAuth(
            signedIn: true,
            mockUser: MockUser(uid: 'guest', email: 'guest@example.com')));
  });
  Future<void> show(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MultiProvider(
        providers: [
          Provider<AuthService>.value(value: auth),
          Provider<FirestoreService>.value(value: diaries),
          Provider<VerificationService>.value(value: verification),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ));
  Future<Baby> shared() async {
    final baby = await diaries.addBaby('owner', 'Emma', consentGiven: true);
    await db.collection('babies').doc(baby.id).update({
      'memberUids': ['owner', 'guest', 'third']
    });
    return (await diaries.getBaby(baby.id))!;
  }

  testWidgets(
      'unverified caregiver can find deletion, verification and support but cannot delete',
      (tester) async {
    await show(tester, DeleteDiaryButton(baby: await shared()));
    await tester.tap(find.text('Delete diary'));
    await tester.pumpAndSettle();
    expect(find.text('Verify your email first'), findsOneWidget);
    expect(find.text('Resend verification email'), findsOneWidget);
    expect(find.text('Contact support'), findsOneWidget);
    expect(find.text('Delete for everyone'), findsNothing);
    expect(verification.deletions, 0);
  });

  testWidgets(
      'verified non-owner sees shared impact; cancel is safe and confirm invokes server',
      (tester) async {
    verification.verified = true;
    await show(tester, DeleteDiaryButton(baby: await shared()));
    await tester.tap(find.text('Delete diary'));
    await tester.pumpAndSettle();
    expect(find.text("Delete Emma's diary?"), findsOneWidget);
    expect(find.textContaining('other 2 caregivers'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(verification.deletions, 0);
    await tester.tap(find.text('Delete diary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete for everyone'));
    await tester.pumpAndSettle();
    expect(verification.deletions, 1);
  });

  testWidgets('failed deletion preserves the screen and allows retry',
      (tester) async {
    verification.verified = true;
    verification.fail = true;
    await show(tester, DeleteDiaryButton(baby: await shared()));
    await tester.tap(find.text('Delete diary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete for everyone'));
    await tester.pumpAndSettle();
    expect(verification.deletions, 0);
    verification.fail = false;
    await tester.tap(find.text('Delete diary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete for everyone'));
    await tester.pumpAndSettle();
    expect(verification.deletions, 1);
  });

  testWidgets('creating a diary requires an unchecked affirmative consent',
      (tester) async {
    await show(
        tester,
        Builder(
            builder: (ctx) => TextButton(
                onPressed: () => showAddBabyDialog(ctx),
                child: const Text('Create'))));
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Ada');
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        false);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Add baby'))
            .onPressed,
        isNull);
    expect((await db.collection('babies').get()).docs, isEmpty);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add baby'));
    await tester.pumpAndSettle();
    final data = (await db.collection('babies').get()).docs.single.data();
    expect(data['consentVersion'], 1);
    expect(data['consentBy'], 'guest');
    expect(data['consentAt'], isNotNull);
  });

  test('declining consent creates no diary or invite placeholder', () async {
    await expectLater(
        diaries.addBaby('guest', 'Ada', consentGiven: false), throwsStateError);
    expect((await db.collection('babies').get()).docs, isEmpty);
    expect((await db.collection('share_codes').get()).docs, isEmpty);
  });
}
