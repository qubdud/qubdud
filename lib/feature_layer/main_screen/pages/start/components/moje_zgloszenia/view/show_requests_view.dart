import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import 'package:video_player/video_player.dart';


import '../../../../../../../shared/globals.dart';
import '../../../../../../../shared/widgets/loading.dart';
import '../../../../../../../shared/widgets/request_take_status.dart';
import '../../../../../../../shared/widgets/w_small_label.dart';
import '../bloc/show_requests_bloc.dart';


class ShowRequestsComponent extends StatelessWidget {
  const ShowRequestsComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShowRequestsComponentBloc(
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


  @override
  Widget build(BuildContext context) {


    return Column(
      children: [


        Expanded(
          child: BlocConsumer<ShowRequestsComponentBloc, ShowRequestsComponentState>(
            listener: (context, state) {
              if (state is ShowRequestsComponentNextState) {
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

  Widget _buildTabbedContent(ShowRequestsComponentState state) {


    if (state is ShowRequestsComponentLoadingState) {
      return Loading(noText: true, key: UniqueKey());
    }

    int ocena = 0;

    if(state.reviews.isNotEmpty){
      ocena = state.reviews.first.score;
    }





 return SizedBox(
      child: SingleChildScrollView(
        child: Column(
          children: [


              SizedBox(height: 32,),
         //   WSmallLabel(text: 'Moje Zgłoszenia'),
            Column(
              children: state.requests.asMap().entries.map((entry) {
                final video = entry.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔸 Miniatura z ikoną kosza na niej

                      GestureDetector(
                        onTap:(){
                          Globals.instance.selectedRequest = entry.value;
                          context.read<MainScreenBloc>().add(GoToShowRequestEvent());
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: video.thumbUrl,
                            width: 90,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      /// Ikona kosza w rogu




                      const SizedBox(width: 16),

                      /// 🔸 Opisy obok miniatury
                      SizedBox( height:160,

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(video.category, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(video.sector, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 8),
                            if (video.description.isNotEmpty)
                              Text(video.description, style: const TextStyle(fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),

                            Expanded(child: SizedBox()),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline_outlined, color: Colors.white, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  context.read<ShowRequestsComponentBloc>().add(TryDeleteMyRequestShowRequestsComponentEvent(id: video.id));
                                },
                              ),
                            ),
                          ],
                        ),

                      ),
                    ],
                  ),
                      RequestOffersBar(request: video),
                    ],
                  ),
                );
              }).toList(),
            ),
            if(state.requests.isEmpty)
              Text('Nie masz żadnych zgłoszeń'),



          ],
        ),
      ),
    );












  }


}

