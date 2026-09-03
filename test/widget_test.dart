import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/pages/sender_dashboard_page.dart';

void main() {
  testWidgets('sender dashboard renders its core controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SenderDashboardPage()));

    expect(find.text('Inbox cleanup'), findsOneWidget);
    expect(find.text('Your inbox, made lighter.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Google account settings'), findsOneWidget);
  });
}
