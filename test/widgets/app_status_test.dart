import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/services/connection_service.dart';
import 'package:potty_tracker/widgets/app_status.dart';
import 'package:provider/provider.dart';

void main() {
  test('turns common Firebase errors into useful messages', () {
    expect(
      friendlyError(Exception('permission-denied')),
      'You do not have permission to do that.',
    );
    expect(
      friendlyError(Exception('network-request-failed')),
      'Check your internet connection and try again.',
    );
    expect(
      friendlyError(Exception('unrecognised problem')),
      'Something went wrong. Please try again.',
    );
  });

  testWidgets('shows an offline banner and keeps the app available',
      (tester) async {
    final changes = StreamController<List<ConnectivityResult>>();
    addTearDown(changes.close);
    final connection = ConnectionService(changes: changes.stream);

    await tester.pumpWidget(
      Provider<ConnectionService>.value(
        value: connection,
        child: const MaterialApp(
          home: ConnectionStatusBanner(child: Scaffold(body: Text('Diary'))),
        ),
      ),
    );

    changes.add([ConnectivityResult.none]);
    await tester.pump();

    expect(
        find.text("You're offline. Changes will sync when you're back online."),
        findsOneWidget);
    expect(find.text('Diary'), findsOneWidget);
  });

  testWidgets('error view calls retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppErrorView(
          message: 'Check your internet connection and try again.',
          onRetry: () => retried = true,
        ),
      ),
    ));

    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });
}
