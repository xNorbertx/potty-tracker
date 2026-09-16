import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/models/consistency.dart';
import 'package:potty_tracker/models/poop_color.dart';
import 'package:potty_tracker/models/poop_size.dart';
import 'package:potty_tracker/widgets/consistency_selector.dart';
import 'package:potty_tracker/widgets/poop_color_selector.dart';
import 'package:potty_tracker/widgets/size_selector.dart';

void main() {
  Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('consistency selector reports the tapped option', (tester) async {
    Consistency? selected;
    await tester.pumpWidget(app(ConsistencySelector(
      selected: null,
      onSelected: (value) => selected = value,
    )));

    await tester.tap(find.text('Watery/Runny'));

    expect(selected, Consistency.watery);
  });

  testWidgets('consistency selector includes the pasty option', (tester) async {
    Consistency? selected;
    await tester.pumpWidget(app(ConsistencySelector(
      selected: null,
      onSelected: (value) => selected = value,
    )));

    await tester.tap(find.text('Pasty'));

    expect(selected, Consistency.pasty);
  });

  testWidgets('size selector reports the tapped size', (tester) async {
    PoopSize? selected;
    await tester.pumpWidget(app(SizeSelector(
      selected: PoopSize.small,
      onSelected: (value) => selected = value,
    )));

    await tester.tap(find.text('Large'));

    expect(selected, PoopSize.large);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('colour selector lists the guide and reports a selection',
      (tester) async {
    PoopColor? selected;
    await tester.pumpWidget(app(PoopColorSelector(
      selected: null,
      onChanged: (value) => selected = value,
    )));

    await tester.tap(find.byType(DropdownButtonFormField<PoopColor>));
    await tester.pumpAndSettle();
    expect(find.text('Yellow / mustard'), findsOneWidget);

    await tester.tap(find.text('Yellow / mustard').last);
    expect(selected, PoopColor.yellow);
  });
}
