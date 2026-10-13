
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../domain_layer/chat_service.dart';
import '../domain_layer/firebase_service.dart';
import '../feature_layer/core_screen/view/core_screen.dart';
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
      // bez własnego colorScheme Material 3 bierze fioletowy seed
      // i podbarwia nim dialogi, karty i chipy — stąd „różowe popupy"
      colorScheme: ColorScheme.fromSeed(
        seedColor: cDarkBlue,
        primary: cDarkBlue,
        surface: Colors.white,
        surfaceTint: Colors.transparent,
      ),
      scaffoldBackgroundColor: cLighterBrown,
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cDarkBrown),
        contentTextStyle: const TextStyle(
            fontFamily: 'Poppins', fontSize: 14, color: cDarkBrown),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: cDarkBlue.withOpacity(0.12),
        surfaceTintColor: Colors.transparent,
        side: BorderSide(color: Colors.grey.shade300),
        labelStyle: const TextStyle(fontFamily: 'Poppins', color: cDarkBrown),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cDarkBrown,
        contentTextStyle:
            const TextStyle(fontFamily: 'Poppins', color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: cDarkBlue,
        thumbColor: cDarkBlue,
        inactiveTrackColor: Colors.grey.shade300,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: cDarkBlue),
      splashColor: cDarkBlue.withOpacity(0.2),
      highlightColor: cDarkBlue.withOpacity(0.1),
      hoverColor: cDarkBlue.withOpacity(0.05),
      fontFamily: 'Poppins',
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
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF232228),
        primary: cDarkBlue,
        surfaceTint: Colors.transparent,
      ),
      cardColor: const Color(0xFF232228),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF232228),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF232228),
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: EdgeInsets.zero,
      ),
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
