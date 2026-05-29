import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

/// Global observer for every `Bloc` / `Cubit` in the app.
///
/// Registered via `Bloc.observer = AppBlocObserver()` in `bootstrap.dart`.
/// Bloc's design is event-sourced — every state transition has a named
/// event and a previous->next state pair — so a single observer can log
/// the entire app's state machine for free. This is one of bloc's best
/// debugging affordances.
///
/// In `kDebugMode` we log to the console; in release we silently no-op
/// to avoid leaking state details into device logs. Hook in a real
/// crash reporter (Sentry, Crashlytics) inside `onError` later.
class AppBlocObserver extends BlocObserver {
  /// Fires once when each Bloc/Cubit is first created.
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (kDebugMode) {
      debugPrint('[bloc] created ${bloc.runtimeType}');
    }
  }

  /// Fires every time a `Bloc` receives an event (Cubits don't have events).
  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (kDebugMode) {
      debugPrint('[bloc] ${bloc.runtimeType} <- ${event?.runtimeType}');
    }
  }

  /// Fires for every state transition. `change.currentState` and
  /// `change.nextState` are both available if you want richer logs.
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      debugPrint(
        '[bloc] ${bloc.runtimeType}: ${change.currentState.runtimeType} -> ${change.nextState.runtimeType}',
      );
    }
  }

  /// Fires when a `Bloc.add()` handler throws, or a `Cubit` method
  /// throws. Forward to your crash reporter here in production builds.
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[bloc] ${bloc.runtimeType} ERROR: $error\n$stackTrace');
    }
    super.onError(bloc, error, stackTrace);
  }

  /// Fires when a Bloc/Cubit is closed (disposed). Useful for verifying
  /// you're not leaking blocs across navigation.
  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    if (kDebugMode) {
      debugPrint('[bloc] closed ${bloc.runtimeType}');
    }
  }
}
