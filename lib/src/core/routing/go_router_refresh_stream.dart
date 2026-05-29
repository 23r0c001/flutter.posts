import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapter that turns a `Stream` into a `ChangeNotifier` so it can be
/// passed to `GoRouter`'s `refreshListenable:` parameter.
///
/// Why: `GoRouter.redirect` is only re-evaluated when its listenable
/// notifies. Without this, the router wouldn't re-check auth state
/// when `AuthBloc` transitions, so a sign-out wouldn't kick the user
/// back to the sign-in page until the next manual navigation.
///
/// Pattern lifted from the official go_router docs:
/// https://pub.dev/documentation/go_router/latest/topics/Redirection-topic.html
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    // Fire once immediately so the router runs its initial redirect.
    notifyListeners();
    _subscription = stream
        .asBroadcastStream()
        .listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
