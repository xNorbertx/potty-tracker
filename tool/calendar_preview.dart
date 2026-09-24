// Synthetic preview; no Firebase connection.
import 'package:flutter/material.dart';
import 'package:potty_tracker/theme/app_theme.dart';
import 'package:potty_tracker/widgets/calendar_widget.dart';

void main() =>
    runApp(MaterialApp(theme: AppTheme.theme, home: const Preview()));

class Preview extends StatefulWidget {
  const Preview({super.key});
  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  DateTime focused = DateTime.now();
  DateTime selected = DateTime.now();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Calendar preview')),
        body: SingleChildScrollView(
            child: Column(children: [
          CalendarWidget(
              entries: const [],
              focusedDay: focused,
              selectedDay: selected,
              onPageChanged: (day) => setState(() => focused = day),
              onDaySelected: (day) => setState(() {
                    selected = day;
                    focused = day;
                  })),
          DayEntriesHeader(day: selected, count: 0),
        ])),
      );
}
