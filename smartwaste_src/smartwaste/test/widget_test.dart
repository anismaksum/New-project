import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartwaste/main.dart';

void main() {
  testWidgets('login demo account opens SmartWaste dashboard', (tester) async {
    await tester.pumpWidget(const SmartWasteApp());

    expect(find.text('SMARTWASTE'), findsOneWidget);

    await tester.tap(find.text('Isi Demo'));
    await tester.pump();
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Anis'), findsOneWidget);
    expect(find.text('SmartWaste Reward'), findsOneWidget);
  });

  testWidgets('calculator tool can log a waste deposit', (tester) async {
    await tester.pumpWidget(const SmartWasteApp());

    await tester.tap(find.text('Isi Demo'));
    await tester.pump();
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catat Setoran'));
    await tester.pump();

    expect(find.byIcon(Icons.add_task_rounded), findsOneWidget);
    expect(find.textContaining('Setoran Plastik menambah'), findsOneWidget);
  });
}
