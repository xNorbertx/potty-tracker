import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/models/baby.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_color.dart';
import 'package:potty_tracker/models/poop_entry.dart';
import 'package:potty_tracker/models/poop_size.dart';
import 'package:potty_tracker/screens/log_poop_screen.dart';

void main() {
  final baby = Baby(
    id: 'baby-1',
    name: 'Ada',
    ownerUid: 'user-1',
    memberUids: const ['user-1'],
    shareCode: 'ABC123',
    createdAt: DateTime(2024, 1, 1),
  );

  testWidgets('editing opens the log form with saved values', (tester) async {
    final entry = PoopEntry(
      id: 'entry-1',
      babyId: baby.id,
      timestamp: DateTime(2024, 6, 15, 9, 5),
      consistency: Consistency.hard,
      size: PoopSize.large,
      color: PoopColor.brown,
      notes: 'After breakfast',
      createdAt: DateTime(2024, 6, 15),
    );

    await tester.pumpWidget(MaterialApp(
      home: LogPoopScreen(baby: baby, entry: entry),
    ));

    expect(find.text('Edit log'), findsOneWidget);
    expect(find.text('Jun 15, 2024'), findsOneWidget);
    expect(find.text('09:05'), findsOneWidget);
    expect(find.text('After breakfast'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}
