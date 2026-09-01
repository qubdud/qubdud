import 'package:flutter_map/flutter_map.dart';
import 'package:qb/data_layer/data_models/request/create_team.dart';
import 'package:qb/data_layer/data_models/request/edit_team.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_dropdown.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:qb/shared/widgets/w_label.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:latlong2/latlong.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/show_promo_page_bloc.dart';

class ShowPromoPage extends StatelessWidget {
  const ShowPromoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ShowPromoPageBloc(repository: context.read<AppRepository>()),
      child: const View(),
    );
  }
}

class View extends StatefulWidget {
  const View({super.key});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {
  String? messageError;
  String? nameError;
  late final TextEditingController name = TextEditingController();
  String type = '';
  String color = '';
  LatLng? selectedLocation;

  String? selectedCategory;
  String? selectedBranza;

  final Map<String, List<String>> categoryToBranza = {
    'Budowlane i Remontowe': [
      'Brukarz',
      'Budowa domów murowanych',
      'Dekarz',
      'Elektryk',
      'Geodeta',
      'Glazurnik',
      'Hydraulik',
      'Kominiarz',
      'Murarz',
      'Posadzki',
      'Remonty',
      'Tynkarz',
      'Wykończenia wnętrz',
      'Wynajem sprzętu budowlanego',
      'Złota rączka',
    ],
    'Edukacja Kursy Szkolenia': [
      'Korepetycje',
      'Kurs kosmetyczny',
      'Kurs makijażu',
      'Kurs nurkowania',
      'Kurs prawa jazdy',
      'Kurs programowania dla dzieci',
      'Kursy językowe',
      'Nauka jazdy konnej',
      'Nauka tańca',
      'Przedszkola',
      'Szkolenia BHP',
      'Szkolenia i kursy',
      'Szkoła',
      'Żłobek',
    ],
    // Dodaj pozostałe kategorie i branże według wzoru
  };


  @override
  void initState() {
    super.initState();
    final state = context
        .read<ShowPromoPageBloc>()
        .state;
    if (state is ShowPromoPageMainState) {}
  }

  Widget build(BuildContext context) {


    return BlocConsumer<ShowPromoPageBloc, ShowPromoPageState>(
      listener: (context, state) {
        if (state is ShowPromoPageNextState) {
          context.read<MainScreenBloc>().add(InitEvent());
        }
      },
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildWidgetBasedOnState(state, context),
        );
      },
    );
  }

  Widget _buildWidgetBasedOnState(ShowPromoPageState state,
      BuildContext context) {
    final isWideScreen = MediaQuery
        .of(context)
        .size
        .width > minWideScreen;

    if (state is ShowPromoPageLoadingState) {
      return const Loading(key: ValueKey('Loading'));
    } else if (state is! ShowPromoPageLoadingState) {
      var categories = categoryToBranza.keys.toList();
      var branze = (selectedCategory != null &&
          categoryToBranza[selectedCategory] != null)
          ? List<String>.from(categoryToBranza[selectedCategory]!)
          : <String>[];


      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [

            SizedBox(height: 16,),
          WAnimatedDropdown(
            controller: TextEditingController(),
            // Twój controller, jeśli potrzebujesz
            label: 'Wybierz kategorię',
            items: categories,
            hintText: 'Wybierz kategorię',
            onItemSelected: (val) {
              setState(() {
                selectedCategory = val;
                selectedBranza = null; // reset branży przy zmianie kategorii
              });
            },
          ),
          SizedBox(height: 20),
          WAnimatedDropdown(
            controller: TextEditingController(),
            // Twój controller, jeśli potrzebujesz
            label: 'Wybierz branżę',
            items: branze as List<String>,
            hintText: selectedCategory == null
                ? 'Wybierz najpierw kategorię'
                : 'Wybierz branżę',
            onItemSelected: (val) {
              setState(() {
                selectedBranza = val;
              });
            },
          ),
          SizedBox(height: 20),

          SizedBox(
            height: 200,
            child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(52.237049, 21.017532),
                  initialZoom: 6,
                  onTap: (tapPos, point) {
                    setState(() {
                      selectedLocation = point;
                    });
                  },

                ),
                children: [openStreetMap,
                  if (selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLocation!,
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),


                      ],

                    ),
                ]),),


            SizedBox(
              height: 24,
            ),
            WButton(
              text: 'Wyszukaj',
              onPressed: () {

                Globals.instance.pozycja=selectedLocation??LatLng(52.237049, 21.017532);
                Globals.instance.branza=selectedBranza??'';
                Globals.instance.kategoria=selectedCategory??'';


                context.read<MainScreenBloc>().add(GoToHomeEvent());
              },
            ),
            const SizedBox(height: 60),
          ],
          ),
        ),
      );
    } else {
      return const Loading(key: ValueKey('Loading'));
    }
  }
}



TileLayer get openStreetMap =>
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleatflet.flutter.map.example',
    );


LatLng _getLatLng(String coordinates) {
  try {
    // Sprawdź, czy URL zawiera znak "@"
    if (!coordinates.contains('@')) {
      throw const FormatException("Niepoprawny URL - brak znaku '@'");
    }

    // Pobierz część po znaku '@'
    final coordsPart = coordinates.split('@')[1];

    // Rozdziel współrzędne po przecinku
    final parts = coordsPart.split(',');

    if (parts.length < 2) {
      throw const FormatException("Niepoprawny format współrzędnych w URL");
    }

    // Pobierz współrzędne - pierwsza i druga wartość to szerokość i długość geograficzna
    final lat = double.parse(parts[0].trim());
    final lng = double.parse(parts[1].trim());

    return LatLng(lat, lng);
  } catch (e) {
    // W przypadku błędu zwróć domyślną wartość lub obsłuż błąd
    print('Błąd parsowania współrzędnych z URL: $e');
    return const LatLng(0.0, 0.0); // Domyślna lokalizacja (możesz ją zmienić)
  }
}