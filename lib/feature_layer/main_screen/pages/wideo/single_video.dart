import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import 'bloc/single_video_page_bloc.dart';

class SingleVideoPage extends StatelessWidget {
  final Promo promo;
  const SingleVideoPage({super.key, required this.promo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SingleVideoPageBloc(
        firebase: context.read<FirebaseService>(),
        promo: promo,
        userId: context.read<MainScreenBloc>().state.user!.id,
      ),
      child: View(promo: promo),
    );
  }
}

class View extends StatefulWidget {
  final Promo promo;
  const View({super.key, required this.promo});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {
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
    return BlocConsumer<SingleVideoPageBloc, SingleVideoPageState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is! SingleVideoPageMainState || !_controller.value.isInitialized) {
          return const Loading(noText: true, key: ValueKey('loading_video'));
        }

        final author = state.author;
        final reviewCount = state.reviews.length;
        final rating = state.averageRating;

        return Container(
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // ── Film ─────────────────────────────────────────
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),

              // ── Ikony akcji po prawej ─────────────────────────
              Positioned(
                right: 8,
                bottom: 140,
                child: Column(
                  children: [
                    // Ulubione
                    _ActionIcon(
                      icon: Icons.favorite_outline,
                      tooltip: 'Ulubione',
                      onTap: () {
                        context.read<SingleVideoPageBloc>().add(
                          ToggleFavoriteVideoEvent(
                            promoId: widget.promo.id,
                            isFavorite: false,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Dodaj do kontaktów
                    _ActionIcon(
                      icon: Icons.person_add_outlined,
                      tooltip: 'Dodaj do kontaktów',
                      onTap: () async {
                        final firebase = context.read<FirebaseService>();
                        final myUid = context.read<MainScreenBloc>().state.user?.id ?? '';
                        await firebase.addContact(
                          myUserId: myUid,
                          contactUserId: widget.promo.userId,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dodano do kontaktów')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // ── Pasek firmy na dole (identyczny jak w wyszukaj) ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => context.read<MainScreenBloc>()
                      .add(GoToProfilPublicznyFirmyEvent(author.id)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                    ),
                    child: Row(
                      children: [
                        // Awatar
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          child: Text(
                            author.companyName?.isNotEmpty == true
                                ? author.companyName![0].toUpperCase()
                                : 'F',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
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
                                author.companyName ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              if (reviewCount > 0)
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                          (i) => Icon(
                                        i < rating ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '($reviewCount)',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                )
                              else
                                const Text('Brak opinii',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),

                        const Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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