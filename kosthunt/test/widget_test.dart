import 'package:flutter_test/flutter_test.dart';
import 'package:kosthunt/src/app.dart';
import 'package:kosthunt/src/services/auth_service.dart';

void main() {
  setUp(() async {
    await AuthService.instance.logout();
  });

  tearDown(() async {
    await AuthService.instance.logout();
  });

  Future<void> pumpPastAuthGate(WidgetTester tester) async {
    await tester.pumpWidget(const KostHuntApp());
    for (int index = 0; index < 30; index += 1) {
      await tester.runAsync(() {
        return Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      if (find.text('Masuk Akun').evaluate().isNotEmpty) {
        return;
      }
    }
  }

  testWidgets('KostHunt starts at Supabase sign in', (
    WidgetTester tester,
  ) async {
    await pumpPastAuthGate(tester);

    expect(find.text('Masuk Akun'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Akun Dummy'), findsNothing);
  });

  testWidgets('empty sign in shows validation message', (
    WidgetTester tester,
  ) async {
    await pumpPastAuthGate(tester);

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Email dan password wajib diisi.'), findsOneWidget);
  });
}
