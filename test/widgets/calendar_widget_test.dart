import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_entry.dart';
import 'package:potty_tracker/widgets/calendar_widget.dart';

void main() {
  testWidgets('shows event markers for the selected day', (tester) async {
    final selectedDay = DateTime.now();
    final entries = List.generate(
      2,
      (index) => PoopEntry(
        id: '$index',
        babyId: 'baby',
        timestamp: selectedDay.add(Duration(hours: index)),
        consistency: Consistency.soft,
        createdAt: selectedDay,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarWidget(
            entries: entries,
            focusedDay: selectedDay,
            selectedDay: selectedDay,
            onDaySelected: (_) {},
            onPageChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(ValueKey('event-marker-${DateUtils.dateOnly(selectedDay)}')),
      findsOneWidget,
    );
  });
}
