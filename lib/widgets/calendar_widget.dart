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
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            markersMaxCount: 6,
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
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return const SizedBox.shrink();
              final count = events.length;
              final dotCount = count > 3 ? 3 : count;
              final overflow = count - dotCount;
              final bool isSelectedDay =
                  selectedDay != null && isSameDay(day, selectedDay);

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
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
                          color: isSelectedDay
                              ? Colors.white
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
                            color: isSelectedDay
                                ? Colors.white
                                : const Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            defaultBuilder: (ctx, day, focused) => _DayCell(
              day: day,
              isSelected: false,
              isToday: false,
              isWeekend: day.weekday >= 6,
            ),
            selectedBuilder: (ctx, day, focused) => _DayCell(
              day: day,
              isSelected: true,
              isToday: isSameDay(day, DateTime.now()),
              isWeekend: day.weekday >= 6,
            ),
            todayBuilder: (ctx, day, focused) => _DayCell(
              day: day,
              isSelected: isSameDay(selectedDay, day),
              isToday: true,
              isWeekend: day.weekday >= 6,
            ),
            outsideBuilder: (ctx, day, focused) => _DayCell(
              day: day,
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
  final bool isSelected;
  final bool isToday;
  final bool isWeekend;
  final bool isOutside;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isWeekend,
    this.isOutside = false,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color numberColor;
    FontWeight numberWeight = FontWeight.normal;

    if (isSelected) {
      bgColor = const Color(0xFF4CAF50);
      numberColor = Colors.white;
      numberWeight = FontWeight.bold;
    } else if (isToday) {
      bgColor = const Color(0xFFE8F5E9);
      numberColor = const Color(0xFF2E7D32);
      numberWeight = FontWeight.bold;
    } else if (isOutside) {
      numberColor = Colors.grey.shade300;
    } else if (isWeekend) {
      numberColor = Colors.grey.shade500;
    } else {
      numberColor = Colors.black87;
    }

    return Center(
      child: Container(
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
