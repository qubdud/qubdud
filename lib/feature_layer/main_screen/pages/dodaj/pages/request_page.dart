import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nominatim_flutter/model/request/reverse_request.dart';
import 'package:nominatim_flutter/model/request/search_request.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/functions/show_toast_error.dart';
import 'package:qb/shared/widgets/w_dropdown.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:latlong2/latlong.dart';

import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_checkbox.dart';
import '../../../bloc/main_bloc.dart';
import '../view/dodaj_page.dart';
import '../bloc/dodaj_page_bloc.dart';
import '../../../../../shared/request_questions.dart';

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
  late final TextEditingController name;
  late final TextEditingController businessCity;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _sectorCtrl;

  LatLng? selectedLocation;
  bool is24 = false;
  String _timing = '';
  final TextEditingController _budget = TextEditingController();
  Map<String, String> _answers = {};

  String? selectedCategory;
  String? selectedBranza;
  String? _categoryError;
  String? _sectorError;
  String? _locationError;
  String? _descError;
  Timer? debounce;
  bool isSearching = false;
  bool _locating = false;
  final MapController mapController = MapController();

  final Map<String, List<String>> categoryToBranza = categories;

  @override
  void initState() {
    super.initState();
    // po nieudanej wysyłce formularz wraca z wpisanymi danymi
    final meta = context.read<DodajPageBloc>().state.requestMetadata;
    name = TextEditingController(text: meta?.description ?? '');
    businessCity = TextEditingController(text: meta?.city ?? '');
    _categoryCtrl = TextEditingController(text: meta?.category ?? '');
    _sectorCtrl = TextEditingController(text: meta?.sector ?? '');
    selectedCategory = meta?.category;
    selectedBranza = meta?.sector;
    selectedLocation = meta?.location;
    is24 = meta?.is24 ?? false;
    _timing = meta?.timing ?? '';
    _budget.text = meta?.budget?.toString() ?? '';
    _answers = {...?meta?.answers};
  }

  @override
  void dispose() {
    debounce?.cancel();
    name.dispose();
    businessCity.dispose();
    _categoryCtrl.dispose();
    _sectorCtrl.dispose();
    _budget.dispose();
    super.dispose();
  }

  void _locationHint(String text, {String? action, VoidCallback? onAction}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      action: action == null
          ? null
          : SnackBarAction(label: action, onPressed: onAction!),
    ));
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _locationHint('Lokalizacja w telefonie jest wyłączona',
            action: 'Włącz', onAction: Geolocator.openLocationSettings);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _locationHint('Brak zgody na lokalizację — włączysz ją w ustawieniach',
            action: 'Ustawienia', onAction: Geolocator.openAppSettings);
        return;
      }
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        _locationHint('Bez zgody na lokalizację ustaw miejsce na mapie');
        return;
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 15)));
      } on TimeoutException {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) {
        _locationHint('Nie udało się ustalić lokalizacji — ustaw ją na mapie');
        return;
      }
      if (!mounted) return;
      final here = LatLng(pos.latitude, pos.longitude);
      debounce?.cancel();
      setState(() {
        selectedLocation = here;
        _locationError = null;
      });
      mapController.move(here, 14);
      final city = await _cityAt(here);
      if (city != null && mounted) businessCity.text = city;
    } catch (_) {
      _locationHint('Nie udało się ustalić lokalizacji — ustaw ją na mapie');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<String?> _cityAt(LatLng p) async {
    try {
      final r = await NominatimFlutter.instance.reverse(
        reverseRequest: ReverseRequest(
            lat: p.latitude, lon: p.longitude, extraTags: false, nameDetails: false),
        language: 'pl',
      );
      final a = r.address ?? const {};
      for (final k in ['city', 'town', 'village', 'municipality']) {
        final v = a[k];
        if (v is String && v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  void _onCityChanged(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 1100), () async {
      if (value.trim().isEmpty) {
        if (mounted) setState(() => isSearching = false);
        return;
      }
      setState(() => isSearching = true);
      try {
        final results = await NominatimFlutter.instance.search(
          searchRequest: SearchRequest(
            query: '$value, Polska',
            limit: 1,
            addressDetails: true,
          ),
          language: 'pl',
        );
        if (!mounted) return;
        setState(() {
          isSearching = false;
          if (results.isNotEmpty) {
            final lat = double.tryParse(results.first.lat ?? '');
            final lon = double.tryParse(results.first.lon ?? '');
            if (lat != null && lon != null) {
              selectedLocation = LatLng(lat, lon);
              _locationError = null;
              mapController.move(selectedLocation!, 10.0);
            }
          }
        });
      } catch (e) {
        if (mounted) setState(() => isSearching = false);
        debugPrint('Błąd zapytania do Nominatim: $e');
      }
    });
  }

  void _submit() {
    setState(() {
      _categoryError = selectedCategory == null ? 'Wybierz kategorię' : null;
      _sectorError = selectedBranza == null ? 'Wybierz branżę' : null;
      _locationError = selectedLocation == null
          ? 'Wpisz miejscowość albo wskaż punkt na mapie'
          : null;
      _descError = context.read<DodajPageBloc>().state.selectedContent == null &&
              name.text.trim().length < 10
          ? 'Bez zdjęcia opisz dokładniej, czego potrzebujesz (min. 10 znaków)'
          : null;
    });
    if (_categoryError != null || _sectorError != null || _locationError != null ||
        _descError != null) {
      showToastError(text: 'Uzupełnij zaznaczone pola');
      return;
    }
    final bloc = context.read<DodajPageBloc>();
    bloc.state.requestMetadata = RequestMetadata(
      category: selectedCategory!,
      sector: selectedBranza!,
      location: selectedLocation!,
      city: businessCity.text.trim(),
      description: name.text.trim(),
      is24: is24 && kEmergencySectors.contains(selectedBranza),
      timing: _timing,
      budget: int.tryParse(_budget.text.trim()),
      answers: _answers,
    );
    bloc.add(DodajDodajPageEvent());
  }

  Widget _chipsQuestion(String label, List<String> options, String? selected,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WSmallLabel(text: label),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final o in options)
                ChoiceChip(
                  label: Text(o),
                  selected: selected == o,
                  onSelected: (s) => onChanged(s ? o : null),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DodajPageBloc, DodajPageState>(
      listener: (context, state) {
        if (state is DodajPageNextState) {
          context.read<MainScreenBloc>().add(InitEvent());
        }
      },
      builder: (context, state) {
        final categories = categoryToBranza.keys.toList();
        final branze = selectedCategory != null
            ? List<String>.from(categoryToBranza[selectedCategory] ?? const [])
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
                  errorText: _descError,
                ),

                SizedBox(height: 24),
                WAnimatedDropdown(
                  controller: _categoryCtrl,
                  label: 'Wybierz kategorię',
                  errorText: _categoryError,
                  items: categories,
                  hintText: 'Wybierz kategorię',
                  onItemSelected: (val) {
                    setState(() {
                      selectedCategory = val.isEmpty ? null : val;
                      _answers = {};
                      if (selectedCategory != null) _categoryError = null;
                      // reset branży przy zmianie kategorii
                      selectedBranza = null;
                      _sectorCtrl.clear();
                      is24 = false;
                    });
                  },
                ),
                SizedBox(height: 24),
                WAnimatedDropdown(
                  controller: _sectorCtrl,
                  label: 'Wybierz branżę',
                  errorText: _sectorError,
                  items: branze,
                  hintText: selectedCategory == null
                      ? 'Wybierz najpierw kategorię'
                      : 'Wybierz branżę',
                  onItemSelected: (val) {
                    setState(() {
                      selectedBranza = val.isEmpty ? null : val;
                      if (selectedBranza != null) _sectorError = null;
                      if (!kEmergencySectors.contains(selectedBranza)) is24 = false;
                      final qs = requestQuestionsFor(selectedCategory, selectedBranza);
                      _answers.removeWhere((k, v) =>
                          !qs.any((q) => q.label == k && q.options.contains(v)));
                    });
                  },
                ),
                SizedBox(height: 20),

                WInputField(
                    controller: businessCity,
                    label: 'Miejscowość',
                    isPassword: false,
                    hintText: 'Wpisz miejscowość',
                    onChanged: _onCityChanged,
                ),

                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _locating ? null : _useMyLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                  label: const Text('Użyj mojej lokalizacji'),
                ),
                const SizedBox(height: 28),
                Text('lub ustaw na mapie'),
                const SizedBox(height: 24),

                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: selectedLocation??LatLng(52.237049, 21.017532),
                            initialZoom: selectedLocation == null ? 6 : 10,
                            onTap: (tapPos, point) {
                              setState(() {
                                selectedLocation = point;
                                _locationError = null;
                              });
                            },

                          ),
                          children: [openStreetMap, osmAttribution,
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
                      if (isSearching || _locating)
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
                if (_locationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_locationError!,
                        style: const TextStyle(fontSize: 14, color: cMidPink)),
                  ),

                const SizedBox(height: 24),
                _chipsQuestion('Kiedy?', kRequestTiming.values.toList(),
                    kRequestTiming[_timing], (v) {
                  setState(() => _timing = v == null
                      ? ''
                      : kRequestTiming.entries.firstWhere((e) => e.value == v).key);
                }),
                for (final q in requestQuestionsFor(selectedCategory, selectedBranza))
                  _chipsQuestion(q.label, q.options, _answers[q.label], (v) {
                    setState(() => v == null ? _answers.remove(q.label) : _answers[q.label] = v);
                  }),
                WInputField(
                  controller: _budget,
                  label: 'Budżet (opcjonalnie, zł)',
                  isPassword: false,
                  hintText: 'np. 500',
                  keyboardType: TextInputType.number,
                  // reguły przyjmują 0..9 999 999 — inaczej zapis odpada dopiero po wysłaniu pliku
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                ),

                SizedBox(height: 24),

                if (kEmergencySectors.contains(selectedBranza)) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WCheckbox(
                        isError: false,
                        value: is24,
                        onChanged: (value) {
                          setState(() {
                            is24 = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      const Flexible(
                        child: Text('🔴 Awaria — potrzebuję pomocy w ciągu 24 h'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                WButton(
                  text: 'Dodaj',
                  isEnabled: !isSearching,
                  onPressed: _submit,
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
