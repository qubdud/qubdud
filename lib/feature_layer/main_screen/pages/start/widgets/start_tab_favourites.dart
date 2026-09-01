import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../shared/widgets/w_small_label.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/start_page_bloc.dart';
import '../components/user2_info/view/user_info_component.dart';




class StartTabFavourites extends StatelessWidget {
  final StartPageState state;

  const StartTabFavourites({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.favVideo.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WSmallLabel(text: 'Brak ulubionych'),
            const Text('Oznacz swoje ulubione firmy!'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Dwie kolumny
        childAspectRatio: 0.7, // Proporcje pionowe (jak w TikTok/Reels)
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: state.favVideo.length,
      itemBuilder: (context, index) {
        final videofav = state.favVideo[index];

        return GestureDetector(
          onTap: (){context.read<MainScreenBloc>().add(GoToPromoFirmyEvent(videofav, playlist: state.favVideo, initialIndex: index));},
          child: Stack(
            children: [
              // 1. Miniaturka jako tło
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: videofav.thumbUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 2. Inicjały Firmy (Górny lewy róg)
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(


                    onTap: (){context.read<MainScreenBloc>().add(GoToProfilPublicznyFirmyEvent(videofav.userId));},

                    child: UserInfoComponent(id: videofav.userId, simpleMode: true)),
              ),

              // 3. Przycisk usuwania (Górny prawy róg)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.white, size: 24),
                  onPressed: () {
                    context.read<StartPageBloc>().add(
                      TryRemoveFavStartPageEvent(videofav.id),
                    );
                  },
                ),
              ),

              // 4. Dolny gradient dla czytelności (opcjonalnie)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
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

























class StartTabFavourites3 extends StatelessWidget {
  final StartPageState state;

  const StartTabFavourites3({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.favVideo.isEmpty) {
      return Column(
        children: [
          SizedBox(height: 32),
          WSmallLabel(text: 'Brak ulubionych'),
          Text(
            'Oznacz swoje ulubione firmy, aby mieć je zawsze pod ręką!',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: state.favVideo.length,
      itemBuilder: (context, index) {
        final videofav = state.favVideo[index];

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
                child: SizedBox(
                  height: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
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
                              icon: const Icon(Icons.message_outlined,
                                  color: Colors.white, size: 18),
                              onPressed: () {
                                context.read<MainScreenBloc>().add(
                                  GoToChatEvent(videofav.userId, chatName: videofav.companyName),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.white, size: 18),
                              onPressed: () {
                                context.read<StartPageBloc>().add(
                                  TryRemoveFavStartPageEvent(videofav.id),
                                );
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
}
