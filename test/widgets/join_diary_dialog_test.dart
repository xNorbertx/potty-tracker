import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:potty_tracker/models/baby.dart';
import 'package:potty_tracker/services/auth_service.dart';
import 'package:potty_tracker/services/firestore_service.dart';
import 'package:potty_tracker/widgets/join_diary_dialog.dart';

void main() {
  testWidgets(
      'join survives its launching page being replaced and ignores repeated taps',
      (tester) async {
    final db = FakeFirebaseFirestore();
    final pending = Completer<String>();
    var calls = 0;
    final service = FirestoreService(
        db: db,
        acceptInvitation: (_) {
          calls++;
          return pending.future;
        });
    final baby = await service.addBaby('owner', 'Ada', consentGiven: true);
    final replaced = ValueNotifier(false);
    Baby? result;
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<AuthService>.value(
              value: AuthService(
                  auth: MockFirebaseAuth(
                      signedIn: true,
                      mockUser: MockUser(
                          uid: 'guest', email: 'guest@example.test')))),
          Provider<FirestoreService>.value(value: service),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: ValueListenableBuilder<bool>(
          valueListenable: replaced,
          builder: (context, changed, _) => changed
              ? const Text('Diary loaded')
              : TextButton(
                  onPressed: () async {
                    result = await showJoinDiaryDialog(context);
                  },
                  child: const Text('Open join')),
        )))));
    await tester.tap(find.text('Open join'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'abc234');
    await tester.tap(find.text('Join baby'));
    await tester.tap(find.text('Join baby'));
    await tester.pump();
    expect(calls, 1);
    expect(find.text('Joining…'), findsOneWidget);
    replaced.value = true;
    await tester.pump();
    pending.complete(baby.id);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Diary loaded'), findsOneWidget);
    expect(result?.id, baby.id);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    replaced.dispose();
  });

  testWidgets(
      'invalid and throttled invitations show inline errors and allow cancellation',
      (tester) async {
    final db = FakeFirebaseFirestore();
    var calls = 0;
    final service = FirestoreService(
        db: db,
        acceptInvitation: (_) async {
          calls++;
          throw FirebaseFunctionsException(
              code: 'resource-exhausted',
              message:
                  'Too many invitation attempts. Try again in 10 minutes.');
        });
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<AuthService>.value(
              value: AuthService(
                  auth: MockFirebaseAuth(
                      signedIn: true,
                      mockUser: MockUser(
                          uid: 'guest', email: 'guest@example.test')))),
          Provider<FirestoreService>.value(value: service),
        ],
        child: MaterialApp(
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => showJoinDiaryDialog(context),
                        child: const Text('Open join')))))));
    await tester.tap(find.text('Open join'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join baby'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the 6-character invite code'), findsOneWidget);
    expect(calls, 0);
    await tester.enterText(find.byType(TextField), 'ZZZ234');
    await tester.tap(find.text('Join baby'));
    await tester.pumpAndSettle();
    expect(find.text('Too many invitation attempts. Try again in 10 minutes.'),
        findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
