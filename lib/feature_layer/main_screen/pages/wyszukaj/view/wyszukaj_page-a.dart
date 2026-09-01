import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:nominatim_flutter/model/request/search_request.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';
import 'package:qb/data_layer/data_models/request/create_team.dart';
import 'package:qb/data_layer/data_models/request/edit_team.dart';
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

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../bloc/main_bloc.dart';
import '../../dodaj/bloc/dodaj_page_bloc.dart';
import '../../dodaj/view/dodaj_page.dart';
import '../bloc/wyszukaj_page_bloc.dart';

class WyszukajPage extends StatelessWidget {
  const WyszukajPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WyszukajPageBloc(firebase: context.read<FirebaseService>(), user:context.read<MainScreenBloc>().state.user!),
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

        return SafeArea(child:

        _buildVideoFeed(state.videos),


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

        Positioned(
          right: 12,
          top: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(widget.promoItem.distance!/1000).toStringAsFixed(1)} km',

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 5,
                          color: Colors.black, // delikatny cień
                        ),
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 15,
                          color: Colors.black, // delikatny cień
                        ),
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 13,
                          color: Colors.black, // delikatny cień
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              )
            ],
          ),
        ),
        Positioned(
          left: 12,
          top: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.index+1} / ${widget.lenght}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 5,
                          color: Colors.black, // delikatny cień
                        ),
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 15,
                          color: Colors.black, // delikatny cień
                        ),
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 13,
                          color: Colors.black, // delikatny cień
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              )
            ],
          ),
        ),

        Positioned(
          right: 12,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton( color: Colors.white, onPressed: () { context.read<MainScreenBloc>().add(GoToChatEvent(widget.promoItem.userId)); }, icon: Icon(Icons.message),),
                  //Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),

                  const SizedBox(height: 16),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }






}
