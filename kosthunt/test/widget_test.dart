import 'package:flutter_test/flutter_test.dart';
import 'package:kosthunt/src/app.dart';
import 'package:kosthunt/src/services/auth_service.dart';

void main() {
  tearDown(() {
    AuthService.instance.logout();
  });

  testWidgets('KostHunt starts at Supabase sign in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KostHuntApp());

    expect(find.text('Masuk Akun'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Akun Dummy'), findsNothing);
  });

  testWidgets('empty sign in shows validation message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KostHuntApp());
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Email dan password wajib diisi.'), findsOneWidget);
  });
}
