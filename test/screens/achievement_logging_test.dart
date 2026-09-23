import 'dart:async';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:potty_tracker/models/achievement.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_entry.dart';
import 'package:potty_tracker/models/poop_size.dart';
import 'package:potty_tracker/models/poop_color.dart';
import 'package:potty_tracker/screens/log_poop_screen.dart';
import 'package:potty_tracker/services/auth_service.dart';
import 'package:potty_tracker/services/firestore_service.dart';

class ControlledFirestore extends FirestoreService {
  ControlledFirestore() : super(db: FakeFirebaseFirestore());
  Completer<void>? saveGate;
  bool failClaims = false;
  @override
  Future<PoopEntry> addEntry(
      {required String uid,
      required String babyId,
      required DateTime timestamp,
      required Consistency consistency,
      String? loggedByName,
      String? loggedByEmail,
      PoopSize? size,
      PoopColor? color,
      String? notes}) async {
    await saveGate?.future;
    return super.addEntry(
        uid: uid,
        babyId: babyId,
        timestamp: timestamp,
        consistency: consistency,
        loggedByName: loggedByName,
        loggedByEmail: loggedByEmail,
        size: size,
        color: color,
        notes: notes);
  }

  @override
  Future<List<AchievementAward>> claimAchievementCelebrations(
      String babyId, String uid, List<AchievementAward> awards) {
    if (failClaims) throw StateError('Celebration unavailable');
    return super.claimAchievementCelebrations(babyId, uid, awards);
  }
}

void main() {
  for (final outcome in ['success', 'save failure', 'celebration failure']) {
    testWidgets('logging: $outcome', (tester) async {
      final service = ControlledFirestore();
      final baby = await service.addBaby('user', 'Ada');
      final today = DateTime.now();
      for (var i = 1; i <= 6; i++) {
        await service.addEntry(
            uid: 'user',
            babyId: baby.id,
            timestamp: DateTime(today.year, today.month, today.day - i),
            consistency: Consistency.soft);
      }
      final auth = AuthService(
          auth: MockFirebaseAuth(
              signedIn: true,
              mockUser: MockUser(uid: 'user', email: 'parent@example.com')));
      await tester.pumpWidget(MultiProvider(
          providers: [
            Provider<AuthService>.value(value: auth),
            Provider<FirestoreService>.value(value: service),
          ],
          child: MaterialApp(
              home: Builder(
                  builder: (context) => Scaffold(
                        body: TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                    builder: (_) => LogPoopScreen(baby: baby))),
                            child: const Text('Log')),
                      )))));
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Soft/Mushy'));
      await tester.tap(find.text('Soft/Mushy'));
      await tester.ensureVisible(find.text('Save Entry 💾'));
      service.saveGate = Completer<void>();
      service.failClaims = outcome == 'celebration failure';
      await tester.tap(find.text('Save Entry 💾'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('New achievement!'), findsNothing);
      if (outcome == 'save failure') {
        service.saveGate!.completeError(StateError('Save failed'));
      } else {
        service.saveGate!.complete();
      }
      await tester.pumpAndSettle();
      expect((await service.getEntries(baby.id)).length,
          outcome == 'save failure' ? 6 : 7);
      expect(find.text('New achievement!'),
          outcome == 'success' ? findsOneWidget : findsNothing);
      if (outcome == 'success') {
        await tester.tap(find.text('Lovely!'));
        await tester.pumpAndSettle();
      }
      if (outcome != 'save failure') {
        expect(find.text('💩 Poop logged successfully!'), findsOneWidget);
      }
    });
  }
}
