import 'package:qb/shared/widgets/empty_state.dart';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nominatim_flutter/model/request/search_request.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';

import '../../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../dodaj/view/dodaj_page.dart';
import '../../../../../../domain_layer/firebase_service.dart';
import '../../../../../../shared/constants.dart';
import '../../../../../../shared/functions/effective_role.dart';
import '../../../../../../shared/globals.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../../shared/widgets/request_take_status.dart';
import '../../../../../../shared/widgets/w_button.dart';
import '../../../../../../shared/widgets/w_input_field.dart';
import '../../../../../../shared/widgets/w_small_label.dart';
import '../../../bloc/main_appbar_cubit.dart';
import '../../../../../../feature_layer/main_screen/bloc/main_bloc.dart';
import '../bloc/profil_my_page_bloc.dart';
import 'tab_kalendarz.dart';
import 'tab_klienci.dart';

class MyProfilPage extends StatelessWidget {
  const MyProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyProfilPageBloc(firebase: context.read<FirebaseService>()),
      child: const _ProfilView(),
    );
  }
}

class _ProfilView extends StatefulWidget {
  const _ProfilView();

  @override
  State<_ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<_ProfilView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final user = context.read<MainScreenBloc>().state.user;
    final isCompany = isCompanyMode(user);
    _tabController = TabController(
      length: isCompany ? 7 : 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyProfilPageBloc, MyProfilPageState>(
      listener: (context, state) {},
      builder: (context, state) {
        context.read<MainScreenControlCubit>().updateAppBar(height: 56, child: null);

        final user = context.read<MainScreenBloc>().state.user;

        // Anonimowy
        if (user == null || user.id.isEmpty || Globals.instance.anonim == true) {
          return _buildAnonimView();
        }

        if (state is MyProfilPageLoadingState) {
          return const Loading(key: ValueKey('Loading'));
        }

        if (state is! MyProfilPageMainState) {
          return const Loading(key: ValueKey('Loading'));
        }

        final isCompany = isCompanyMode(user);

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              const Tab(text: 'Moje dane'),
              if (isCompany) const Tab(text: 'Kalendarz'),
              if (isCompany) const Tab(text: 'Klienci'),
              if (isCompany) const Tab(text: 'Zgłoszenia'),
              const Tab(text: 'Recenzje'),
              if (isCompany) const Tab(text: 'Prezentacje'),
              if (isCompany) const Tab(icon: Icon(Icons.delete_outline, size: 18)),
              if (!isCompany) const Tab(text: 'Moje firmy'),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _TabDane(state: state, isCompany: isCompany, user: user),
              if (isCompany)
                TabKalendarz(companyId: user.id, showBookings: false),
              if (isCompany) TabKlienci(companyId: user.id),
              if (isCompany) _TabZgloszenia(state: state),
              _TabRecenzje(state: state),
              if (isCompany) _TabPrezentacje(state: state),
              if (isCompany) _TabKosz(state: state),
              if (!isCompany) TabMojeFirmy(userId: user.id),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnonimView() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text('Przeglądasz aplikację anonimowo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text(
                'Zarejestruj się lub zaloguj, aby korzystać z pełnych możliwości.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 40),
            WButton(
              text: 'Zaloguj się',
              onPressed: () => context.read<MainScreenBloc>().add(LogoutEvent()),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.read<MainScreenBloc>().add(LogoutEvent()),
              child: const Text('lub zarejestruj się',
                  style: TextStyle(
                    color: cDarkBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TAB 1 — MOJE DANE
// ──────────────────────────────────────────────────────────────────────────────
class _TabDane extends StatefulWidget {
  final MyProfilPageMainState state;
  final bool isCompany;
  final dynamic user;

  const _TabDane({required this.state, required this.isCompany, required this.user});

  @override
  State<_TabDane> createState() => _TabDaneState();
}

class _TabDaneState extends State<_TabDane> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _bio;
  late final TextEditingController _companyName;
  late final TextEditingController _street;
  late final TextEditingController _buildingNr;
  late final TextEditingController _flatNr;
  late final TextEditingController _city;
  late final TextEditingController _postCode;
  late final TextEditingController _businessCity;
  final MapController _mapController = MapController();

  LatLng? _selectedLocation;
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _firstName = TextEditingController(text: u?.firstName ?? '');
    _lastName = TextEditingController(text: u?.lastName ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _bio = TextEditingController(text: u?.bio ?? widget.state.companyInfo?.description ?? '');
    _companyName = TextEditingController(text: u?.companyName ?? '');
    final addr = u?.companyAddress ?? {};
    _street = TextEditingController(text: addr['street'] ?? '');
    _buildingNr = TextEditingController(text: addr['buildingNr'] ?? '');
    _flatNr = TextEditingController(text: addr['flatNr'] ?? '');
    _city = TextEditingController(text: addr['city'] ?? '');
    _postCode = TextEditingController(text: addr['postCode'] ?? '');
    _businessCity = TextEditingController(text: u?.companyCity ?? '');
    final loc = u?.companyLocation;
    if (loc != null && (loc.latitude != 0 || loc.longitude != 0)) {
      _selectedLocation = loc;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [
      _firstName, _lastName, _phone, _bio, _companyName,
      _street, _buildingNr, _flatNr, _city, _postCode, _businessCity,
    ]) {
      c.dispose();
    }
    super.dispose();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          if (!widget.isCompany) ...[
            // ── Dane użytkownika ──────────────────────────────
            WInputField(controller: _firstName, label: 'Imię',
                isPassword: false, hintText: 'Imię'),
            const SizedBox(height: 16),
            WInputField(controller: _lastName, label: 'Nazwisko',
                isPassword: false, hintText: 'Nazwisko'),
            const SizedBox(height: 16),
            WInputField(controller: _phone, label: 'Telefon',
                isPassword: false, hintText: 'Numer telefonu',

            ),
            const SizedBox(height: 16),
            WInputField(controller: _bio, label: 'Opis (publiczny)',
                isPassword: false, hintText: 'Krótki opis widoczny na profilu',
                maxLines: 4),
          ] else ...[
            // ── Dane firmy ────────────────────────────────────
            WInputField(controller: _companyName, label: 'Nazwa firmy',
                isPassword: false, hintText: 'Nazwa firmy'),
            const SizedBox(height: 16),
            WInputField(controller: _phone, label: 'Telefon kontaktowy',
                isPassword: false, hintText: 'Numer telefonu',

            ),
            const SizedBox(height: 16),
            WInputField(controller: _bio, label: 'Opis firmy (publiczny)',
                isPassword: false,
                hintText: 'Opis działalności widoczny na profilu firmy',
                maxLines: 6),

            const SizedBox(height: 32),
            WSmallLabel(text: 'Adres prowadzenia działalności'),
            const SizedBox(height: 16),
            WInputField(controller: _street, label: 'Ulica',
                isPassword: false, hintText: 'Ulica'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: WInputField(controller: _buildingNr,
                  label: 'Nr budynku', isPassword: false, hintText: 'Nr')),
              const SizedBox(width: 16),
              Expanded(child: WInputField(controller: _flatNr,
                  label: 'Nr lokalu', isPassword: false, hintText: 'Nr (opcjonalnie)')),
            ]),
            const SizedBox(height: 16),
            WInputField(controller: _city, label: 'Miejscowość (adres)',
                isPassword: false, hintText: 'Miejscowość'),
            const SizedBox(height: 16),
            WInputField(controller: _postCode, label: 'Kod pocztowy',
                isPassword: false, hintText: '00-000'),

            const SizedBox(height: 32),
            WSmallLabel(text: 'Lokalizacja działalności'),
            const SizedBox(height: 8),
            Text(
              'Z tą lokalizacją powiązane są Twoje filmy — po niej znajdą Cię użytkownicy w wyszukiwarce. '
              'Zmiana przenosi też już opublikowane filmy.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
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
                      initialCenter: _selectedLocation ??
                          const LatLng(52.237049, 21.017532),
                      initialZoom: _selectedLocation == null ? 6 : 10,
                      onTap: (_, point) =>
                          setState(() => _selectedLocation = point),
                    ),
                    children: [
                      openStreetMap,
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
          ],

          const SizedBox(height: 24),
          WButton(
            text: 'Zapisz',
            onPressed: () {
              if (widget.isCompany) {
                context.read<MyProfilPageBloc>().add(UpdateCompanyDataEvent(
                  companyName: _companyName.text.trim(),
                  bio: _bio.text.trim(),
                  phone: _phone.text.trim(),
                  companyCity: _businessCity.text.trim(),
                  companyLocation: _selectedLocation,
                  companyAddress: {
                    'street': _street.text.trim(),
                    'buildingNr': _buildingNr.text.trim(),
                    'flatNr': _flatNr.text.trim(),
                    'city': _city.text.trim(),
                    'postCode': _postCode.text.trim(),
                  },
                ));
              } else {
                context.read<MyProfilPageBloc>().add(UpdateUserDataEvent(
                  firstName: _firstName.text.trim(),
                  lastName: _lastName.text.trim(),
                  phone: _phone.text.trim(),
                  bio: _bio.text.trim(),
                ));
              }
            },
          ),

          const SizedBox(height: 40),
          WButton(
            text: 'Wyloguj',
            onPressed: () => context.read<MainScreenBloc>().add(LogoutEvent()),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TAB 2 — MOJE ZGŁOSZENIA
// ──────────────────────────────────────────────────────────────────────────────
class _TabZgloszenia extends StatelessWidget {
  final MyProfilPageMainState state;

  const _TabZgloszenia({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.requests.isEmpty) {
      return const Center(
        child: Text('Nie masz żadnych zgłoszeń',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: state.requests.length,
      itemBuilder: (context, index) {
        final req = state.requests[index];
        return _RequestTile(req: req);
      },
    );
  }
}

class _RequestTile extends StatefulWidget {
  final Request req;
  const _RequestTile({required this.req});

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _editing = false;
  late final TextEditingController _desc;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: widget.req.description);
  }

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Miniatura
                if (widget.req.thumbUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: widget.req.thumbUrl,
                      width: 60, height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 12),
                // Dane
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.req.category,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.req.sector,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (widget.req.city.isNotEmpty)
                        Text(widget.req.city,
                            style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                // Akcje
                Column(
                  children: [
                    IconButton(
                      icon: Icon(_editing ? Icons.close : Icons.edit_outlined,
                          size: 20),
                      onPressed: () => setState(() => _editing = !_editing),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      onPressed: () => context
                          .read<MyProfilPageBloc>()
                          .add(TryDeleteMyRequestProfilPageEvent(id: widget.req.id)),
                    ),
                  ],
                ),
              ],
            ),

            // Edycja opisu
            if (_editing) ...[
              const SizedBox(height: 12),
              WInputField(
                controller: _desc,
                label: 'Opis zgłoszenia',
                isPassword: false,
                hintText: 'Wpisz opis',
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: WButton(
                  text: 'Zapisz',
                  onPressed: () {
                    context.read<MyProfilPageBloc>().add(
                      UpdateRequestDescriptionEvent(
                        id: widget.req.id,
                        newDescription: _desc.text.trim(),
                      ),
                    );
                    setState(() => _editing = false);
                  },
                ),
              ),
            ] else ...[
              if (widget.req.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(widget.req.description,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
            RequestOffersBar(request: widget.req),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TAB 3 — MOJE RECENZJE
// ──────────────────────────────────────────────────────────────────────────────
class _TabRecenzje extends StatelessWidget {
  final MyProfilPageMainState state;

  const _TabRecenzje({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.reviews.isEmpty) {
      return const Center(
        child: Text('Nie wystawiłeś jeszcze żadnych recenzji',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: state.reviews.length,
      itemBuilder: (context, index) {
        final rev = state.reviews[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                    (i) => Icon(
                  i < rev.score ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                ),
              ),
            ),
            title: Text(rev.description,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: rev.timestamp != null
                ? Text(
                '${rev.timestamp!.day}.${rev.timestamp!.month}.${rev.timestamp!.year}',
                style: const TextStyle(fontSize: 11))
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.red),
              onPressed: () => context
                  .read<MyProfilPageBloc>()
                  .add(TryDeleteMyReviewProfilPageEvent(id: rev.id)),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TAB 4 — MOJE PREZENTACJE (tylko firma)
// ──────────────────────────────────────────────────────────────────────────────
class _TabPrezentacje extends StatelessWidget {
  final MyProfilPageMainState state;

  const _TabPrezentacje({required this.state});

  @override
  Widget build(BuildContext context) {
    final addButton = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: WButton(
        text: 'Dodaj prezentację',
        onPressed: () => context.read<MainScreenBloc>().add(GoToDodajEvent()),
      ),
    );

    if (state.videos.isEmpty) {
      return Column(
        children: [
          addButton,
          const Expanded(
            child: EmptyState(
              icon: Icons.videocam_outlined,
              title: 'Brak prezentacji',
              subtitle:
                  'Dodaj film pokazujący Twoją firmę — klienci znajdą Cię w wyszukiwarce.',
            ),
          ),
        ],
      );
    }

    return Column(children: [
      addButton,
      Expanded(
        child: GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: state.videos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 9 / 16,
      ),
      itemBuilder: (context, index) {
        final video = state.videos[index];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: video.thumbUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => context
                      .read<MyProfilPageBloc>()
                      .add(TryDeleteMyPromoProfilPageEvent(id: video.id)),
                ),
              ),
            ),
          ],
        );
      },
        ),
      ),
    ]);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// TAB 5 — KOSZ (tylko firma)
// Zgłoszenia ukryte przez firmę — można przywrócić lub trwale usunąć z widoku
// WAŻNE: ukrycie nie usuwa zgłoszenia — inne firmy nadal je widzą
// ──────────────────────────────────────────────────────────────────────────────
class _TabKosz extends StatelessWidget {
  final MyProfilPageMainState state;
  const _TabKosz({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.trashedRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Kosz jest pusty',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              'Ukryte zgłoszenia trafiają tutaj.\nMożesz je przywrócić lub usunąć z kosza.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: state.trashedRequests.length,
      itemBuilder: (context, index) {
        final req = state.trashedRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Miniatura
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: req.thumbUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: req.thumbUrl,
                    width: 64, height: 100, fit: BoxFit.cover,
                  )
                      : Container(
                    width: 64, height: 100,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
                const SizedBox(width: 12),

                // Dane
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req.category,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(req.sector,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      if (req.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(req.description,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),

                      // Akcje
                      Row(
                        children: [
                          // Przywróć
                          OutlinedButton.icon(
                            onPressed: () => context.read<MyProfilPageBloc>()
                                .add(TryRestoreFromTrashEvent(req.id)),
                            icon: const Icon(Icons.restore, size: 14),
                            label: const Text('Przywróć', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Usuń z kosza
                          OutlinedButton.icon(
                            onPressed: () => context.read<MyProfilPageBloc>()
                                .add(TryDeleteFromTrashEvent(req.id)),
                            icon: const Icon(Icons.delete_forever_outlined, size: 14, color: Colors.red),
                            label: const Text('Usuń z kosza',
                                style: TextStyle(fontSize: 12, color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}