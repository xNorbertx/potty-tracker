import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/connection_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/app_status.dart';
import 'l10n/app_locale.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PottyTrackerApp());
}

class PottyTrackerApp extends StatelessWidget {
  const PottyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<ConnectionService>(create: (_) => ConnectionService()),
      ],
      child: AppLocale(
        language: AppLanguage.english,
        child: MaterialApp(
        title: 'Potty Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppLanguage.values.map((language) => language.locale),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
        },
        builder: (context, child) => ConnectionStatusBanner(
          child: child ?? const SizedBox.shrink(),
        ),
        ),
      ),
    );
  }
}
