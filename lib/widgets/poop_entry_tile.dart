import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/poop_entry.dart';
import '../models/consistency.dart';
import '../models/poop_size.dart';

class PoopEntryTile extends StatelessWidget {
  final PoopEntry entry;
  final VoidCallback onDelete;

  const PoopEntryTile({
    super.key,
    required this.entry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete entry?'),
            content: const Text('This will permanently delete this poop entry.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: entry.consistency.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                entry.consistency.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          title: Text(
            entry.consistency.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.size != null
                    ? '${entry.size!.emoji} ${entry.size!.label}'
                    : 'No size selected',
                style: TextStyle(
                  fontSize: 12,
                  color: entry.size != null ? Colors.black87 : Colors.grey,
                ),
              ),
              if (entry.notes != null && entry.notes!.isNotEmpty)
                Text(entry.notes!),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(entry.timestamp),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'swipe to delete',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
