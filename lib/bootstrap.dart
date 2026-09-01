import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'shared/theme_controller.dart';



class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug, // 👈 to aktywuje tryb debugowy
      );



      requestNotificationPermission();

      await loadSavedTheme();

      runApp(await builder());
    },
    (error, stackTrace) => log(error.toString(), stackTrace: stackTrace),
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

