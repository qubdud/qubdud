import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import 'package:qb/feature_layer/main_screen/pages/start/components/rewiev_info/view/rev_info_component.dart';
import 'package:qb/feature_layer/main_screen/pages/start/components/user2_info/view/user_info_component.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import 'package:video_player/video_player.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/constants.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_card.dart';
import '../bloc/start_page_bloc.dart';

class StartPage2 extends StatelessWidget {
  const StartPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StartPageBloc(
        firebase: context.read<FirebaseService>(),
        user: context.read<MainScreenBloc>().state.user!,
      ),
      child: const View(),
    );
  }
}

class View extends StatefulWidget {
  const View({super.key});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> with SingleTickerProviderStateMixin {
  bool isWideScreen = true;
  int stageNumber = 0;
  bool _isPlayingVideo = false;
  bool _isVideoTabActive = false;
  TabController? _tabController;
  PageController? _pageController;
  VideoPlayerController? _videoController;
  List<String> videoUrls = [];
  bool isLoadingVideos = true;
  int _currentVideoIndex = 0;
  @override
  void dispose() {
    _tabController?.dispose();
    _pageController?.dispose();
    _videoController?.dispose();
    super.dispose();


  }


  @override
  @override
  void initState() {
    super.initState();

    final user = context.read<MainScreenBloc>().state.user;
    final tabsLength = user!.firma! ? 3 : 2;

    _tabController = TabController(length: tabsLength, vsync: this);
    _pageController = PageController();

    // 🔥 ustaw startowy active tab
    _isVideoTabActive = _tabController!.index == 1;
  }




  void _stopAndDisposeVideo() {
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
      _videoController = null;
    }
    _currentVideoIndex = 0;
  }




  Future<void> _playVideo(Promo promo) async {
    await _videoController?.dispose();

    final controller = VideoPlayerController.network(promo.fileUrl);
    await controller.initialize();

    if (!mounted) return;

    controller
      ..setLooping(true)
      ..play();

    setState(() {
      _videoController = controller;
    });
  }








  @override
  Widget build(BuildContext context) {
    var sta = context.read<StartPageBloc>().state;

    var user = context.read<MainScreenBloc>().state.user;
    List<Tab> _tabs = [];

    if (user!.firma!) {
      _tabs = const [
        Tab(text: "Moi\nklienci"),
        //  Tab(text: 'Wyszukiwane'),
        Tab(text: "Odkrywaj"),
        Tab(text: "Ulubione"),
      ];
    } else {
      _tabs = const [
        Tab(text: 'Wyszukiwane'),
        Tab(text: "Okrywaj"),
        Tab(text: "Ulubione"),
      ];
    }



    return Column(
      children: [
        SafeArea(
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            controller: _tabController,
            tabs: _tabs,
            labelColor: Colors.black,
            onTap: (index) {
              _isVideoTabActive = index == 1;
              if (_isVideoTabActive) {
                final videos = context.read<StartPageBloc>().state.videos;
                if (videos.isNotEmpty) {
                  _currentVideoIndex = 0;
                  _playVideo(videos.first);
                }
              } else {
                _stopAndDisposeVideo();
              }

              setState(() {}); // rebuild tab content
            },



          ),
        ),
        Expanded(
          child: BlocConsumer<StartPageBloc, StartPageState>(
            listener: (context, state) {
              if (state is StartPageNextState) {
                context.read<MainScreenBloc>().add(InitEvent());
              }

              if (_isVideoTabActive &&
                  state.videos.isNotEmpty &&
                  _videoController == null) {
                _playVideo(state.videos.first);
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
                child: _buildTabbedContent(state),
              );
            },
          ),
        ),
      ],
    );
  }



  Widget _buildTabbedContent(StartPageState state) {
    if (state is StartPageLoadingState) {
      return Loading(noText: true, key: UniqueKey());
    }

    final currentIndex = _tabController!.index;


    if (currentIndex == 0) {
      return         SingleChildScrollView(
        child: Column(
          children: state.requests.asMap().entries.map((entry) {
            final video = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {

                      Globals.instance.selectedRequest = entry.value;
                      context.read<MainScreenBloc>().add(
                        GoToShowRequestEvent(),
                      );
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: video.thumbUrl,
                            width: 90,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),

                        if (video.is24)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.running_with_errors_outlined,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  SizedBox(
                    height: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(video.distance! / 1000).toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (video.description.isNotEmpty)
                          Text(
                            video.description,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                        Expanded(child: SizedBox()),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.message_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              context.read<MainScreenBloc>().add(
                                GoToChatEvent(video.userId),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    // Tab 1 – Wideo (pionowy scroll)
    if (currentIndex == 1) {
      if (state.videos.isEmpty) {
        return const Center(child: Text('Brak dostępnych filmów'));
      }

      return PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: state.videos.length,
        onPageChanged: (index) {
          _currentVideoIndex = index;
          _playVideo(state.videos[index]);
        },
        itemBuilder: (context, index) {
          return VideoPlayerItem(
            controller: index == _currentVideoIndex ? _videoController : null,
            promo: state.videos[index],
            isFav: false,
          );
        },
      );
    }


    if (currentIndex == 0) {
      return SingleChildScrollView(
        child: Column(
          children: state.requests.asMap().entries.map((entry) {
            final video = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {

                      Globals.instance.selectedRequest = entry.value;
                      context.read<MainScreenBloc>().add(
                        GoToShowRequestEvent(),
                      );
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: video.thumbUrl,
                            width: 90,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),

                        if (video.is24)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.running_with_errors_outlined,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  SizedBox(
                    height: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(video.distance! / 1000).toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (video.description.isNotEmpty)
                          Text(
                            video.description,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                        Expanded(child: SizedBox()),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.message_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              context.read<MainScreenBloc>().add(
                                GoToChatEvent(video.userId),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }


    if (currentIndex == 1) {
      if (state.videos.isEmpty) {
        return const Center(child: Text('Brak dostępnych filmów'));
      }


      return PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: state.videos.length,
        onPageChanged: (index) {
          _currentVideoIndex = index;
          _playVideo(state.videos[index]);
        },
        itemBuilder: (context, index) {
          return VideoPlayerItem(
            controller: index == _currentVideoIndex ? _videoController : null,
            promo: state.videos[index],
            isFav: false,
          );
        },
      );
    }



    if (currentIndex == 2) {
      if (state.favVideo.isEmpty) {
        return Column(
          children: [
            SizedBox(height: 32),
            WSmallLabel(text: 'Brak ulubionych'),
            Text(
              textAlign: TextAlign.center,
              'Oznacz swoje ulubione firmy, aby mieć je zawsze pod ręką!',
            ),
          ],
        );
      }

      return  ListView.builder(
        itemCount: state.favVideo.length,
        itemBuilder: (context, index) {
          final videofav = state.favVideo[index];


          print(videofav.userId);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: videofav.thumbUrl,
                    width: 90,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 160, // tutaj całkowita wysokość bloku
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          key: ValueKey(videofav.id),
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: UserInfoComponent(key:UniqueKey(),id: videofav.userId),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.message_outlined, color: Colors.white, size: 18),
                                onPressed: () {
                                  context.read<MainScreenBloc>().add(GoToChatEvent(videofav.userId));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 18),
                                onPressed: () {
                                  context.read<StartPageBloc>().add(TryRemoveFavStartPageEvent(videofav.id));
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

  return SizedBox.shrink();




  }








  Widget _buildVideoFeed(List<Promo> videos, bool isFav) {
    if (!_isVideoTabActive) {
      return const SizedBox.shrink();
    }

    if (videos.isEmpty) {
      return const Center(child: Text('Brak dostępnych filmów'));
    }



      return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: videos.length,
      onPageChanged: (index) {

        _currentVideoIndex = index;

        _playVideo(videos[index]);
      },

      itemBuilder: (context, index) {

        return VideoPlayerItem(
          controller:
          index == _currentVideoIndex ? _videoController : null,
          promo: videos[index],
          isFav: isFav,
        );
      },
    );
  }



}



class VideoPlayerItem extends StatelessWidget {
  final VideoPlayerController? controller;
  final Promo promo;
  final bool isFav;


  const VideoPlayerItem({
    super.key,
    required this.controller,
    required this.promo,
    required this.isFav,

  });

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    Globals.instance.selectedPromo = promo;
    return Stack(
      children: [
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller!.value.size.width,
              height: controller!.value.size.height,
              child: VideoPlayer(controller!),
            ),
          ),
        ),

        Positioned(
          right: 12,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Napisz',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),

                      IconButton(
                        color: Colors.white,
                        onPressed: () {
                          context.read<MainScreenBloc>().add(
                            GoToChatEvent(promo.userId),
                          );
                        },
                        icon: Icon(Icons.message),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [



                      Text(
                        isFav?'Usuń z ulubionych':
                        'Dodaj do ulubionych',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),

                      IconButton(
                        color: Colors.white,


                        onPressed: () {

                          if(isFav){

                            context.read<StartPageBloc>().add(TryRemoveFavStartPageEvent(promo.id));

                          }
                          else{

                            context.read<StartPageBloc>().add(TryAddFavStartPageEvent(promo.id));

                          }


                        },


                        icon: Icon(isFav?Icons.remove_circle_outline:Icons.favorite),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),



                  Center(
                    child: SizedBox(
                        width: 300,
                        height: 50,

                        child: RevInfoComponent(selectedPromo: promo)),
                  ),

                  Container(
                      width: MediaQuery.of(context).size.width-24,
                      color: Colors.black54,
                      child: 
                  
                  UserInfoComponent(id: promo.userId)
                  
                  
                  )

                ],
              ),

            ],
          ),
        ),
      ],
    );
  }
}







