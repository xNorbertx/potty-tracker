// Interactive synthetic diary; all reads and writes stay in memory.
// flutter run -d web-server -t tool/copy_preview.dart --web-port 8093
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:potty_tracker/models/caregiver_profile.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/screens/home_screen.dart';
import 'package:potty_tracker/services/auth_service.dart';
import 'package:potty_tracker/services/firestore_service.dart';
import 'package:potty_tracker/services/verification_service.dart';
import 'package:potty_tracker/theme/app_theme.dart';

class PreviewVerification extends VerificationService {
  PreviewVerification(FakeFirebaseFirestore db) : super(db: db);
  @override
  Future<void> resend() async {}
  @override
  Future<String> createInvitation(String babyId) async => 'DEMO42';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = FakeFirebaseFirestore();
  final diary = FirestoreService(db: db);
  await diary.saveCaregiverProfile(const CaregiverProfile(
      uid: 'preview', name: 'Sam', email: 'sam@example.com'));
  final baby = await diary.addBaby('preview', 'Ada');
  await diary.addBaby('preview', 'Alexander Sebastian Montgomery');
  final now = DateTime.now();
  for (var daysAgo = 0; daysAgo < 14; daysAgo++) {
    await diary.addEntry(
      uid: 'preview',
      babyId: baby.id,
      timestamp: DateTime(now.year, now.month, now.day - daysAgo, 10),
      consistency: Consistency.values[daysAgo % Consistency.values.length],
      loggedByName: 'Sam',
    );
  }
  runApp(MultiProvider(providers: [
    Provider<AuthService>.value(
        value: AuthService(
            auth: MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'preview', email: 'sam@example.com'),
    ))),
    Provider<FirestoreService>.value(value: diary),
    Provider<VerificationService>.value(value: PreviewVerification(db)),
  ], child: MaterialApp(theme: AppTheme.theme, home: const HomeScreen())));
}
