import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/models/achievement.dart';
import 'package:potty_tracker/theme/app_theme.dart';
import 'package:potty_tracker/widgets/achievement_badges.dart';
import '../models/achievement_test.dart' as fixtures;

void main() {
  testWidgets('overview shows placeholders and shared repeat counts',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: AchievementBadges(entries: [
            ...fixtures.streak(14),
            ...fixtures.streak(7, start: DateTime(2026, 2, 1)),
          ]),
        )));
    await tester.pumpAndSettle();
    expect(find.text('×2'), findsOneWidget);
    expect(find.text('×1'), findsOneWidget);
    expect(find.text('Not yet earned'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(3));
  });

  testWidgets('badge row fits a narrow phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Scaffold(
          body: SingleChildScrollView(
              child: AchievementBadges(entries: fixtures.streak(30)))),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple awards share one dismissible celebration',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.theme,
        home: Builder(
          builder: (context) => Scaffold(
              body: TextButton(
                  onPressed: () => showAchievementCelebration(context, 'Ada', [
                        AchievementAward(7, DateTime(2026, 1, 7)),
                        AchievementAward(14, DateTime(2026, 1, 14)),
                      ]),
                  child: const Text('Celebrate'))),
        )));
    await tester.tap(find.text('Celebrate'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('New achievements!'), findsOneWidget);
    await tester.tap(find.text('Lovely!'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
