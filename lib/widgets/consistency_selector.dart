import 'package:flutter/material.dart';
import '../models/consistency.dart';
import 'consistency_illustration.dart';

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
            color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x334CAF50),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              ConsistencyIllustration(consistency: consistency),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(
                consistency.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                ),
              )),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: Color(0xFF4CAF50), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
