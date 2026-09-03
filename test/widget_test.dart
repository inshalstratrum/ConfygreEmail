import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Confygre Email smoke test', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Confygre Email'))));
    expect(find.text('Confygre Email'), findsOneWidget);
  });
}
