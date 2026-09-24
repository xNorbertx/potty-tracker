import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_entry.dart';
import 'package:potty_tracker/widgets/calendar_widget.dart';
import 'package:potty_tracker/widgets/calendar_month_picker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

void main() {
  Finder button(String tooltip) =>
      find.byWidgetPredicate((w) => w is IconButton && w.tooltip == tooltip);
  final today = DateUtils.dateOnly(DateTime.now());

  Widget calendar(
      {DateTime? initial, DateTime? selectedDay, double scale = 1}) {
    var focused = initial ?? today;
    var selected = selectedDay ?? focused;
    return MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
      builder: (context, setState) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: SingleChildScrollView(
            child: CalendarWidget(
          entries: const [],
          focusedDay: focused,
          selectedDay: selected,
          onPageChanged: (day) => setState(() => focused = day),
          onDaySelected: (day) => setState(() {
            selected = day;
            focused = day;
          }),
        )),
      ),
    )));
  }

  TextButton todayButton(WidgetTester tester) => tester.widget<TextButton>(
      find.ancestor(of: find.text('Today'), matching: find.byType(TextButton)));

  testWidgets('jump to a month in an older year, then return to today',
      (tester) async {
    await tester.pumpWidget(calendar());
    expect(todayButton(tester).onPressed, isNull);
    await tester.tap(find.text(DateFormat.yMMMM().format(today)));
    await tester.pumpAndSettle();
    await tester.tap(button('Previous year'));
    await tester.pumpAndSettle();
    expect(find.text('${today.year - 1}'), findsOneWidget);
    await tester.tap(find.text('Feb'));
    await tester.pumpAndSettle();
    var table = tester.widget<TableCalendar<PoopEntry>>(
        find.byType(TableCalendar<PoopEntry>));
    expect(table.focusedDay.year, today.year - 1);
    expect(table.focusedDay.month, 2);
    // Browsing does not silently change the selected diary day.
    expect(table.selectedDayPredicate!(today), isTrue);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    table = tester.widget<TableCalendar<PoopEntry>>(
        find.byType(TableCalendar<PoopEntry>));
    expect(isSameDay(table.focusedDay, today), isTrue);
    expect(table.selectedDayPredicate!(today), isTrue);
    expect(todayButton(tester).onPressed, isNull);
  });

  testWidgets(
      'month picker disables future months and years, and supports cancel',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showDialog<DateTime>(
                          context: context,
                          builder: (_) => CalendarMonthPicker(
                              focusedMonth: DateTime(2026, 9),
                              firstMonth: DateTime(2020),
                              lastMonth: DateTime(2026, 9))),
                      child: const Text('Open')),
                ))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    TextButton month(String label) => tester.widget<TextButton>(
        find.ancestor(of: find.text(label), matching: find.byType(TextButton)));
    expect(month('Sep').onPressed, isNotNull);
    for (final label in ['Oct', 'Nov', 'Dec']) {
      expect(month(label).onPressed, isNull);
    }
    expect(tester.widget<IconButton>(button('Next year')).onPressed, isNull);
    await tester.tap(button('Previous year'));
    await tester.pumpAndSettle();
    expect(month('Dec').onPressed, isNotNull);
    await tester.tap(button('Next year'));
    await tester.pumpAndSettle();
    expect(month('Dec').onPressed, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarMonthPicker), findsNothing);
  });

  testWidgets('arrows and swipe keep navigation within past and present months',
      (tester) async {
    await tester.pumpWidget(calendar());
    expect(tester.widget<IconButton>(button('Next month')).onPressed, isNull);
    final tableFinder = find.byType(TableCalendar<PoopEntry>);
    await tester.drag(tableFinder, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TableCalendar<PoopEntry>>(tableFinder).focusedDay.month,
        today.month);
    await tester.tap(button('Previous month'));
    await tester.pumpAndSettle();
    final previous = DateTime(today.year, today.month - 1);
    expect(find.text(DateFormat.yMMMM().format(previous)), findsOneWidget);
    await tester.drag(tableFinder, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text(DateFormat.yMMMM().format(today)), findsOneWidget);
    expect(
        isSameDay(tester.widget<TableCalendar<PoopEntry>>(tableFinder).lastDay,
            today),
        isTrue);
  });

  testWidgets('Today also selects today from another day in the current month',
      (tester) async {
    final other = today.day > 1
        ? today.subtract(const Duration(days: 1))
        : DateTime(today.year, today.month - 1, 1);
    await tester.pumpWidget(calendar(initial: other));
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    final table = tester.widget<TableCalendar<PoopEntry>>(
        find.byType(TableCalendar<PoopEntry>));
    expect(table.selectedDayPredicate!(today), isTrue);
    expect(todayButton(tester).onPressed, isNull);
  });

  testWidgets('Today never moves the heading or calendar on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(calendar(
        selectedDay: today.subtract(const Duration(days: 1)), scale: 2));
    final heading = find.text(DateFormat.yMMMM().format(today));
    final grid = find.byType(TableCalendar<PoopEntry>);
    final headingBefore = tester.getRect(heading);
    final gridBefore = tester.getRect(grid);
    final cardBefore = tester.getRect(find.byType(Card));
    final todayBefore = tester.getRect(find.text('Today'));
    expect(todayButton(tester).onPressed, isNotNull);
    expect(find.byIcon(Icons.expand_more), findsNothing);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(todayButton(tester).onPressed, isNull);
    expect(tester.getRect(heading), headingBefore);
    expect(tester.getRect(grid), gridBefore);
    expect(tester.getRect(find.byType(Card)), cardBefore);
    expect(tester.getRect(find.text('Today')), todayBefore);
    expect(tester.takeException(), isNull);
  });

  testWidgets('earliest year is bounded and picker fits narrow enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(calendar(initial: DateTime(2020), scale: 2));
    expect(
        tester.widget<IconButton>(button('Previous month')).onPressed, isNull);
    await tester.tap(find.text('January 2020'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<IconButton>(button('Previous year')).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

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
