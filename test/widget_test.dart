import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:office_boy_app/app.dart';

void main() {
  testWidgets('Home screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: OfficeBoyApp()),
    );

    // Verify the app title is shown
    expect(find.text('Office Boy Note'), findsOneWidget);

    // Verify action buttons
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
