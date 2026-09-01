
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../domain_layer/chat_service.dart';
import '../domain_layer/firebase_service.dart';
import '../feature_layer/core_screen/view/core_screen.dart';
import '../feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import '../shared/constants.dart';
import '../shared/theme_controller.dart';

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appChatService = ChatService();
    final appFirebaseService = FirebaseService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(
          value: appChatService,
        ),
        RepositoryProvider.value(
          value: appFirebaseService,
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, mode, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: FToastBuilder(),
          navigatorKey: NavigationService.navigatorKey,
          themeMode: mode,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          home: const CoreScreen(),
        ),
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      splashColor: cDarkBlue.withOpacity(0.2),
      highlightColor: cDarkBlue.withOpacity(0.1),
      hoverColor: cDarkBlue.withOpacity(0.05),
      fontFamily: 'FiraSans',
      tabBarTheme: const TabBarThemeData(
        labelColor: cDarkBlue,
        indicatorColor: cDarkBlue,
        unselectedLabelColor: Colors.grey,
      ),
      appBarTheme: const AppBarTheme(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: cDarkBrown,
          fontFamily: 'Poppins',
        ),
        iconTheme: IconThemeData(color: cDarkBrown),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      textTheme: const TextTheme(
        displayMedium: TextStyle(fontFamily: 'Poppins', color: cDarkBrown),
        displayLarge: TextStyle(fontFamily: 'Poppins', color: cDarkBrown),
        displaySmall: TextStyle(fontFamily: 'Poppins', color: cDarkBrown),
        bodyMedium: TextStyle(fontFamily: 'Poppins', color: cDarkBrown, fontSize: 16),
        bodySmall: TextStyle(fontFamily: 'Poppins', color: cDarkBrown),
        bodyLarge: TextStyle(fontFamily: 'Poppins', color: cDarkBrown),
      ),
    );
  }

  ThemeData _darkTheme() {
    const light = Color(0xFFE6E1DC);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF16151A),
      splashColor: Colors.white12,
      highlightColor: Colors.white10,
      fontFamily: 'FiraSans',
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF232228),
        primary: cDarkBlue,
      ),
      cardColor: const Color(0xFF232228),
      tabBarTheme: const TabBarThemeData(
        labelColor: cDarkBlue,
        indicatorColor: cDarkBlue,
        unselectedLabelColor: Colors.white54,
      ),
      appBarTheme: const AppBarTheme(
        scrolledUnderElevation: 0.0,
        backgroundColor: Color(0xFF1C1B21),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: light,
          fontFamily: 'Poppins',
        ),
        iconTheme: IconThemeData(color: light),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      textTheme: const TextTheme(
        displayMedium: TextStyle(fontFamily: 'Poppins', color: light),
        displayLarge: TextStyle(fontFamily: 'Poppins', color: light),
        displaySmall: TextStyle(fontFamily: 'Poppins', color: light),
        bodyMedium: TextStyle(fontFamily: 'Poppins', color: light, fontSize: 16),
        bodySmall: TextStyle(fontFamily: 'Poppins', color: light),
        bodyLarge: TextStyle(fontFamily: 'Poppins', color: light),
      ),
    );
  }
}
