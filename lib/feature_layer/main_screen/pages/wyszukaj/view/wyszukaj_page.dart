import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:nominatim_flutter/model/request/search_request.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_dropdown.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:qb/shared/widgets/w_label.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';

import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../bloc/main_bloc.dart';
import '../../dodaj/bloc/dodaj_page_bloc.dart';
import '../../dodaj/view/dodaj_page.dart';
import '../../start/bloc/start_page_bloc.dart';
import '../../start/components/rewiev_info/view/rev_info_component.dart';
import '../../start/components/user2_info/view/user_info_component.dart';
import '../bloc/wyszukaj_page_bloc.dart';

class WyszukajPage extends StatelessWidget {
  const WyszukajPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mainState = context.read<MainScreenBloc>().state;
    final autoState = mainState is WyszukajFirmyMainScreenState ? mainState : null;

    return BlocProvider(
      create: (_) {
        final bloc = WyszukajPageBloc(
          firebase: context.read<FirebaseService>(),
          user: context.read<MainScreenBloc>().state.user!,
        );
        // Jeśli przyszły parametry z historii — od razu wyszukaj
        if (autoState?.autoCategory != null &&
            autoState?.autoSector != null &&
            autoState?.autoLat != null &&
            autoState?.autoLng != null) {
          bloc.add(TryWyszukajPageEvent(
            category: autoState!.autoCategory!,
            sector: autoState.autoSector!,
            location: LatLng(autoState.autoLat!, autoState.autoLng!),
          ));
        }
        return bloc;
      },





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
  bool _showMap = false;
  final MapController mapController = MapController();


  final Map<String, List<String>> categoryToBranza = categories;




  @override
  Widget build(BuildContext context) {



    return BlocConsumer<WyszukajPageBloc, WyszukajPageState>(
        listener: (context, state) {
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
        });
  }


  Widget _buildWidgetBasedOnState(WyszukajPageState state, BuildContext context) {
    if (state is WyszukajPageLoadingState) {
      return const Loading(key: ValueKey('Loading'));
    } else if (state is WyszukajPageMainState) {

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
              WSmallLabel(text: 'Wyszukaj firmę / usługę'),


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

              WButton(
                isEnabled: !isSearching,
                text: 'Wyszukaj',
                onPressed: ()  {
                  context.read<WyszukajPageBloc>().add(TryWyszukajPageEvent(sector: selectedBranza!, category: selectedCategory!, location: selectedLocation!));
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      );
    }
    else if (state is WyszukajPageResultsState) {

      return SafeArea(
        child: Stack(
          children: [
            _showMap
                ? _buildResultsMap(state.videos)
                : _buildVideoFeed(state.videos),
            Positioned(
              top: 12,
              right: 12,
              child: FloatingActionButton.small(
                heroTag: 'wyszukajMapToggle',
                backgroundColor: Colors.white,
                onPressed: () => setState(() => _showMap = !_showMap),
                child: Icon(
                  _showMap ? Icons.play_circle_outline : Icons.map_outlined,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }



    else {
      return SizedBox();
    }

  }


  Widget _buildVideoFeed(List<Promo> videos) {


    if (videos.isEmpty) {
      return const Center(child: Text('Brak dostępnych filmów'));
    }

    return PageView.builder(
      key: const ValueKey('VideoFeed'),
      scrollDirection: Axis.vertical,
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoPlayerItem(promoItem: videos[index],lenght: videos.length,index: index,);
      },
    );
  }

  Widget _buildResultsMap(List<Promo> videos) {
    if (videos.isEmpty) {
      return const Center(child: Text('Brak wyników'));
    }
    final center = selectedLocation ?? videos.first.location;

    return FlutterMap(
      key: const ValueKey('ResultsMap'),
      options: MapOptions(initialCenter: center, initialZoom: 9),
      children: [
        openStreetMap,
        MarkerLayer(
          markers: videos.asMap().entries.map((e) {
            return Marker(
              point: e.value.location,
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () => _showPromoSheet(e.value, videos, e.key),
                child: const Icon(Icons.location_pin,
                    color: cDarkBlue, size: 40),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showPromoSheet(Promo promo, List<Promo> all, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: promo.thumbUrl.isNotEmpty
                  ? Image.network(promo.thumbUrl,
                      width: 80, height: 120, fit: BoxFit.cover)
                  : Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.business_outlined),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(promo.companyName.isNotEmpty ? promo.companyName : 'Firma',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('${promo.category} · ${promo.sector}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2),
                  if (promo.distance != null)
                    Text('${(promo.distance! / 1000).toStringAsFixed(1)} km',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Oglądaj'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<MainScreenBloc>().add(
                              GoToPromoFirmyEvent(promo,
                                  playlist: all, initialIndex: index));
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<MainScreenBloc>().add(
                              GoToProfilPublicznyFirmyEvent(promo.userId));
                        },
                        child: const Text('Profil'),
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
  }
}


class VideoPlayerItem extends StatefulWidget {
  final Promo promoItem;
  final int lenght;
  final int index;
  const VideoPlayerItem({super.key, required this.promoItem, required this.lenght, required this.index});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.promoItem.fileUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return VideoFeedPage(promo: widget.promoItem, controller: _controller, actual: widget.index,all: widget.lenght);
  }






}


void _showAnonimSnackbar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Zaloguj się aby korzystać z tej funkcji'),
      duration: Duration(seconds: 2),
    ),
  );
}

const _textShadow = [
  Shadow(offset: Offset(0, 0), blurRadius: 5, color: Colors.black),
  Shadow(offset: Offset(0, 0), blurRadius: 15, color: Colors.black),
];

class VideoFeedPage extends StatelessWidget {
  final int all;
  final int actual;
  final Promo promo;
  final VideoPlayerController controller;

  const VideoFeedPage({
    super.key,
    required this.promo,
    required this.controller,
    required this.all,
    required this.actual,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Film ──────────────────────────────────────────────
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),

        // ── Licznik i dystans ─────────────────────────────────
        Positioned(
          left: 12,
          top: 10,
          child: Text(
            '${actual + 1} / $all',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold,
                color: Colors.white, shadows: _textShadow),
          ),
        ),
        Positioned(
          right: 12,
          top: 10,
          child: Text(
            '${(promo.distance! / 1000).toStringAsFixed(1)} km',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold,
                color: Colors.white, shadows: _textShadow),
          ),
        ),

        // ── Ikony akcji po prawej ─────────────────────────────
        Positioned(
          right: 8,
          bottom: 120,
          child: Column(
            children: [
              // Ulubione
              _ActionIcon(
                icon: Icons.favorite_outline,
                tooltip: 'Ulubione',
                onTap: () {
                  if (Globals.instance.anonim) {
                    _showAnonimSnackbar(context);
                    return;
                  }
                  context.read<WyszukajPageBloc>()
                      .add(TryAddFavWyszukajPageEvent(promo.id));
                },
              ),
              const SizedBox(height: 16),
              // Dodaj do kontaktów
              _ActionIcon(
                icon: Icons.person_add_outlined,
                tooltip: 'Dodaj do kontaktów',
                onTap: () {
                  if (Globals.instance.anonim) {
                    _showAnonimSnackbar(context);
                    return;
                  }
                  context.read<WyszukajPageBloc>()
                      .add(TryAddContactEvent(promo.userId));
                },
              ),
            ],
          ),
        ),

        // ── Pasek firmy na dole ───────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _CompanyBar(promo: promo),
        ),
      ],
    );
  }
}

// ── Ikona akcji ───────────────────────────────────────────────────────────────
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

// ── Pasek firmy ───────────────────────────────────────────────────────────────
class _CompanyBar extends StatefulWidget {
  final Promo promo;
  const _CompanyBar({required this.promo});

  @override
  State<_CompanyBar> createState() => _CompanyBarState();
}

class _CompanyBarState extends State<_CompanyBar> {
  double _avgScore = 0;
  int _reviewCount = 0;
  String _companyName = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final firebase = context.read<FirebaseService>();
      // Nazwa firmy
      final user = await firebase.fetchUser(widget.promo.userId);
      final reviews = await firebase.getReviewsMetadataByReviewedUser(widget.promo.userId);
      double avg = 0;
      if (reviews.isNotEmpty) {
        avg = reviews.map((r) => r.score).reduce((a, b) => a + b) / reviews.length;
      }
      if (mounted) {
        setState(() {
          _companyName = user?.companyName ?? widget.promo.userId;
          _avgScore = avg;
          _reviewCount = reviews.length;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Kliknięcie → publiczny profil firmy
        context.read<MainScreenBloc>()
            .add(GoToProfilPublicznyFirmyEvent(widget.promo.userId));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
        ),
        child: Row(
          children: [
            // Awatar
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white24,
              child: Text(
                _companyName.isNotEmpty ? _companyName[0].toUpperCase() : 'F',
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),

            // Nazwa + gwiazdki
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _loaded ? _companyName : '...',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (_loaded && _reviewCount > 0)
                    Row(
                      children: [
                        ...List.generate(
                          5,
                              (i) => Icon(
                            i < _avgScore.round() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${_reviewCount})',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    )
                  else if (_loaded)
                    const Text(
                      'Brak opinii',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                ],
              ),
            ),

            // Strzałka → profil
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}