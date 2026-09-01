import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/globals.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/start_page_bloc.dart';
import '../components/rewiev_info/view/rev_info_component.dart';
import '../components/user2_info/view/user_info_component.dart';



class StartTabVideoFeed extends StatefulWidget {
  final List<Promo> videos;

  const StartTabVideoFeed({
    super.key,
    required this.videos,
  });

  @override
  State<StartTabVideoFeed> createState() => _StartTabVideoFeedState();
}

class _StartTabVideoFeedState extends State<StartTabVideoFeed> {
  VideoPlayerController? _controller;
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideo(0);
  }

  Future<void> _loadVideo(int index) async {
    _isLoading = true;
    setState(() {});


    if (_controller != null) {
      try {
        await _controller!.pause();
        await _controller!.seekTo(Duration.zero);
        await _controller!.dispose();
      } catch (_) {}
      _controller = null;
    }

    final promo = widget.videos[index];

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(promo.fileUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );

    await controller.initialize();
    if (!mounted) return;

    controller.play();

    controller.addListener(() async {
      final v = controller.value;
      if (!v.isInitialized) return;

      if (v.position >= v.duration && mounted) {
        // 🔁 restart playback BEZ narastania pamięci
        await controller.pause();
        await controller.seekTo(Duration.zero);
        await controller.play();
      }
    });

    _controller = controller;
    _currentIndex = index;
    _isLoading = false;

    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller?.pause();
    }
  }




  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      return const Center(child: Text('Brak dostępnych filmów'));
    }


    return PageView.builder(
      key: const ValueKey('VideoFeed'),
      scrollDirection: Axis.vertical,
      itemCount: widget.videos.length,
      itemBuilder: (context, index) {
        return VideoPlayerItem(key:ValueKey( widget.videos[index].id),promoItem: widget.videos[index],lenght: widget.videos.length,index: index,);
      },
    );



















    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: widget.videos.length,
      onPageChanged: (index) {
        _loadVideo(index);
      },
      itemBuilder: (context, index) {
        // ⛔️ TYLKO AKTUALNA STRONA RENDERUJE VIDEO
        if (index != _currentIndex) {
          return const SizedBox.expand();
        }

        if (_isLoading || _controller == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return VideoFeedPage(
          promo: widget.videos[index],
          controller: _controller!,
        );
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

    return VideoFeedPage(promo: widget.promoItem, controller: _controller);
  }
}













class VideoFeedPage extends StatelessWidget {
  final Promo promo;
  final VideoPlayerController controller;

  const VideoFeedPage({
    super.key,
    required this.promo,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    Globals.instance.selectedPromo = promo;
    return Stack(
      key:ValueKey(promo.id),


      children: [
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

        Positioned(
          right: 12,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Text('Napisz', style: TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.message, color: Colors.white),
                    onPressed: () {
                      context.read<MainScreenBloc>()
                          .add(GoToChatEvent(promo.userId));
                    },
                  ),
                ],
              ),

              Row(
                children: [
                  const Text(
                    'Dodaj do ulubionych',
                    style: TextStyle(color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    onPressed: () {
                      context.read<StartPageBloc>()
                          .add(TryAddFavStartPageEvent(promo.id));
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: 300,
                height: 50,
                child: RevInfoComponent(key:ValueKey(promo.id),selectedPromo: promo),
              ),

              Container(
                width: MediaQuery.of(context).size.width - 24,
                color: Colors.white70,
                child: UserInfoComponent(id: promo.userId),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
