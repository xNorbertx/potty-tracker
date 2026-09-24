import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/models/baby.dart';
import 'package:potty_tracker/widgets/diary_title.dart';

Baby baby(String id, String name) => Baby(
    id: id,
    name: name,
    ownerUid: 'caregiver',
    memberUids: const ['caregiver'],
    shareCode: '',
    createdAt: DateTime(2026));

void main() {
  testWidgets('picker stays centered and the same size regardless of names',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget picker(List<Baby> babies) => MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 900), textScaler: TextScaler.linear(2)),
            child: Scaffold(
                body: BabyDiaryPicker(babies: babies, selectedBabyId: '1')),
          ),
        );
    await tester.pumpWidget(picker([baby('1', 'Ada'), baby('2', 'Bo')]));
    final surface = find.descendant(
        of: find.byType(Dialog), matching: find.byType(Material));
    final original = tester.getRect(surface);
    expect(original.center, const Offset(160, 450));
    await tester.pumpWidget(picker([
      baby('1', 'Alexanderthegreat Sebastian Montgomery'),
      baby('2', 'Alexanderthegreat Sebastian Montgomery Alexandra')
    ]));
    await tester.pumpAndSettle();
    expect(tester.getRect(surface), original);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long baby lists scroll without overflowing', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<String>(
                        context: context,
                        builder: (_) => BabyDiaryPicker(
                            babies:
                                List.generate(20, (i) => baby('$i', 'Baby $i')),
                            selectedBabyId: '0')),
                    child: const Text('Open')),
              )),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Baby 19'), 200);
    expect(find.text('Baby 19'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Baby 19'));
    await tester.pumpAndSettle();
    expect(find.byType(BabyDiaryPicker), findsNothing);
  });
}
