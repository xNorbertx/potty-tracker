import 'package:flutter/material.dart';
import '../models/poop_color.dart';
import '../l10n/app_locale.dart';

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
      decoration: InputDecoration(
        labelText: context.tr('colorOptional'),
        prefixIcon: const Icon(Icons.palette_outlined),
      ),
      hint: Text(context.tr('selectColor')),
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
                  Text(color.labelFor(context.appLanguage)),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
