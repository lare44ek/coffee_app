import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coffee_app/main.dart';

void main() {
  testWidgets('App boots to login when no session', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CoffeeApp(initialUser: null)),
    );
    expect(find.text('Войти'), findsOneWidget);
  });
}
