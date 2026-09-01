import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:qb/domain_layer/firebase_service.dart';

import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_dropdown.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';

import '../../../../../../shared/widgets/loading.dart';
import '../../../../../shared/functions/effective_role.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/request_take_status.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_small_label.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/show_request_page_bloc.dart';
import '../widgets/realization_section.dart';

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
    final isWideScreen = MediaQuery
        .of(context)
        .size
        .width > minWideScreen;

    if (state is ShowRequestPageLoadingState) {
      return const Loading(key: ValueKey('Loading'));
    } else if (state is! ShowRequestPageLoadingState) {


      final meId = FirebaseAuth.instance.currentUser?.uid;


      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
          WSmallLabel(text: 'Widok zgłoszenia'),
          if(Globals.instance.selectedRequest!.fileName.contains('.jpg'))
            Container(
              height: MediaQuery.of(context).size.width-32,

              child: SingleChildScrollView(
                child: CachedNetworkImage(
                  imageUrl: Globals.instance.selectedRequest!.fileUrl,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),

              if(Globals.instance.selectedRequest!.fileName.contains('.mp4'))

                Container(
                  height: MediaQuery.of(context).size.width-32,

                  child: VideoPlayerItem(videoUrl: Globals.instance.selectedRequest!.fileUrl),
                ),


                //VideoPlayerItem(videoUrl: Globals.instance.selectedRequest!.fileUrl),

              SizedBox(height: 24,),
              WSmallLabel(text: 'Opis zgłoszenia'),
              Text(Globals.instance.selectedRequest!.description),

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
                    options: MapOptions(
                      initialCenter: (Globals.instance.selectedRequest!.location),
                      initialZoom: 14,
                      onTap: (tapPos, point) {
                        setState(() {
                          selectedLocation = point;
                        });
                      },

                    ),
                    children: [openStreetMap,
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: (Globals.instance.selectedRequest!.location),
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
                Text(state.appUser!.firstName!),
                SizedBox(height: 24,),

                Text(
                  'e-mail'.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(state.appUser!.email!),
                SizedBox(height: 24,),

                Text(
                  'telefon'.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text('brak'),

                SizedBox(height: 24,),


                if(meId!=Globals.instance.selectedRequest!.userId)
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
                      onPressed: () {
                       // context.read<MainScreenBloc>().add(GoToChatEvent(video.userId));
                      },
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
    } else {
      return const Loading(key: ValueKey('Loading'));
    }
  }
}

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerItem({super.key, required this.videoUrl});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
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

  Widget _buildIconColumn(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton( color: Colors.white, onPressed: () { print('asdf'); }, icon: Icon(icon),),
        //Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),

        const SizedBox(height: 16),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Wideo wypełniające cały widget
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge, // ważne, żeby nie wychodził poza obszar
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),

      ],
    );
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