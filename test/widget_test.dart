import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ankara_tren/screens/main_scaffold.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MainScaffold()),
    );
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
