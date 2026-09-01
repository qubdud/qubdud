import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../../app/app.dart';

showToastRegister({required String text, Color color = Colors.red, int milliseconds = 30000, bool positioned = true}) {
  var fToast = FToast();
  fToast.init(NavigationService.navigatorKey.currentContext!);
  fToast.showToast(
    gravity: ToastGravity.NONE,
    isDismissible: false,
    toastDuration: Duration(milliseconds: milliseconds),
    child: Container(
      width: MediaQuery.of(NavigationService.navigatorKey.currentContext!).size.width,
      height: MediaQuery.of(NavigationService.navigatorKey.currentContext!).size.height,
      color: cDarkBrown,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(NavigationService.navigatorKey.currentContext!).size.width,
            height: 330,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Material(
                color: Theme.of(NavigationService.navigatorKey.currentContext!).brightness == Brightness.dark ? const Color(0xFF2A2930) : Colors.white,
                elevation: 8, // Ustawienie cienia
                borderRadius: BorderRadius.circular(8), // Opcjonalnie, jeśli chcesz zaokrąglić rogi
                child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        const Icon(
                          Icons.check_circle_outline,
                          size: 70,
                        ),
                        const SizedBox(height: 24),
                        const Center(
                            child: SelectableText('Karta została pomyślnie zarejestrowana',
                                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: cDarkBrown))),
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              fToast.removeCustomToast();
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return Colors.white;
                                }
                                return cDarkBrown;
                              }),
                              foregroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return cDarkBrown;
                                }
                                return cMidBrown;
                              }),
                              overlayColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return Colors.green.withOpacity(0.2);
                                }
                                return Colors.transparent;
                              }),
                              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                  side: const BorderSide(color: cDarkBrown, width: 2),
                                ),
                              ),
                            ),
                            child: const SelectableText(
                              'Zamknij',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
