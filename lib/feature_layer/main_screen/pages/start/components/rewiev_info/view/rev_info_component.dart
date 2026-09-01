import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import 'package:video_player/video_player.dart';


import '../../../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../../../shared/globals.dart';
import '../../../../../../../shared/widgets/loading.dart';
import '../bloc/rev_info_bloc.dart';

class RevInfoComponent extends StatelessWidget {
  final Promo selectedPromo;
  const RevInfoComponent({super.key, required this.selectedPromo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RevInfoComponentBloc(
        firebase: context.read<FirebaseService>(),
        user: context.read<MainScreenBloc>().state.user!,
      ),
      child: View(selectedPromo: selectedPromo),
    );
  }
}

class View extends StatefulWidget {
  final Promo selectedPromo;
  const View({super.key, required this.selectedPromo});


  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> with SingleTickerProviderStateMixin {


  @override
  Widget build(BuildContext context) {


    return Column(
      children: [


        Expanded(
          child: BlocConsumer<RevInfoComponentBloc, RevInfoComponentState>(
            listener: (context, state) {
              if (state is RevInfoComponentNextState) {
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




                child:











                _buildTabbedContent(state),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabbedContent(RevInfoComponentState state) {


    if (state is RevInfoComponentLoadingState) {
      return Loading(noText: true, key: UniqueKey());
    }

    if (state is RevInfoComponentMainState) {

      int ocena = 0;

      if (state.reviews.isNotEmpty) {
        final avg = state.reviews
            .map((r) => r.score)
            .reduce((a, b) => a + b) /
            state.reviews.length;

        ocena = avg.round(); // ⬅️ zaokrąglenie do INT
      }


      return Row(

          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,

          children:

          [
            Expanded(child: SizedBox()),
            ...List.generate(5, (index) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  index < ocena ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 18,
                ),
                onPressed: () {
                  Globals.instance.selectedPromo = widget.selectedPromo;
                  context.read<MainScreenBloc>().add(
                      GoToDodajReviewEvent());



                },
              );
            }),


          ]

      );





    }

    return Loading(noText: true, key: UniqueKey());












  }


}

