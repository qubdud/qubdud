import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nominatim_flutter/model/request/search_request.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';

import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/constants.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_checkbox.dart';
import '../../../../../shared/widgets/w_dropdown.dart';
import '../../../../../shared/widgets/w_input_field.dart';
import '../../../../../shared/widgets/w_label.dart';
import '../../../../../shared/widgets/w_small_label.dart';
import '../../../../../shared/widgets/loading.dart';
import '../../../../main_screen/pages/dodaj/view/dodaj_page.dart';
import '../../../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _password = TextEditingController();
  final _nip = TextEditingController();
  final _companyName = TextEditingController();
  final _street = TextEditingController();
  final _buildingNr = TextEditingController();
  final _flatNr = TextEditingController();
  final _city = TextEditingController();
  final _postCode = TextEditingController();
  final _businessCity = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final MapController _mapController = MapController();

  bool _isCompany = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _acceptTerms = false;

  String? _nameError;
  String? _surnameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _nipError;
  String? _companyNameError;
  String? _categoryError;
  String? _sectorError;
  String? _locationError;
  String? _termsError;

  String? _selectedCategory;
  String? _selectedSector;
  LatLng? _selectedLocation;

  Timer? _debounce;

  final Map<String, List<String>> _categoryToSector = categories;

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [
      _name, _surname, _email, _phone, _bio, _password,
      _nip, _companyName, _street, _buildingNr, _flatNr,
      _city, _postCode, _businessCity, _categoryCtrl, _sectorCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    setState(() {
      _nameError = _name.text.trim().isEmpty ? 'Pole wymagane' : null;
      _surnameError = _surname.text.trim().isEmpty ? 'Pole wymagane' : null;
      _emailError = _email.text.trim().isEmpty
          ? 'Pole wymagane'
          : (!emailRegex.hasMatch(_email.text.trim())
              ? 'Nieprawidłowy adres e-mail'
              : null);
      _phoneError = _phone.text.trim().isEmpty
          ? 'Pole wymagane'
          : (_phone.text.trim().length > 50 ? 'Za długi numer' : null);
      _passwordError = _password.text.length < 6
          ? 'Hasło musi mieć min. 6 znaków'
          : null;
      if (_isCompany) {
        _nipError =
            _nip.text.trim().length != 10 ? 'NIP musi mieć 10 cyfr' : null;
        _companyNameError =
            _companyName.text.trim().isEmpty ? 'Pole wymagane' : null;
        _categoryError = _selectedCategory == null ? 'Wybierz kategorię' : null;
        _sectorError = _selectedSector == null ? 'Wybierz branżę' : null;
        _locationError = _selectedLocation == null
            ? 'Wskaż lokalizację działalności (wpisz miejscowość lub zaznacz na mapie)'
            : null;
      } else {
        _nipError = null;
        _companyNameError = null;
        _categoryError = null;
        _sectorError = null;
        _locationError = null;
      }
      _termsError = _acceptTerms ? null : 'Zgoda jest wymagana';
    });
    return [
      _nameError, _surnameError, _emailError, _phoneError, _passwordError,
      _nipError, _companyNameError, _categoryError, _sectorError,
      _locationError, _termsError,
    ].every((e) => e == null);
  }

  Future<void> _register() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      final firebaseService = context.read<FirebaseService>();
      final error = await firebaseService.registerUser(
        email: _email.text.trim(),
        password: _password.text,
        firstName: _name.text.trim(),
        lastName: _surname.text.trim(),
        phone: _phone.text.trim(),
        bio: _bio.text.trim(),
        isCompany: _isCompany,
        nip: _isCompany ? _nip.text.trim() : null,
        companyName: _isCompany ? _companyName.text.trim() : null,
        companyCategory: _isCompany ? _selectedCategory : null,
        companySector: _isCompany ? _selectedSector : null,
        companyLocation: _isCompany ? _selectedLocation : null,
        companyCity: _isCompany ? _businessCity.text.trim() : null,
        companyAddress: _isCompany
            ? {
                'street': _street.text.trim(),
                'buildingNr': _buildingNr.text.trim(),
                'flatNr': _flatNr.text.trim(),
                'city': _city.text.trim(),
                'postCode': _postCode.text.trim(),
              }
            : null,
      );
      if (!mounted) return;
      if (error != null) {
        setState(() => _emailError = _mapError(error));
      } else {
        context.read<AuthBloc>().add(AuthGoToRegistrationCompletePageEvent());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nie udało się założyć konta. Sprawdź połączenie i spróbuj ponownie.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapError(String e) {
    if (e.contains('email-already-in-use')) return 'Ten e-mail jest już zarejestrowany.';
    if (e.contains('invalid-email')) return 'Nieprawidłowy adres e-mail.';
    if (e.contains('weak-password')) return 'Hasło za słabe (min. 6 znaków).';
    if (e.contains('network-request-failed')) return 'Brak połączenia z internetem.';
    if (e.contains('too-many-requests')) return 'Za dużo prób — spróbuj za chwilę.';
    if (e.contains('operation-not-allowed')) return 'Rejestracja e-mailem jest wyłączona.';
    return 'Rejestracja nie powiodła się ($e).';
  }

  void _onCityChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      if (value.trim().isEmpty) return;
      setState(() => _isSearching = true);
      try {
        final results = await NominatimFlutter.instance.search(
          searchRequest: SearchRequest(
            query: '$value, Polska',
            limit: 1,
            addressDetails: true,
          ),
          language: 'pl',
        );
        if (results.isNotEmpty && mounted) {
          final lat = double.tryParse(results.first.lat ?? '') ?? 52.237049;
          final lon = double.tryParse(results.first.lon ?? '') ?? 21.017532;
          setState(() {
            _selectedLocation = LatLng(lat, lon);
            _mapController.move(_selectedLocation!, 10.0);
          });
        }
      } catch (_) {}
      if (mounted) setState(() => _isSearching = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Loading();

    final topPadding = MediaQuery.of(context).padding.top;
    final sectors = (_selectedCategory != null &&
            _categoryToSector[_selectedCategory] != null)
        ? List<String>.from(_categoryToSector[_selectedCategory]!)
        : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding > 1 ? topPadding : 64),
          const SizedBox(height: 20),
          Center(
            child: Text('QUBDUD',
                style: const TextStyle(fontSize: 33, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => context.read<AuthBloc>().add(AuthGoToLoginPageEvent()),
              child: const Text('< Wróć',
                  style: TextStyle(
                    color: cDarkerBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  )),
            ),
          ),
          const SizedBox(height: 20),
          Center(child: WLabel(text: 'Rejestracja')),

          // ──── DANE OSOBOWE ────────────────────────────────────
          const SizedBox(height: 24),
          WSmallLabel(text: 'Dane osobowe'),
          const SizedBox(height: 16),
          WInputField(controller: _name, label: 'Imię', errorText: _nameError,
              isPassword: false, hintText: 'Wpisz imię'),
          const SizedBox(height: 24),
          WInputField(controller: _surname, label: 'Nazwisko', errorText: _surnameError,
              isPassword: false, hintText: 'Wpisz nazwisko'),
          const SizedBox(height: 24),
          WInputField(controller: _email, label: 'E-mail', errorText: _emailError,
              isPassword: false, hintText: 'Wpisz adres e-mail',
              ),
          const SizedBox(height: 24),

          // ──── TELEFON ─────────────────────────────────────────
          WInputField(controller: _phone, label: 'Telefon', errorText: _phoneError,
              isPassword: false, hintText: 'Wpisz numer telefonu',
             // keyboardType: TextInputType.phone
              ),
          const SizedBox(height: 6),
          Text(_isCompany
                  ? 'Telefon firmy jest widoczny na jej profilu (możesz go ukryć w ustawieniach).'
                  : 'Telefon i e-mail zobaczy tylko firma, której ofertę przyjmiesz '
                      'albo u której zarezerwujesz termin.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 24),

          // ──── OPIS PUBLICZNY ──────────────────────────────────
          WInputField(controller: _bio,
              label: 'Opis (opcjonalny)',
              isPassword: false,
              hintText: 'Krótki opis widoczny publicznie na Twoim profilu',
              maxLines: 3),
          const SizedBox(height: 24),

          // ──── CHECKBOX FIRMA ──────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WCheckbox(
                isError: false,
                value: _isCompany,
                onChanged: (val) => setState(() => _isCompany = val ?? false),
              ),
              const SizedBox(width: 16),
              const Flexible(child: Text('Rejestruj jako firma',
                  style: TextStyle(fontSize: 16))),
            ],
          ),

          // ──── SEKCJA FIRMY ────────────────────────────────────
          if (_isCompany) ...[
            const SizedBox(height: 32),
            WSmallLabel(text: 'Dane firmy'),
            const SizedBox(height: 16),
            WInputField(controller: _nip, label: 'NIP', errorText: _nipError,
                isPassword: false, hintText: 'Wpisz 10-cyfrowy NIP',
              //  keyboardType: TextInputType.number,
                onChanged: (val) {
                  final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
                  final limited = cleaned.length > 10 ? cleaned.substring(0, 10) : cleaned;
                  if (val != limited) {
                    _nip.value = TextEditingValue(
                      text: limited,
                      selection: TextSelection.collapsed(offset: limited.length),
                    );
                  }
                }),
            const SizedBox(height: 24),
            WInputField(controller: _companyName, label: 'Nazwa firmy',
                errorText: _companyNameError,
                isPassword: false, hintText: 'Pełna nazwa firmy'),
            const SizedBox(height: 24),
            WInputField(controller: _street, label: 'Ulica',
                isPassword: false, hintText: 'Ulica (adres rejestrowy)'),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: WInputField(controller: _buildingNr,
                  label: 'Nr budynku', isPassword: false, hintText: 'Nr')),
              const SizedBox(width: 16),
              Expanded(child: WInputField(controller: _flatNr,
                  label: 'Nr lokalu', isPassword: false, hintText: 'Nr (opcjonalnie)')),
            ]),
            const SizedBox(height: 24),
            WInputField(controller: _city, label: 'Miejscowość (adres)',
                isPassword: false, hintText: 'Miejscowość'),
            const SizedBox(height: 24),
            WInputField(controller: _postCode, label: 'Kod pocztowy',
                isPassword: false, hintText: '00-000',
             //   keyboardType: TextInputType.number
            ),
            const SizedBox(height: 32),

            WSmallLabel(text: 'Branża i lokalizacja działalności'),
            const SizedBox(height: 16),
            WAnimatedDropdown(
              controller: _categoryCtrl,
              label: 'Wybierz kategorię',
              errorText: _categoryError,
              items: _categoryToSector.keys.toList(),
              hintText: 'Wybierz kategorię',
              onItemSelected: (val) => setState(() {
                _selectedCategory = val.isEmpty ? null : val;
                _selectedSector = null;
                _sectorCtrl.clear();
              }),
            ),
            const SizedBox(height: 24),
            WAnimatedDropdown(
              controller: _sectorCtrl,
              label: 'Wybierz branżę',
              errorText: _sectorError,
              items: sectors,
              hintText: _selectedCategory == null
                  ? 'Najpierw wybierz kategorię'
                  : 'Wybierz branżę',
              onItemSelected: (val) =>
                  setState(() => _selectedSector = val.isEmpty ? null : val),
            ),
            const SizedBox(height: 24),
            WInputField(
              controller: _businessCity,
              label: 'Miejscowość działalności',
              isPassword: false,
              hintText: 'Wpisz miejscowość (do mapy)',
              onChanged: _onCityChanged,
            ),
            const SizedBox(height: 8),
            const Text('lub zaznacz lokalizację na mapie:',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),

            SizedBox(
              height: 220,
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation ?? const LatLng(52.237049, 21.017532),
                      initialZoom: 6,
                      onTap: (_, point) => setState(() => _selectedLocation = point),
                    ),
                    children: [
                      openStreetMap, osmAttribution,
                      if (_selectedLocation != null)
                        MarkerLayer(markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 40, height: 40,
                            child: const Icon(Icons.location_pin,
                                color: Colors.red, size: 40),
                          ),
                        ]),
                    ],
                  ),
                ),
                if (_isSearching)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ]),
            ),
            if (_locationError != null) ...[
              const SizedBox(height: 6),
              Text(_locationError!,
                  style: const TextStyle(color: cMidPink, fontSize: 14)),
            ],
            const SizedBox(height: 6),
            Text(
              'Z tą lokalizacją będą powiązane Twoje filmy — po niej znajdą Cię użytkownicy w wyszukiwarce.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],

          // ──── HASŁO ───────────────────────────────────────────
          const SizedBox(height: 40),
          WSmallLabel(text: 'Hasło'),
          const SizedBox(height: 16),
          WInputField(
            controller: _password,
            label: 'Hasło',
            errorText: _passwordError,
            hintText: 'Min. 6 znaków',
            isPassword: true,
            obscureText: _obscurePassword,
            onTogglePasswordVisibility: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),

          // ──── ZGODY ───────────────────────────────────────────
          const SizedBox(height: 40),
          WSmallLabel(text: 'Zgody i oświadczenia'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WCheckbox(
                isError: _termsError != null,
                value: _acceptTerms,
                onChanged: (val) => setState(() {
                  _acceptTerms = val ?? false;
                  if (_acceptTerms) _termsError = null;
                }),
              ),
              const SizedBox(width: 16),
              const Flexible(
                child: Text(
                  'Akceptuję regulamin aplikacji i wyrażam zgodę na przetwarzanie moich danych osobowych '
                  '(imię, nazwisko, e-mail, telefon, a w przypadku firmy także jej dane) w celu świadczenia '
                  'usług aplikacji, zgodnie z RODO. Regulamin jest dostępny w aplikacji w menu „Regulamin".',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          if (_termsError != null) ...[
            const SizedBox(height: 6),
            Text(_termsError!,
                style: const TextStyle(color: cMidPink, fontSize: 14)),
          ],

          const SizedBox(height: 32),
          WButton(text: 'Zarejestruj się', onPressed: _register),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
