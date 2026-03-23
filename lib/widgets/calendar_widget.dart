import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/poop_entry.dart';

class CalendarWidget extends StatelessWidget {
  final List<PoopEntry> entries;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  const CalendarWidget({
    super.key,
    required this.entries,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  List<PoopEntry> _getEntriesForDay(DateTime day) {
    return entries.where((e) => isSameDay(e.timestamp, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TableCalendar<PoopEntry>(
          firstDay: DateTime.utc(2020),
          lastDay: DateTime.now(),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          eventLoader: _getEntriesForDay,
          onDaySelected: (selected, focused) => onDaySelected(selected),
          onPageChanged: onPageChanged,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          rowHeight: 60,
          daysOfWeekHeight: 28,
          // Disable built-in markers — we draw our own inside calendarBuilders
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            markersMaxCount: 0,
            // These only apply to days NOT handled by custom builders,
            // so keep them neutral:
            defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
            weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
            selectedDecoration: const BoxDecoration(shape: BoxShape.circle),
            todayDecoration: const BoxDecoration(shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            weekendStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (ctx, day, focused) => _DayCell(
              day: day,
              count: _getEntriesForDay(day).length,
              isSelected: false,
              isToday: false,
              isWeekend: day.weekday >= 6,
            ),
            selectedBuilder: (ctx, day, focused) => _DayCell(
              day: day,
              count: _getEntriesForDay(day).length,
              isSelected: true,
              isToday: isSameDay(day, DateTime.now()),
              isWeekend: day.weekday >= 6,
            ),
            todayBuilder: (ctx, day, focused) => _DayCell(
              day: day,
              count: _getEntriesForDay(day).length,
              isSelected: isSameDay(selectedDay, day),
              isToday: true,
              isWeekend: day.weekday >= 6,
            ),
            outsideBuilder: (ctx, day, focused) => _DayCell(
              day: day,
              count: 0,
              isSelected: false,
              isToday: false,
              isWeekend: day.weekday >= 6,
              isOutside: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final int count;
  final bool isSelected;
  final bool isToday;
  final bool isWeekend;
  final bool isOutside;

  const _DayCell({
    required this.day,
    required this.count,
    required this.isSelected,
    required this.isToday,
    required this.isWeekend,
    this.isOutside = false,
  });

  @override
  Widget build(BuildContext context) {
    // Background colour logic
    Color? bgColor;
    Color numberColor;
    FontWeight numberWeight = FontWeight.normal;

    if (isSelected) {
      bgColor = const Color(0xFF4CAF50);
      numberColor = Colors.white;
      numberWeight = FontWeight.bold;
    } else if (isToday) {
      bgColor = const Color(0xFFE8F5E9); // very light green tint
      numberColor = const Color(0xFF2E7D32);
      numberWeight = FontWeight.bold;
    } else if (isOutside) {
      numberColor = Colors.grey.shade300;
    } else if (isWeekend) {
      numberColor = Colors.grey.shade500;
    } else {
      numberColor = Colors.black87;
    }

    // Poop dots: small coloured circles (brown), up to 3, then +N text
    final dotCount = count > 3 ? 3 : count;
    final overflow = count > 3 ? count - 3 : 0;

    return SizedBox(
      height: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: const Color(0xFF4CAF50), width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: numberWeight,
                color: numberColor,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 10,
            child: count > 0
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(
                        dotCount,
                        (_) => Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF8D6E63),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      if (overflow > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 1),
                          child: Text(
                            '+$overflow',
                            style: TextStyle(
                              fontSize: 6,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class DayEntriesHeader extends StatelessWidget {
  final DateTime day;
  final int count;

  const DayEntriesHeader({super.key, required this.day, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(day),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF388E3C),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count 💩',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF388E3C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
