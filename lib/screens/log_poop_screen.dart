import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/consistency.dart';
import '../models/poop_size.dart';
import '../models/baby.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/consistency_selector.dart';
import '../widgets/size_selector.dart';

class LogPoopScreen extends StatefulWidget {
  final Baby baby;
  final DateTime? initialDate;

  const LogPoopScreen({super.key, required this.baby, this.initialDate});

  @override
  State<LogPoopScreen> createState() => _LogPoopScreenState();
}

class _LogPoopScreenState extends State<LogPoopScreen> {
  late DateTime _selectedDateTime;
  Consistency? _selectedConsistency;
  PoopSize? _selectedSize;
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final base = widget.initialDate ?? now;
    // Use the selected day but always current time
    _selectedDateTime = DateTime(
      base.year, base.month, base.day,
      now.hour, now.minute,
    );
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isAfter(now) ? now : _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_selectedConsistency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a consistency type')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final firestore = context.read<FirestoreService>();
      await firestore.addEntry(
        uid: auth.currentUserId!,
        babyId: widget.baby.id,
        timestamp: _selectedDateTime,
        consistency: _selectedConsistency!,
        size: _selectedSize,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💩 Poop logged successfully!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log a Poop 💩'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date/Time picker
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'When did it happen?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              DateFormat('MMM d, yyyy').format(_selectedDateTime),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.access_time, size: 18),
                            label: Text(
                              DateFormat('HH:mm').format(_selectedDateTime),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Consistency selector
            ConsistencySelector(
              selected: _selectedConsistency,
              onSelected: (c) => setState(() => _selectedConsistency = c),
            ),

            const SizedBox(height: 16),

            // Size selector
            SizeSelector(
              selected: _selectedSize,
              onSelected: (s) => setState(() => _selectedSize = s),
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any observations...',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Entry 💾'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
