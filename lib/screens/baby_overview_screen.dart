import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/baby.dart';
import '../models/poop_entry.dart';
import '../services/auth_service.dart';
import '../services/diary_pdf_export_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_status.dart';
import '../l10n/app_locale.dart';

class BabyOverviewScreen extends StatefulWidget {
  final Baby baby;

  const BabyOverviewScreen({super.key, required this.baby});

  @override
  State<BabyOverviewScreen> createState() => _BabyOverviewScreenState();
}

class _BabyOverviewScreenState extends State<BabyOverviewScreen> {
  bool _exporting = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      final uid = auth.currentUserId;
      final email = auth.currentUserEmail;
      if (uid == null || email == null) return;
      _refreshCurrentCaregiver(uid, email);
    });
  }

  Future<void> _refreshCurrentCaregiver(String uid, String email) async {
    final firestore = context.read<FirestoreService>();
    final profile = await firestore.getCaregiverProfile(uid);
    if (!mounted) return;
    await firestore.updateCaregiverDetails(
      baby: widget.baby,
      uid: uid,
      name: profile?.name.trim().isNotEmpty == true
          ? profile!.name.trim()
          : 'Caregiver',
      email: profile?.email.trim().isNotEmpty == true
          ? profile!.email.trim()
          : email,
    );
  }

  void _showShareDialog(BuildContext context, Baby currentBaby) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('inviteCaregiver')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Give this code to the caregiver you want to invite to ${currentBaby.name}\'s diary.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: Text(
                currentBaby.shareCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: currentBaby.shareCode));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('inviteCopied'))),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: Text(context.tr('copyCode')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('done')),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDiary(Baby baby, List<PoopEntry> entries) async {
    final period = await showModalBottomSheet<DiaryExportPeriod>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr('exportSummary'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(context.tr('chooseExportPeriod')),
              const SizedBox(height: 12),
              ...DiaryExportPeriod.values.map(
                (value) => ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined,
                      color: Color(0xFF4CAF50)),
                  title: Text(value.labelFor(context.appLanguage)),
                  onTap: () => Navigator.pop(sheetContext, value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (period == null || !mounted) return;

    setState(() => _exporting = true);
    try {
      final now = DateTime.now();
      final bytes = await const DiaryPdfExportService().build(
        baby: baby,
        entries: entries,
        period: period,
        now: now,
        language: context.appLanguage,
      );
      final safeName = baby.name.replaceAll(RegExp('[^a-zA-Z0-9]+'), '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            '${safeName}_diary_${DateFormat('yyyy-MM-dd').format(now)}.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(error)),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    return StreamBuilder<Baby?>(
      stream: firestore.babyStream(widget.baby.id),
      initialData: widget.baby,
      builder: (context, babySnapshot) {
        final currentBaby = babySnapshot.data;
        if (currentBaby == null) {
          return const Scaffold(
            body: AppLoadingView(message: 'This baby is no longer available.'),
          );
        }
        return StreamBuilder<List<PoopEntry>>(
          stream: firestore.entriesStream(currentBaby.id),
          builder: (context, entrySnapshot) {
            final entries = entrySnapshot.data ?? [];
            final now = DateTime.now();
            final startOfWeek = DateTime(now.year, now.month, now.day)
                .subtract(Duration(days: now.weekday - 1));
            final weekCount = entries
                .where((entry) => !entry.timestamp.isBefore(startOfWeek))
                .length;
            final lastEntry = entries.isEmpty
                ? null
                : entries.reduce(
                    (latest, entry) => entry.timestamp.isAfter(latest.timestamp)
                        ? entry
                        : latest,
                  );
            final uid = auth.currentUserId;

            return Scaffold(
              appBar: AppBar(title: Text(currentBaby.name)),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    context.tr('caregivers'),
                    style: TextStyle(
                      color: Color(0xFF388E3C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children:
                          currentBaby.memberUids.asMap().entries.map((entry) {
                        final caregiverUid = entry.value;
                        final storedLabel =
                            currentBaby.memberLabels[caregiverUid];
                        final storedEmail =
                            currentBaby.memberEmails[caregiverUid];
                        final labelIsEmail = storedLabel?.contains('@') == true;
                        final hasKnownName = storedLabel != 'Caregiver' &&
                            !labelIsEmail &&
                            storedLabel?.trim().isNotEmpty == true;
                        final name = hasKnownName
                            ? storedLabel!.trim()
                            : 'Caregiver ${entry.key + 1}';
                        final email = storedEmail?.trim().isNotEmpty == true
                            ? storedEmail!.trim()
                            : labelIsEmail
                                ? storedLabel!
                                : null;
                        return ListTile(
                          leading: const Icon(Icons.person_outline,
                              color: Color(0xFF4CAF50)),
                          title: Text(caregiverUid == uid ? context.tr('you') : name),
                          subtitle: email == null ? null : Text(email),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showShareDialog(context, currentBaby),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text(context.tr('inviteCaregiver')),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _exporting
                        ? null
                        : () => _exportDiary(currentBaby, entries),
                    icon: _exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_outlined),
                    label: Text(
                        _exporting ? context.tr('exportingPdf') : context.tr('exportPdf')),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    context.tr('diaryAtAGlance'),
                    style: TextStyle(
                      color: Color(0xFF388E3C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: context.tr('totalLogs'),
                          value: '${entries.length}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: context.tr('thisWeek'),
                          value: '$weekCount',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.schedule, color: Color(0xFF4CAF50)),
                      title: Text(context.tr('mostRecentLog')),
                      subtitle: Text(
                        lastEntry == null
                            ? 'No poop logs yet'
                            : DateFormat('EEEE, MMMM d • HH:mm')
                                .format(lastEntry.timestamp),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, currentBaby.id),
                      icon: const Icon(Icons.calendar_month),
                      label: Text(context.tr('openDiary', args: {'name': currentBaby.name})),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C))),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
}
