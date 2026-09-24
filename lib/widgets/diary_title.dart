import 'package:flutter/material.dart';
import '../models/baby.dart';

class DiaryTitle extends StatelessWidget {
  final Baby baby;
  final List<Baby> babies;
  final ValueChanged<String> onSelected;

  const DiaryTitle({
    super.key,
    required this.baby,
    required this.babies,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final title = Text("${baby.name}'s diary",
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis);
    if (babies.length < 2) return title;

    return Tooltip(
      message: 'Switch baby',
      child: Semantics(
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final selected = await showDialog<String>(
              context: context,
              builder: (_) =>
                  BabyDiaryPicker(babies: babies, selectedBabyId: baby.id),
            );
            if (selected != null && context.mounted) onSelected(selected);
          },
          child: SizedBox(
            width: double.infinity,
            height: kToolbarHeight,
            child: Center(child: title),
          ),
        ),
      ),
    );
  }
}

class BabyDiaryPicker extends StatelessWidget {
  final List<Baby> babies;
  final String selectedBabyId;

  const BabyDiaryPicker({
    super.key,
    required this.babies,
    required this.selectedBabyId,
  });

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: Semantics(
          namesRoute: true,
          label: 'Switch baby',
          child: SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.6),
                child: ListView.builder(
                  shrinkWrap: true,
                  // Names never change the popup's size. Larger text gets
                  // equally taller rows, and longer lists scroll.
                  itemExtent:
                      64 * MediaQuery.textScalerOf(context).scale(16) / 16,
                  itemCount: babies.length,
                  itemBuilder: (context, index) {
                    final candidate = babies[index];
                    final selected = candidate.id == selectedBabyId;
                    return Semantics(
                      button: true,
                      selected: selected,
                      child: Tooltip(
                        message: candidate.name,
                        excludeFromSemantics: true,
                        child: InkWell(
                          onTap: () => Navigator.pop(context, candidate.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(children: [
                              Expanded(
                                child: Text(candidate.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 24,
                                child: selected
                                    ? Icon(Icons.check,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)
                                    : null,
                              ),
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
}
