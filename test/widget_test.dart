

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rural_education/main.dart';

void main() {
  testWidgets('App loads and shows initial screen',
      (WidgetTester tester) async {

    await tester.pumpWidget(const MyApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    final loginScreenFound = find.textContaining('Login').evaluate().isNotEmpty;
    final homeScreenFound = find.textContaining('Home').evaluate().isNotEmpty;

    expect(loginScreenFound || homeScreenFound, true,
        reason: 'Either LoginScreen or HomeScreen should appear');
  });
}
