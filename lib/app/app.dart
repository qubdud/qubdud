
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../domain_layer/chat_service.dart';
import '../domain_layer/firebase_service.dart';
import '../domain_layer/repository.dart';
import '../feature_layer/core_screen/view/core_screen.dart';
import '../feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import '../shared/constants.dart';

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class App extends StatelessWidget {
  App({super.key, required this.appRepository});

  final AppRepository appRepository;



  @override
  Widget build(BuildContext context) {
    final appChatService = ChatService();
    final appFirebaseService = FirebaseService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(
          value: appRepository,
        ),
        RepositoryProvider.value(
          value: appChatService,
        ),
        RepositoryProvider.value(
          value: appFirebaseService,
        ),


      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: FToastBuilder(),
        navigatorKey: NavigationService.navigatorKey,

        theme: ThemeData(
          splashColor: cDarkBlue.withOpacity(0.2),
          // Domyślny kolor splash
          highlightColor: cDarkBlue.withOpacity(0.1),
          // Poświata po kliknięciu
          hoverColor: cDarkBlue.withOpacity(0.05),
          // Efekt hover (dla des

          fontFamily: 'FiraSans',
          // Globalna czcionka dla całej aplikacji

          appBarTheme: const AppBarTheme(
            scrolledUnderElevation: 0.0, // Remove shadow when scrolling
            backgroundColor: Colors.white, // Default background color
            titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: cDarkBrown,
              fontFamily: 'Poppins',
            ),
            iconTheme: IconThemeData(
              color: cDarkBrown, // Default color for leading/trailing icons
            ),
          ),

          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.all(Colors.transparent), // Usuwa efekt kliknięcia
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
        ),

        home: const CoreScreen(), // const LoginPage(),
      ),
    );
  }
}
