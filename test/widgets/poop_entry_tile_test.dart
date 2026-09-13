import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_color.dart';
import 'package:potty_tracker/models/poop_entry.dart';
import 'package:potty_tracker/models/poop_size.dart';
import 'package:potty_tracker/widgets/poop_entry_tile.dart';

void main() {
  final entry = PoopEntry(
    id: 'entry-1',
    babyId: 'baby-1',
    timestamp: DateTime(2024, 6, 15, 9, 5),
    consistency: Consistency.soft,
    size: PoopSize.medium,
    color: PoopColor.mustardYellow,
    notes: 'After breakfast',
    createdAt: DateTime(2024, 6, 15),
  );

  Widget app(VoidCallback onDelete, {VoidCallback? onEdit}) => MaterialApp(
        home: Scaffold(
          body: PoopEntryTile(
            entry: entry,
            onDelete: onDelete,
            onEdit: onEdit ?? () {},
          ),
        ),
      );

  testWidgets('shows entry details', (tester) async {
    await tester.pumpWidget(app(() {}));

    expect(find.text('Soft/Mushy'), findsOneWidget);
    expect(find.text('After breakfast'), findsOneWidget);
    expect(find.text('09:05'), findsOneWidget);
  });

  testWidgets('asks before deletion and only deletes after confirmation',
      (tester) async {
    var deletes = 0;
    await tester.pumpWidget(app(() => deletes++));

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Edit or delete entry?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deletes, 0);

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deletes, 1);
  });

  testWidgets('opens editing without deleting the entry', (tester) async {
    var edits = 0;
    var deletes = 0;
    await tester.pumpWidget(app(() => deletes++, onEdit: () => edits++));

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(edits, 1);
    expect(deletes, 0);
    expect(find.byType(Dismissible), findsOneWidget);
  });
}
