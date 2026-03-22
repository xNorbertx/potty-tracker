import 'package:flutter/material.dart';
import '../models/poop_color.dart';

class PoopColorSelector extends StatelessWidget {
  final PoopColor? selected;
  final ValueChanged<PoopColor?> onChanged;

  const PoopColorSelector(
      {super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PoopColor>(
      value: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Colour (optional)',
        prefixIcon: Icon(Icons.palette_outlined),
      ),
      hint: const Text('Select colour from baby poo guide'),
      items: PoopColor.values
          .map(
            (color) => DropdownMenuItem<PoopColor>(
              value: color,
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: color.swatch,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.08)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(color.label),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
