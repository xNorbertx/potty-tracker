import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/services/auth_service.dart';

void main() {
  testWidgets('web auth initializes without a native Google client ID',
      (tester) async {
    final auth = AuthService(auth: MockFirebaseAuth());
    await tester.pump();
    expect(auth.currentUser, isNull);
    await auth.signOut();
    await tester.pump();
  }, skip: !kIsWeb);
}
