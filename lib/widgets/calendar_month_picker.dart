import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarMonthPicker extends StatefulWidget {
  final DateTime focusedMonth;
  final DateTime firstMonth;
  final DateTime lastMonth;

  const CalendarMonthPicker({
    super.key,
    required this.focusedMonth,
    required this.firstMonth,
    required this.lastMonth,
  });

  @override
  State<CalendarMonthPicker> createState() => _CalendarMonthPickerState();
}

class _CalendarMonthPickerState extends State<CalendarMonthPicker> {
  late int _year = widget.focusedMonth.year;

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        title: Row(children: [
          IconButton(
            tooltip: 'Previous year',
            onPressed: _year > widget.firstMonth.year
                ? () => setState(() => _year--)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(child: Text('$_year', textAlign: TextAlign.center)),
          IconButton(
            tooltip: 'Next year',
            onPressed: _year < widget.lastMonth.year
                ? () => setState(() => _year++)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
        content: SizedBox(
          width: 320,
          child: Table(children: [
            for (var row = 0; row < 4; row++)
              TableRow(children: [
                for (var column = 1; column <= 3; column++)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: _monthButton(DateTime(_year, row * 3 + column)),
                  ),
              ]),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );

  Widget _monthButton(DateTime month) {
    final enabled =
        !month.isBefore(widget.firstMonth) && !month.isAfter(widget.lastMonth);
    final selected = month.year == widget.focusedMonth.year &&
        month.month == widget.focusedMonth.month;
    return Semantics(
      label: DateFormat.yMMMM().format(month),
      selected: selected,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(48, 48),
          backgroundColor: selected ? const Color(0xFFE8F5E9) : null,
        ),
        onPressed: enabled ? () => Navigator.pop(context, month) : null,
        child: ExcludeSemantics(child: Text(DateFormat.MMM().format(month))),
      ),
    );
  }
}
