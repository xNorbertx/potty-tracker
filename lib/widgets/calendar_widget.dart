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
      margin: const EdgeInsets.all(12),
      child: TableCalendar<PoopEntry>(
        firstDay: DateTime.utc(2020),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        eventLoader: _getEntriesForDay,
        onDaySelected: (selected, focused) => onDaySelected(selected),
        onPageChanged: onPageChanged,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        rowHeight: 52,
        daysOfWeekHeight: 24,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
          // Hide default dot markers — we use custom builder below
          markersMaxCount: 0,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();

            final count = events.length;
            // Show up to 3 poop emojis, then "+N" for more
            final displayCount = count > 3 ? 3 : count;
            final overflow = count > 3 ? count - 3 : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '💩' * displayCount,
                    style: const TextStyle(fontSize: 7, height: 1),
                  ),
                  if (overflow > 0)
                    Text(
                      '+$overflow',
                      style: const TextStyle(
                        fontSize: 7,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                ],
              ),
            );
          },
          // Custom day cell builder to stack number + markers cleanly
          defaultBuilder: (context, day, focusedDay) {
            return _DayCell(
              day: day,
              events: _getEntriesForDay(day),
              isSelected: false,
              isToday: false,
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            return _DayCell(
              day: day,
              events: _getEntriesForDay(day),
              isSelected: true,
              isToday: false,
            );
          },
          todayBuilder: (context, day, focusedDay) {
            return _DayCell(
              day: day,
              events: _getEntriesForDay(day),
              isSelected: false,
              isToday: true,
            );
          },
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final List<PoopEntry> events;
  final bool isSelected;
  final bool isToday;

  const _DayCell({
    required this.day,
    required this.events,
    required this.isSelected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor = Colors.black87;

    if (isSelected) {
      bgColor = const Color(0xFF4CAF50);
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.2);
      textColor = const Color(0xFF2E7D32);
    }

    final count = events.length;
    final displayCount = count > 3 ? 3 : count;
    final overflow = count > 3 ? count - 3 : 0;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: bgColor != null
          ? BoxDecoration(color: bgColor, shape: BoxShape.circle)
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  isToday ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
          if (count > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '💩' * displayCount,
                  style: const TextStyle(fontSize: 7, height: 1.1),
                ),
                if (overflow > 0)
                  Text(
                    '+$overflow',
                    style: TextStyle(
                      fontSize: 6,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
              ],
            )
          else
            const SizedBox(height: 9), // keep rows same height
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
