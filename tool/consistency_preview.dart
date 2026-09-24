// Synthetic UI preview; does not initialize or connect to Firebase.
import 'package:flutter/material.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_entry.dart';
import 'package:potty_tracker/theme/app_theme.dart';
import 'package:potty_tracker/widgets/consistency_selector.dart';
import 'package:potty_tracker/widgets/poop_entry_tile.dart';

void main() =>
    runApp(MaterialApp(theme: AppTheme.theme, home: const Preview()));

class Preview extends StatefulWidget {
  const Preview({super.key});

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  Consistency? selected = Consistency.pasty;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Consistency preview')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(padding: const EdgeInsets.all(20), children: [
              ConsistencySelector(
                selected: selected,
                onSelected: (value) => setState(() => selected = value),
              ),
              const SizedBox(height: 20),
              for (final consistency in Consistency.values)
                PoopEntryTile(
                  entry: PoopEntry(
                    id: consistency.name,
                    babyId: 'preview',
                    timestamp: DateTime(2026, 9, 24, 10),
                    consistency: consistency,
                    createdAt: DateTime(2026, 9, 24),
                  ),
                  onDelete: () {},
                  onEdit: () {},
                ),
            ]),
          ),
        ),
      );
}
