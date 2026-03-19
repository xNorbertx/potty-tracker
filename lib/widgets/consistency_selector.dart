import 'package:flutter/material.dart';
import '../models/consistency.dart';

class ConsistencySelector extends StatelessWidget {
  final Consistency? selected;
  final ValueChanged<Consistency> onSelected;

  const ConsistencySelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Consistency',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...Consistency.values.map((c) => _ConsistencyCard(
              consistency: c,
              isSelected: selected == c,
              onTap: () => onSelected(c),
            )),
      ],
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  final Consistency consistency;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConsistencyCard({
    required this.consistency,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? consistency.color.withValues(alpha: 0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? consistency.color : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: consistency.color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Text(
                consistency.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 16),
              Text(
                consistency.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? consistency.color.withValues(alpha: 0.9)
                      : Colors.black87,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(Icons.check_circle, color: consistency.color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
