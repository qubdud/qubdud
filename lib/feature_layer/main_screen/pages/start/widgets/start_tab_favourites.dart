import 'package:qb/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:qb/shared/widgets/promo_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/start_page_bloc.dart';

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
