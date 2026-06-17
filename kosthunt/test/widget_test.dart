import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosthunt/src/app.dart';
import 'package:kosthunt/src/routes/app_routes.dart';

void main() {
  testWidgets('KostHunt renders the home marketplace', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KostHuntApp());

    expect(find.text('KostHunt'), findsOneWidget);
    expect(find.text('Temukan ruang yang pas, tanpa ribet.'), findsWidgets);
    expect(find.text('Cari'), findsOneWidget);
    expect(find.text('Booking'), findsWidgets);
  });

  testWidgets('role routes open owner and admin areas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KostHuntApp());

    final BuildContext context = tester.element(find.text('KostHunt').first);

    Navigator.of(context).pushNamed(AppRoutes.ownerDashboard);
    await tester.pumpAndSettle();
    expect(find.text('Owner Dashboard'), findsOneWidget);
    expect(find.text('Listing Milikmu'), findsOneWidget);

    Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
    await tester.pumpAndSettle();
    expect(find.text('Admin Console'), findsOneWidget);
    expect(find.text('Antrian Moderasi'), findsOneWidget);
  });
}
