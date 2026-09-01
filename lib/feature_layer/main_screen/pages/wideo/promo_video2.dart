import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../bloc/main_bloc.dart';
import '../start/components/rewiev_info/view/rev_info_component.dart';
import '../start/components/user2_info/view/user_info_component.dart';

class SingleVideoPage2 extends StatefulWidget {
  final Promo promo;

  const SingleVideoPage2({super.key, required this.promo});

  @override
  State<SingleVideoPage2> createState() => _SingleVideoPageState();
}

class _SingleVideoPageState extends State<SingleVideoPage2> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.promo.fileUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
          _controller.setLooping(true);
        }
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
      return Container(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Container(
      color: Colors.black,
      // Zajmujemy dokładnie tyle miejsca, ile daje nam MainView
      width: double.infinity,
      height: double.infinity,
      child: ClipRect( // <--- TO NAPRAWIA PROBLEM: Odcina wideo, żeby nie wyszło na menu
        child: Stack(
          children: [
            // 1. WIDEO TYPU COVER
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover, // Rozciąga wideo, aby wypełniło cały dostępny prostokąt
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),

            // 2. GRADIENT DLA CZYTELNOŚCI
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
            ),

            // 3. PRZYCISK POWROTU
            Positioned(
              top: 10,
              left: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.read<MainScreenBloc>().add(GoToHomeEvent()),
                ),
              ),
            ),

            // 4. PANEL INFO
            Positioned(
              right: 12,
              bottom: 20,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    text: 'Napisz',
                    icon: Icons.message,
                    onTap: () => context.read<MainScreenBloc>().add(GoToChatEvent(widget.promo.userId)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    height: 50,
                    child: RevInfoComponent(selectedPromo: widget.promo),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: UserInfoComponent(id: widget.promo.userId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required String text, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white, size: 28, shadows: const [Shadow(blurRadius: 10, color: Colors.black)]),
        ],
      ),
    );
  }
}