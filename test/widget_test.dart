// Minimal smoke test — verifies the app boots and renders without throwing.
//
// We pass the test-default zero-latency in-memory fakes through
// `MyApp`'s override hooks. This avoids any pending `Future.delayed`
// timers at teardown, which would otherwise trip the test framework's
// "A Timer is still pending" invariant.

import 'package:flutter/material.dart';
import 'package:flutter_posts/src/app.dart';
import 'package:flutter_posts/src/features/auth/data/in_memory_auth_repository.dart';
import 'package:flutter_posts/src/features/forum/data/in_memory_forum_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots and renders without throwing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        authRepositoryOverride: InMemoryAuthRepository(),
        forumRepositoryOverride: InMemoryForumRepository(seed: false),
      ),
    );

    // `pumpWidget` returns after the first frame. If the widget tree
    // threw during construction, this line never runs. Assert that
    // SOMETHING (anything) rendered.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
