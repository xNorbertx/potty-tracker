import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:potty_tracker/models/caregiver_profile.dart';
import 'package:potty_tracker/models/poop_entry.dart';
import 'package:potty_tracker/screens/baby_overview_screen.dart';
import 'package:potty_tracker/screens/baby_settings_screen.dart';
import 'package:potty_tracker/screens/home_screen.dart';
import 'package:potty_tracker/services/auth_service.dart';
import 'package:potty_tracker/services/firestore_service.dart';
import 'package:potty_tracker/services/verification_service.dart';
import 'package:potty_tracker/widgets/app_status.dart';
import 'package:potty_tracker/widgets/delete_diary_button.dart';

// Fake Firestore resolves timestamps immediately. Model the real SDK's local
// snapshot first, then the server acknowledgement, and reject premature reads.
class _DelayedConsent extends FirestoreService {
  final FakeFirebaseFirestore db;
  final acknowledgement = Completer<void>();
  bool committed = false;
  int prematureReads = 0;
  int entryReads = 0;

  _DelayedConsent(this.db) : super(db: db);

  @override
  Future<void> acceptDiaryConsent(String babyId, String uid) async {
    final document = db.collection('babies').doc(babyId);
    await document.update({
      'consentVersion': 1,
      'consentBy': uid,
      'consentAt': null,
    });
    await acknowledgement.future;
    committed = true;
    await document.update({'consentAt': Timestamp.now()});
  }

  @override
  Stream<List<PoopEntry>> entriesStream(String babyId) {
    entryReads++;
    if (!committed) {
      prematureReads++;
      return Stream.error(FirebaseException(
          plugin: 'cloud_firestore', code: 'permission-denied'));
    }
    return super.entriesStream(babyId);
  }
}

void main() {
  for (final detail in [false, true]) {
    testWidgets(
        '${detail ? 'detail' : 'calendar'} waits for saved consent and opens without refresh',
        (tester) async {
      final db = FakeFirebaseFirestore();
      final diaries = _DelayedConsent(db);
      await diaries.saveCaregiverProfile(const CaregiverProfile(
          uid: 'owner', name: 'Sam', email: 'sam@example.com'));
      await db.collection('babies').doc('baby').set({
        'name': 'Ada',
        'ownerUid': 'owner',
        'memberUids': ['owner'],
        'createdAt': Timestamp.now(),
      });
      final baby = (await diaries.getBaby('baby'))!;
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<AuthService>.value(
              value: AuthService(
                  auth: MockFirebaseAuth(
                      signedIn: true,
                      mockUser:
                          MockUser(uid: 'owner', email: 'sam@example.com')))),
          Provider<FirestoreService>.value(value: diaries),
          Provider<VerificationService>.value(
              value: VerificationService(db: db)),
        ],
        child: MaterialApp(
            home: detail ? BabyOverviewScreen(baby: baby) : const HomeScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Permission to keep this diary'), findsOneWidget);
      expect(find.byType(DeleteDiaryButton),
          detail ? findsOneWidget : findsNothing);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Saving…'), findsOneWidget);
      expect(diaries.entryReads, 0);
      expect(find.byType(AppErrorView), findsNothing);

      diaries.acknowledgement.complete();
      await tester.pumpAndSettle();
      expect(diaries.prematureReads, 0);
      expect(diaries.entryReads, greaterThan(0));
      expect(find.text('Permission to keep this diary'), findsNothing);
      expect(find.text(detail ? 'Achievements' : 'No entries for this day'),
          findsOneWidget);
      expect(find.byType(AppErrorView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Your babies has no delete action; detail has a danger zone before consent',
      (tester) async {
    final db = FakeFirebaseFirestore();
    final diaries = FirestoreService(db: db);
    await db.collection('babies').doc('baby').set({
      'name': 'Ada',
      'ownerUid': 'owner',
      'memberUids': ['owner'],
      'createdAt': Timestamp.now(),
    });
    final baby = (await diaries.getBaby('baby'))!;
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<AuthService>.value(
            value: AuthService(
                auth: MockFirebaseAuth(
                    signedIn: true, mockUser: MockUser(uid: 'owner')))),
        Provider<FirestoreService>.value(value: diaries),
      ],
      child: MaterialApp(
          home: BabySettingsScreen(babies: [baby], selectedBabyId: baby.id)),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteDiaryButton), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    await tester.tap(find.text('Ada'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete diary'), 150);
    expect(find.text('Danger zone'), findsOneWidget);
    expect(
        find.ancestor(
            of: find.text('Delete diary'), matching: find.byType(Card)),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
