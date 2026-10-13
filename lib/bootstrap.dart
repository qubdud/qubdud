import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'shared/theme_controller.dart';

Object? _lastReported;

/// Błąd na konsolę (widoczny w logcat także w release) i do Crashlytics.
void reportError(Object error, StackTrace stack, {String? reason}) {
  // błąd z handlera BLoC trafia tu dwa razy: przez onError i przez strefę
  if (identical(error, _lastReported)) return;
  _lastReported = error;
  debugPrint('${reason ?? 'BŁĄD'}: $error\n$stack');
  if (Firebase.apps.isEmpty) return;
  FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
}

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    reportError(error, stackTrace, reason: '${bloc.runtimeType}');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  Bloc.observer = const AppBlocObserver();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        reportError(error, stack, reason: 'PlatformDispatcher');
        return true;
      };

      // provider debug tylko w buildzie debug — release musi przejść Play Integrity
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );

      requestNotificationPermission();

      await loadSavedTheme();

      runApp(await builder());
    },
    (error, stackTrace) => reportError(error, stackTrace),
  );
}
Future<void> requestNotificationPermission() async {
  if (kIsWeb) return; // Pominięcie dla web

  if (Platform.isIOS) {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } else if (Platform.isAndroid) {
    await Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    });
  }
}
