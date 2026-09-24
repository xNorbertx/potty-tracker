// Store captures use real app widgets and fictional, in-memory data only.
// flutter run -d web-server -t tool/store_preview.dart --web-port 8096 --no-pub
// ?screen=overview or ?screen=log; default is the diary.
// ?capture=true renders a 360x720 phone layout at the viewport's scale.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:potty_tracker/models/caregiver_profile.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_size.dart';
import 'package:potty_tracker/models/poop_color.dart';
import 'package:potty_tracker/screens/home_screen.dart';
import 'package:potty_tracker/screens/baby_overview_screen.dart';
import 'package:potty_tracker/screens/log_poop_screen.dart';
import 'package:potty_tracker/services/auth_service.dart';
import 'package:potty_tracker/services/firestore_service.dart';
import 'package:potty_tracker/services/verification_service.dart';
import 'package:potty_tracker/theme/app_theme.dart';

class StoreVerification extends VerificationService {
  StoreVerification(FakeFirebaseFirestore db) : super(db: db);
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
  final created = await diary.addBaby('preview', 'Ada');
  await diary.addBaby('preview', 'Milo');
  await db.collection('babies').doc(created.id).update({
    'memberUids': ['preview', 'alex'],
    'memberLabels': {'preview': 'Sam', 'alex': 'Alex'},
    'memberEmails': {'preview': 'sam@example.com', 'alex': 'alex@example.com'},
  });
  await db
      .collection('verified_emails')
      .doc('preview')
      .set({'email': 'sam@example.com'});
  final baby = (await diary.babyStream(created.id).first)!;
  final now = DateTime.now();
  for (var daysAgo = 0; daysAgo < 14; daysAgo++) {
    await diary.addEntry(
      uid: daysAgo.isEven ? 'preview' : 'alex',
      babyId: baby.id,
      timestamp: DateTime(now.year, now.month, now.day - daysAgo, 9, 15),
      consistency: daysAgo % 3 == 0 ? Consistency.soft : Consistency.formed,
      size: PoopSize.medium,
      color: PoopColor.brown,
      loggedByName: daysAgo.isEven ? 'Sam' : 'Alex',
      notes: daysAgo == 0 ? 'After breakfast' : null,
    );
  }
  final screen = Uri.base.queryParameters['screen'];
  final capture = Uri.base.queryParameters['capture'] == 'true';
  runApp(MultiProvider(
    providers: [
      Provider<AuthService>.value(
          value: AuthService(
              auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'preview', email: 'sam@example.com'),
      ))),
      Provider<FirestoreService>.value(value: diary),
      Provider<VerificationService>.value(value: StoreVerification(db)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
      initialRoute: screen == 'overview' || screen == 'log' ? '/$screen' : '/',
      routes: {
        '/overview': (_) => BabyOverviewScreen(baby: baby),
        '/log': (_) => LogPoopScreen(baby: baby),
      },
      builder: capture
          ? (context, child) => ColoredBox(
                color: Colors.white,
                child: FittedBox(
                  child: SizedBox(
                    width: 360,
                    height: 720,
                    child: MediaQuery(
                      data: const MediaQueryData(
                          size: Size(360, 720), devicePixelRatio: 3),
                      child: child!,
                    ),
                  ),
                ),
              )
          : null,
    ),
  ));
}
