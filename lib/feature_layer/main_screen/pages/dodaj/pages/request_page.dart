import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nominatim_flutter/model/request/search_request.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_dropdown.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:qb/shared/widgets/w_label.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import 'package:latlong2/latlong.dart';

import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_card.dart';
import '../../../../../shared/widgets/w_checkbox.dart';
import '../../../bloc/main_bloc.dart';
import '../view/dodaj_page.dart';
import '../bloc/dodaj_page_bloc.dart';

class DodajRequestFormPage extends StatelessWidget {
  const DodajRequestFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<DodajPageBloc>(), // używa tej samej instancji
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
  late final TextEditingController businessCity = TextEditingController();

  String type = '';
  String color = '';
  LatLng? selectedLocation;
  bool? is24;

  String? selectedCategory;
  String? selectedBranza;
  Timer? debounce;
  bool isSearching=false;
  final MapController mapController = MapController();


  final Map<String, List<String>> categoryToBranza = categories;




  @override
  Widget build(BuildContext context) {
    var user = context.read<MainScreenBloc>().state.user;

    return BlocConsumer<DodajPageBloc, DodajPageState>(
      listener: (context, state) {
        if (state is DodajPageNextState) {
          context.read<MainScreenBloc>().add(InitEvent());
        }
      },
      builder: (context, state) {








        var categories = categoryToBranza.keys.toList();
        var branze =
        (selectedCategory != null &&
            categoryToBranza[selectedCategory] != null)
            ? List<String>.from(categoryToBranza[selectedCategory]!)
            : <String>[];

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                WSmallLabel(text: 'Szczegóły zgłoszenia'),

                SizedBox(height: 16),

                WInputField(
                  label: 'Opis zgłoszenia',
                  controller: name,
                  maxLines: 8,
                ),

                SizedBox(height: 24),
                WAnimatedDropdown(
                  controller: TextEditingController(),
                  // Twój controller, jeśli potrzebujesz
                  label: 'Wybierz kategorię',
                  items: categories,
                  hintText: 'Wybierz kategorię',
                  onItemSelected: (val) {
                    setState(() {
                      selectedCategory = val;
                      selectedBranza =
                      null; // reset branży przy zmianie kategorii
                    });
                  },
                ),
                SizedBox(height: 24),
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

                WInputField(
                    controller: businessCity,
                    label: 'Miejscowość',
                    isPassword: false,
                    hintText: 'Wpisz miejscowość',
                    onChanged: (value) {
                      if (debounce?.isActive ?? false) {
                        debounce!.cancel();
                      }

                      debounce = Timer(const Duration(milliseconds: 1100), () async {
                        if (value.trim().isEmpty) {
                          setState(() {
                            isSearching = false;
                          });
                          return;
                        }

                        setState(() {
                          isSearching = true;
                        });

                        final searchRequest = SearchRequest(
                          query: '$value, Polska',
                          limit: 1,
                          addressDetails: true,
                        );

                        try {
                          final results = await NominatimFlutter.instance.search(
                            searchRequest: searchRequest,
                            language: 'pl',
                          );

                          if (results.isNotEmpty) {
                            final result = results.first;
                            final lat = double.tryParse(result.lat ?? '') ?? 52.237049;
                            final lon = double.tryParse(result.lon ?? '') ?? 21.017532;

                            setState(() {
                              selectedLocation = LatLng(lat, lon);
                              mapController.move(selectedLocation!, 10.0);
                              isSearching = false;
                            });
                          } else {
                            // Brak wyników → ukryj spinner
                            setState(() {
                              isSearching = false;
                            });
                            // (Opcjonalnie) pokaż komunikat
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(content: Text('Nie znaleziono miejscowości')),
                            // );
                          }
                        } catch (e) {
                          // Obsługa błędu zapytania
                          setState(() {
                            isSearching = false;
                          });
                          debugPrint('Błąd zapytania do Nominatim: $e');
                        }
                      });
                    }
                ),

                SizedBox(height: 20),


                const SizedBox(height: 24),
                Text('lub ustaw na mapie'),
                const SizedBox(height: 24),

                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      FlutterMap(
                          mapController: mapController, // <--- TU
                          options: MapOptions(
                            initialCenter: selectedLocation??LatLng(52.237049, 21.017532),
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
                          ]),
                      if (isSearching)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.3), // półprzezroczyste tło
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),



                    ],
                  ),),




                SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WCheckbox(
                      isError: false,
                      value: is24 ?? false,
                      onChanged: (value) {
                        setState(() {
                          is24 = value;
                        });
                      },
                    ),
                    SizedBox(width: 16),
                    Flexible(
                      child: Text('Wyślij jako zgloszenie 24'
                      ),


                    ),
                  ],
                ),
                SizedBox(height: 24),

                WButton(
                text: 'Dodaj',
                onPressed: ()  {
                  context.read<DodajPageBloc>().state.requestMetadata=RequestMetadata(category: selectedCategory!, sector: selectedBranza!, location: selectedLocation!,city: businessCity.text, description: name.text, is24: is24??false);

                  context.read<DodajPageBloc>().add(DodajDodajPageEvent());
                },
              ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }
}
