// Uses the actual app with isolated local Auth, Firestore and Functions emulators.
// flutter run -d web-server -t tool/security_preview.dart --web-port 8096
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:potty_tracker/main.dart' show PottyTrackerApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:123:web:qa',
    messagingSenderId: '123',
    projectId: 'demo-potty-tracker',
    authDomain: 'localhost',
  ));
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
  runApp(const PottyTrackerApp());
}
