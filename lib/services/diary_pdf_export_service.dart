import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/baby.dart';
import '../models/consistency.dart';
import '../models/poop_color.dart';
import '../models/poop_entry.dart';
import '../models/poop_size.dart';
import '../l10n/app_locale.dart';

enum DiaryExportPeriod {
  week(7, 'lastWeek'),
  twoWeeks(14, 'last2Weeks'),
  month(30, 'lastMonth');

  const DiaryExportPeriod(this.days, this.label);

  final int days;
  final String label;

  String labelFor(AppLanguage language) => AppLocale.localized(language, label);
}

class DiaryPdfExportService {
  const DiaryPdfExportService();

  List<PoopEntry> entriesForPeriod({
    required List<PoopEntry> entries,
    required DiaryExportPeriod period,
    required DateTime now,
  }) {
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: period.days - 1));
    return entries
        .where((entry) =>
            !entry.timestamp.isBefore(start) && !entry.timestamp.isAfter(now))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<Uint8List> build({
    required Baby baby,
    required List<PoopEntry> entries,
    required DiaryExportPeriod period,
    DateTime? now,
    AppLanguage language = AppLanguage.english,
  }) async {
    final exportTime = now ?? DateTime.now();
    final periodEntries = entriesForPeriod(
      entries: entries,
      period: period,
      now: exportTime,
    );
    final start = DateTime(exportTime.year, exportTime.month, exportTime.day)
        .subtract(Duration(days: period.days - 1));
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(36),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          pw.Text(
            AppLocale.localized(language, 'pdfSummary', args: {'name': baby.name}),
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF2E7D32),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${period.labelFor(language)}: ${DateFormat('MMM d, y', language.code).format(start)} to ${DateFormat('MMM d, y', language.code).format(exportTime)}',
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE8F5E9),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  '${periodEntries.length}',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF2E7D32),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Text(
                  periodEntries.length == 1 ? 'poop logged' : 'poops logged',
                  style: const pw.TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            AppLocale.localized(language, 'dailyActivity'),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _dailyChart(start: start, period: period, entries: periodEntries, language: language),
          pw.SizedBox(height: 24),
          _breakdown(
            title: AppLocale.localized(language, 'consistencyTitle'),
            values: Consistency.values,
            entries: periodEntries,
            labelFor: (value) => value.labelFor(language),
            valueFor: (entry) => entry.consistency,
            unknownLabel: AppLocale.localized(language, 'notAvailable'),
          ),
          pw.SizedBox(height: 18),
          _breakdown(
            title: AppLocale.localized(language, 'sizeTitle'),
            values: PoopSize.values,
            entries: periodEntries,
            labelFor: (value) => value.labelFor(language),
            valueFor: (entry) => entry.size,
            unknownLabel: AppLocale.localized(language, 'notAvailable'),
          ),
          pw.SizedBox(height: 18),
          _breakdown(
            title: AppLocale.localized(language, 'colorTitle'),
            values: PoopColor.values,
            entries: periodEntries,
            labelFor: (value) => value.labelFor(language),
            valueFor: (entry) => entry.color,
            unknownLabel: AppLocale.localized(language, 'notAvailable'),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            AppLocale.localized(language, 'generatedBy', args: {'date': DateFormat('MMM d, y', language.code).format(exportTime)}),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _dailyChart({
    required DateTime start,
    required DiaryExportPeriod period,
    required List<PoopEntry> entries,
    required AppLanguage language,
  }) {
    final dailyCounts = List<int>.generate(period.days, (index) {
      final day = start.add(Duration(days: index));
      return entries
          .where((entry) =>
              entry.timestamp.year == day.year &&
              entry.timestamp.month == day.month &&
              entry.timestamp.day == day.day)
          .length;
    });
    final highestCount = math.max(1, dailyCounts.fold(0, math.max));
    final labelInterval = period.days <= 7
        ? 1
        : period.days <= 14
            ? 2
            : 5;

    final middleCount = highestCount > 1 ? (highestCount / 2).ceil() : null;

    return pw.Container(
      height: 170,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(AppLocale.localized(language, 'poopsPerDay'),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.SizedBox(
                  width: 20,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('$highestCount',
                          style: const pw.TextStyle(fontSize: 7)),
                      if (middleCount != null) ...[
                        pw.Spacer(),
                        pw.Text('$middleCount',
                            style: const pw.TextStyle(fontSize: 7)),
                      ],
                      pw.Spacer(),
                      pw.Text('0', style: const pw.TextStyle(fontSize: 7)),
                      pw.SizedBox(height: 13),
                    ],
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                              left: pw.BorderSide(color: PdfColors.grey400),
                              bottom: pw.BorderSide(color: PdfColors.grey400),
                            ),
                          ),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                            children: List.generate(period.days, (index) {
                              final count = dailyCounts[index];
                              final barHeight = count == 0
                                  ? 0.0
                                  : math.max(3, 92 * count / highestCount);
                              return pw.Expanded(
                                child: pw.Align(
                                  alignment: pw.Alignment.bottomCenter,
                                  child: pw.Container(
                                    width: period.days > 14 ? 6 : 12,
                                    height: barHeight.toDouble(),
                                    decoration: pw.BoxDecoration(
                                      color: PdfColor.fromInt(0xFF4CAF50),
                                      borderRadius: pw.BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: List.generate(period.days, (index) {
                          final day = start.add(Duration(days: index));
                          final showLabel = index % labelInterval == 0 ||
                              index == period.days - 1;
                          return pw.Expanded(
                            child: pw.Text(
                              showLabel ? DateFormat('M/d', language.code).format(day) : '',
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 5),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _breakdown<T>({
    required String title,
    required List<T> values,
    required List<PoopEntry> entries,
    required String Function(T value) labelFor,
    required T? Function(PoopEntry entry) valueFor,
    required String unknownLabel,
  }) {
    final items = breakdownItems(
      values: values,
      entries: entries,
      labelFor: labelFor,
      valueFor: valueFor,
      unknownLabel: unknownLabel,
    );
    return _section(
      title,
      [
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(item, style: const pw.TextStyle(fontSize: 10)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  List<String> breakdownItems<T>({
    required List<T> values,
    required List<PoopEntry> entries,
    required String Function(T value) labelFor,
    required T? Function(PoopEntry entry) valueFor,
    String unknownLabel = 'n/a',
  }) {
    final items = values
        .where((value) => entries.any((entry) => valueFor(entry) == value))
        .map((value) =>
            '${labelFor(value)}: ${entries.where((entry) => valueFor(entry) == value).length}')
        .toList();
    final unknownCount =
        entries.where((entry) => valueFor(entry) == null).length;
    if (unknownCount > 0) items.add('$unknownLabel: $unknownCount');
    return items;
  }

  pw.Widget _section(String title, List<pw.Widget> children) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ...children,
        ],
      );
}
