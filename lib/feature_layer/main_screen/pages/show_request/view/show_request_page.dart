import 'dart:async';
import 'dart:math' show min;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:qb/domain_layer/firebase_service.dart';

import 'package:qb/shared/constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../../../shared/widgets/loading.dart';
import '../../../../../shared/client_notes.dart';
import '../../../../../shared/functions/effective_role.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/request_take_status.dart';
import '../../../../../shared/widgets/w_small_label.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/show_request_page_bloc.dart';
import '../widgets/realization_section.dart';
import '../../../../../shared/widgets/load_error.dart';
import '../../dodaj/view/dodaj_page.dart' show osmAttribution;
import '../../../../../shared/request_questions.dart';

class ShowRequestPage extends StatelessWidget {
  const ShowRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ShowRequestPageBloc(firebase: context.read<FirebaseService>()),
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
  Future<void> _dial(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nie można otworzyć dialera')));
      }
    }
  }


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
        .read<ShowRequestPageBloc>()
        .state;
    if (state is ShowRequestPageMainState) {}
  }

  Widget build(BuildContext context) {


    return BlocConsumer<ShowRequestPageBloc, ShowRequestPageState>(
      listener: (context, state) {
        if (state is ShowRequestPageNextState) {
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


  Widget _buildWidgetBasedOnState(ShowRequestPageState state,
      BuildContext context) {

    if (state is ShowRequestPageLoadingState) {
      return const Loading(key: ValueKey('Loading'));
    } else if (state is ShowRequestPageErrorState) {
      return LoadError(
        key: const ValueKey('Error'),
        message: 'Nie udało się wczytać zgłoszenia.',
        onRetry: () =>
            context.read<ShowRequestPageBloc>().add(TryShowRequestPageEvent()),
      );
    } else {


      final meId = FirebaseAuth.instance.currentUser?.uid;
      final author = state.appUser;
      final req = Globals.instance.selectedRequest!;
      final insider = meId != null && (meId == req.userId || meId == req.takenBy);
      // bez private/location (zgłoszenie sprzed migracji, offline) klient i realizujący widzą location
      final exact = state.exactLocation ?? (insider ? req.location : null);
      final authorName = author == null
          ? 'Konto usunięte'
          : '${author.firstName ?? ''} ${author.lastName ?? ''}'.trim();
      final email = author?.email ?? '';
      final phone = author?.phone ?? '';
      final screen = MediaQuery.of(context).size;
      // tablet / poziomo: kwadrat do 45% wysokości ekranu, telefon jak dotąd
      final wide = screen.width >= 600;
      final mediaSide = wide
          ? min(min(screen.width, maxColumnSize) - 32, screen.height * 0.45)
          : screen.width - 32;


      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
          WSmallLabel(text: 'Widok zgłoszenia'),
          if (Globals.instance.selectedRequest!.mediaType == 'image' &&
              Globals.instance.selectedRequest!.fileUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _openImageFullscreen(
                  context, Globals.instance.selectedRequest!.fileUrl),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: mediaSide,
                      width: wide ? mediaSide : double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: Globals.instance.selectedRequest!.fileUrl,
                        fit: BoxFit.cover,
                        // np. HEIC bez dekodera — pokazujemy miniaturę JPG
                        errorWidget: (_, __, ___) => CachedNetworkImage(
                          imageUrl: Globals.instance.selectedRequest!.thumbUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 10,
                    bottom: 10,
                    child: _ZoomHint(icon: Icons.zoom_out_map),
                  ),
                ],
              ),
            ),

              if (Globals.instance.selectedRequest!.mediaType == 'video' &&
                  Globals.instance.selectedRequest!.fileUrl.isNotEmpty)
                GestureDetector(
                  onTap: () => _openVideoFullscreen(
                      context, Globals.instance.selectedRequest!.fileUrl),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: mediaSide,
                          width: wide ? mediaSide : double.infinity,
                          child: VideoPlayerItem(
                              videoUrl:
                                  Globals.instance.selectedRequest!.fileUrl),
                        ),
                      ),
                      const Positioned(
                        right: 10,
                        bottom: 10,
                        child: _ZoomHint(icon: Icons.fullscreen),
                      ),
                    ],
                  ),
                ),


                //VideoPlayerItem(videoUrl: Globals.instance.selectedRequest!.fileUrl),

              SizedBox(height: 24,),
              WSmallLabel(text: 'Opis zgłoszenia'),
              Text(Globals.instance.selectedRequest!.description),
              if (Globals.instance.selectedRequest!.timing.isNotEmpty ||
                  Globals.instance.selectedRequest!.budget != null ||
                  Globals.instance.selectedRequest!.answers.isNotEmpty) ...[
                const SizedBox(height: 16),
                WSmallLabel(text: 'Szczegóły'),
                if (kRequestTiming[Globals.instance.selectedRequest!.timing] != null)
                  Text('Kiedy: ${kRequestTiming[Globals.instance.selectedRequest!.timing]}'),
                if (Globals.instance.selectedRequest!.budget != null)
                  Text('Budżet: do ${Globals.instance.selectedRequest!.budget} zł'),
                for (final e in Globals.instance.selectedRequest!.answers.entries)
                  Text('${e.key}: ${e.value}'),
              ],

              SizedBox(height: 24,),
              WSmallLabel(text: 'Lokalizacja zgłoszenia'),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text((Globals.instance.selectedRequest!.city).isEmpty?'Nieznane':(Globals.instance.selectedRequest!.city), style: TextStyle(fontWeight: FontWeight.bold),),
                  if(Globals.instance.selectedRequest!.distance!=null)
                  Text((Globals.instance.selectedRequest!.distance!/1000).toInt().toString()+'km'),
                ],
              ),



              SizedBox(
                height: 200,
                child: FlutterMap(
                    // dokładne miejsce dochodzi na żywo po przyjęciu oferty — mapa centruje się od nowa
                    key: ValueKey(exact),
                    options: MapOptions(
                      initialCenter: exact ?? Globals.instance.selectedRequest!.location,
                      initialZoom: exact != null ? 14 : 13,
                      onTap: (tapPos, point) {
                        setState(() {
                          selectedLocation = point;
                        });
                      },

                    ),
                    children: [openStreetMap, osmAttribution,
                      if (exact != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: exact,
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        )
                      else
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: Globals.instance.selectedRequest!.location,
                              radius: 800,
                              useRadiusInMeter: true,
                              color: Colors.red.withValues(alpha: 0.15),
                              borderColor: Colors.red,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                    ]),),
              if (exact == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Przybliżona okolica (ok. 1 km). Dokładne miejsce zobaczysz po przyjęciu Twojej oferty.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),


              SizedBox(height: 24,),
              WSmallLabel(text: 'Dane zgłaszającego'),
              Column(children: [

                Text(
                  'Imię'.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(authorName),
                    if (author != null &&
                        isCompanyMode(
                            context.read<MainScreenBloc>().state.user))
                      IconButton(
                        icon: Icon(
                            ClientNotes.get(
                                        Globals.instance.selectedRequest!.userId)
                                    .isEmpty
                                ? Icons.sticky_note_2_outlined
                                : Icons.sticky_note_2,
                            size: 20,
                            color: ClientNotes.get(Globals
                                        .instance.selectedRequest!.userId)
                                    .isEmpty
                                ? Colors.grey
                                : const Color(0xFFB8901B)),
                        tooltip: 'Notatka',
                        onPressed: () async {
                          final changed = await showClientNoteDialog(
                              context,
                              Globals.instance.selectedRequest!.userId,
                              authorName);
                          if (changed) setState(() {});
                        },
                      ),
                  ],
                ),
                ClientNoteBadge(
                    userId: Globals.instance.selectedRequest!.userId,
                    maxLines: 3),
                SizedBox(height: 24,),

                if (email.isNotEmpty) ...[
                  Text(
                    'e-mail'.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(email),
                  SizedBox(height: 24,),
                ],

                Text(
                  'telefon'.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (phone.isNotEmpty)
                  GestureDetector(
                    onTap: () => _dial(phone),
                    child: Text(phone,
                        style: const TextStyle(
                            color: cDarkBlue,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline)),
                  )
                else
                  Text(author != null && author.firma != true &&
                          meId != Globals.instance.selectedRequest!.userId
                      ? 'Zobaczysz go, gdy klient przyjmie Twoją ofertę albo zarezerwuje termin'
                      : 'brak',
                      textAlign: TextAlign.center),

                SizedBox(height: 24,),


                if (author != null &&
                    meId != Globals.instance.selectedRequest!.userId)
                Row(children: [
                  Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.message_outlined, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      context.read<MainScreenBloc>().add(GoToChatEvent(Globals.instance.selectedRequest!.userId));
                    },
                  ),
                ),
                  SizedBox(width: 16,),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed:
                          phone.isNotEmpty ? () => _dial(phone) : null,
                    ),
                  ),




                ],)

              ]),


              SizedBox(height: 24,),

              // ── Podjęcie zadania (tylko firma, nie swoje zgłoszenie) ──
              Builder(builder: (context) {
                final me = context.read<MainScreenBloc>().state.user;
                final req = Globals.instance.selectedRequest!;
                if (me == null || !isCompanyMode(me) || me.id == req.userId) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: CompanyOfferSection(
                    request: req,
                    myCompanyId: me.id,
                    myCompanyName: me.companyName ?? 'Firma',
                  ),
                );
              }),

              RealizationSection(request: Globals.instance.selectedRequest!),

            ],
          ),
        ),
      );
    }
  }
}

/// Pełny ekran zdjęcia: zoom palcami, tap w tło zamyka.
void _openImageFullscreen(BuildContext context, String url) {
  showDialog(
    context: context,
    barrierColor: Colors.black,
    builder: (ctx) => Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(ctx).padding.top + 8,
          right: 12,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
      ],
    ),
  );
}

/// Pełny ekran wideo z dźwiękiem i pauzą.
void _openVideoFullscreen(BuildContext context, String url) {
  showDialog(
    context: context,
    barrierColor: Colors.black,
    builder: (ctx) => Stack(
      children: [
        Positioned.fill(
          child: VideoPlayerItem(videoUrl: url, contain: true, controls: true),
        ),
        Positioned(
          top: MediaQuery.of(ctx).padding.top + 8,
          right: 12,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
      ],
    ),
  );
}

class _ZoomHint extends StatelessWidget {
  final IconData icon;
  const _ZoomHint({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
          color: Colors.black54, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  /// contain = całe wideo widoczne (pełny ekran); false = wypełnia kafelek.
  final bool contain;

  /// controls = tap pauzuje/wznawia, dźwięk włączony.
  final bool controls;

  const VideoPlayerItem(
      {super.key,
      required this.videoUrl,
      this.contain = false,
      this.controls = false});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      // podgląd bez dźwięku — inaczej gra równolegle z pełnym ekranem
      if (!widget.controls) _controller.setVolume(0);
      _controller.play();
      _controller.setLooping(true);
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const VideoError();
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: widget.controls
          ? () => setState(() => _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play())
          : null,
      child: Stack(
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: widget.contain ? BoxFit.contain : BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          if (widget.controls && !_controller.value.isPlaying)
            const Center(
              child: Icon(Icons.play_circle_fill,
                  color: Colors.white70, size: 72),
            ),
        ],
      ),
    );
  }
}











TileLayer get openStreetMap =>
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.qb.zkv.pl.qb',
    );
