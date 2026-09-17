import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/poop_entry.dart';
import '../models/consistency.dart';
import '../models/poop_size.dart';
import '../l10n/app_locale.dart';

class PoopEntryTile extends StatelessWidget {
  final PoopEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const PoopEntryTile({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: Key(entry.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.45,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: const Color(0xFF42A5F5),
            foregroundColor: Colors.white,
            icon: Icons.edit_outlined,
            label: context.tr('edit'),
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
            backgroundColor: const Color(0xFFEF5350),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: context.tr('delete'),
          ),
        ],
      ),
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
            entry.consistency.labelFor(context.appLanguage),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.size != null
                    ? '${entry.size!.emoji} ${entry.size!.labelFor(context.appLanguage)}'
                    : context.tr('notAvailable'),
                style: TextStyle(
                  fontSize: 12,
                  color: entry.size != null ? Colors.black87 : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: entry.color?.swatch ?? Colors.grey.shade300,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.grey.shade400, width: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.color?.labelFor(context.appLanguage) ?? context.tr('notAvailable'),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            entry.color != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(entry.notes!),
              ],
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
              if (entry.loggedByName?.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  entry.loggedByName!,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ] else if (entry.loggedByEmail?.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  entry.loggedByEmail!,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('deleteEntryQuestion')),
        content: Text(context.tr('deleteEntryHelp')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }
}
