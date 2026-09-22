import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn? _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        // Web authentication uses Firebase popups, not the native Google plugin.
        _googleSignIn = kIsWeb ? null : (googleSignIn ?? GoogleSignIn());

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  String? get currentUserEmail => _auth.currentUser?.email;

  bool get hasPasswordProvider =>
      _auth.currentUser?.providerData.any(
          (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID) ??
      false;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Returns false when this email address exists but uses only an SSO provider.
  Future<bool> sendPasswordResetEmail(String email) async {
    final methods = await _auth.fetchSignInMethodsForEmail(email.trim());
    if (!methods.contains(EmailAuthProvider.PROVIDER_ID)) return false;
    await _auth.sendPasswordResetEmail(email: email.trim());
    return true;
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      return await _auth.signInWithPopup(googleProvider);
    } else {
      final googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    }
  }

  Future<UserCredential?> signInWithMicrosoft() async {
    final microsoftProvider = OAuthProvider('microsoft.com');
    microsoftProvider.setCustomParameters({
      'prompt': 'select_account',
      'tenant': 'common',
    });
    // Both web and Android use popup/redirect via Firebase
    return await _auth.signInWithPopup(microsoftProvider);
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      if (!kIsWeb) _googleSignIn!.signOut(),
    ]);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || !hasPasswordProvider) {
      throw StateError('This account does not have a password.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in account.');
    await user.delete();
  }
}
