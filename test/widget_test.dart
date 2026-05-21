// Minimal smoke test — verifies the app boots and renders without throwing.
//
// The default `flutter create` template ships a counter-app test that
// referenced a `MyApp` with an increment button — neither has ever
// existed in this project. Replaced with a smoke test that's actually
// meaningful for a forum app: pump the widget, verify SOMETHING renders.

import 'package:flutter/material.dart';
import 'package:flutter_posts/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots and renders without throwing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // `pumpWidget` returns after the first frame. If the widget tree
    // threw during construction, this line never runs. Assert that
    // SOMETHING (anything) rendered.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
