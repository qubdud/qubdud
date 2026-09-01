import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../shared/constants.dart';
import '../../../domain_layer/domain_models/app_data.dart';
import '../../../shared/widgets/w_button.dart';

class ActualizationRequiredPage extends StatefulWidget {
  final AppData appData;

  const ActualizationRequiredPage({super.key, required this.appData});

  @override
  State<ActualizationRequiredPage> createState() => _ActualizationRequiredPageState();
}

class _ActualizationRequiredPageState extends State<ActualizationRequiredPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Logo and Title Section
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top), // Optional padding
              Image.asset(
                'assets/logotypy.png',
                width: MediaQuery.of(context).size.width / 2,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60.0),
                child: Image.asset(
                  'assets/7_male.png', // Replace with your logo asset
                  fit: BoxFit.fitWidth,
                ),
              ),
              const SizedBox(height: 60),
              //   const SelectableText(
              //     'AKTUALIZACJA',
              //     style: TextStyle(
              //       fontFamily: 'Poppins',
              //       fontSize: 40,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SelectableText(
                    'WYMAGANA AKTUALIZACJA',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  SelectableText.rich(
                    // textAlign: TextAlign,
                   TextSpan(
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontFamily: 'FiraSans',
                        color: cDarkBrown,
                      ),
                      children: [
                        const TextSpan(text: 'Twoja aplikacja wymaga aktualizacji. Kliknij w przycisk aby pobrać nową wersję!'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                      child: WButton(
                    text: 'PPRZEJDŹ DO SKLEPU',
                    onPressed: () async {
                      if (Platform.isIOS) {
                        if (await canLaunchUrl(Uri.parse(widget.appData.appPlatform.ios.link))) {
                          await launchUrl(Uri.parse(widget.appData.appPlatform.ios.link));
                        }
                      }
                      if (Platform.isAndroid) {
                        if (await canLaunchUrl(Uri.parse(widget.appData.appPlatform.android.link))) {
                          await launchUrl(Uri.parse(widget.appData.appPlatform.android.link));
                        }
                      }
                    },
                  )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Register Section
        ],
      ),
    );
  }
}
