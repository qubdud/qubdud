import 'package:qb/shared/widgets/empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qb/shared/widgets/promo_tile.dart';
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
      return const EmptyState(
        icon: Icons.favorite_outline,
        title: 'Brak ulubionych',
        subtitle: 'Oznacz serduszkiem filmy firm, aby mieć je pod ręką.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: state.favVideo.length,
      itemBuilder: (context, index) {
        final promo = state.favVideo[index];
        return PromoTile(
          promo: promo,
          onTap: () => context.read<MainScreenBloc>().add(GoToPromoFirmyEvent(
              promo,
              playlist: state.favVideo,
              initialIndex: index)),
          cornerAction: GestureDetector(
            onTap: () => context
                .read<StartPageBloc>()
                .add(TryRemoveFavStartPageEvent(promo.id)),
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.black45,
              child: Icon(Icons.favorite, color: Colors.redAccent, size: 16),
            ),
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
