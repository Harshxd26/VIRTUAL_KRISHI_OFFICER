// This is a basic Flutter widget test for Digital Krishi Officer app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_krishi_officer/main.dart';

void main() {
  testWidgets('App loads and shows splash content', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DigitalKrishiOfficerApp());

    // Allow async initialization (e.g. locale) to complete.
    await tester.pumpAndSettle();

    // Verify app title or splash content is shown (splash shows "Digital Krishi Officer").
    expect(find.text('Virtual Krishi Officer'), findsOneWidget);
  });
}
