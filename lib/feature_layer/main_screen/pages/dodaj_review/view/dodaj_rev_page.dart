import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_dropdown.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:qb/shared/widgets/w_label.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import 'package:latlong2/latlong.dart';

import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/review.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../bloc/main_bloc.dart';
import '../../start/components/user2_info/view/user_info_component.dart';
import '../bloc/dodaj_rev_page_bloc.dart';
import '../pages/review_page.dart';
import '../pages/selectror_page.dart';
import '../widgets/user_info_short/view/user_info_component.dart';

class DodajReviewPage extends StatelessWidget {
  const DodajReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DodajReviewPageBloc(firebase: context.read<FirebaseService>()),
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
  String type = '';
  String color = '';




  @override
  void initState() {
    super.initState();
    final state = context.read<DodajReviewPageBloc>().state;
    if (state is DodajReviewPageMainState) {}
  }

  Widget build(BuildContext context) {
    return BlocConsumer<DodajReviewPageBloc, DodajReviewPageState>(
      listener: (context, state) {
        if (state is DodajReviewPageNextState) {
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
          child: _buildWidgetBasedOnState(state, context),
        );
      },
    );
  }

  Widget _buildWidgetBasedOnState(
      DodajReviewPageState state,
      BuildContext context,
      ) {

    if (state is DodajReviewPageLoadingState) {
      return const Loading(key: ValueKey('Loading'));
    }
    else if (state is DodajReviewPageMainState) {

      return SingleChildScrollView(
          child: Column(
            children: [

              // Lista recenzji z podglądem pliku i komentarzami
              if (state.reviews.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Opinie (${state.reviews.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...state.reviews.map((review) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Miniatura zdjęcia/video
                        if (review.thumbUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: CachedNetworkImage(
                              imageUrl: review.thumbUrl,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        // Treść + komentarze
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: ReviewWithComments(review: review),
                        ),
                      ],
                    ),
                  ),
                )),
              ],




              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Info o firmie której dotyczy recenzja
                    if (Globals.instance.selectedPromo != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.business_outlined, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            const Text('Recenzja dla: ', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
                            Expanded(
                              child: Text(
                                (Globals.instance.selectedPromo?.companyName.isNotEmpty == true ? Globals.instance.selectedPromo!.companyName : 'firmy'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    DodajFilmSelectorPage(),
                  ],
                ),
              ),
            ],
          ));


    }


    else if (state is DodajRequestPromoState) {

      return DodajReviewFormPage();
    }




    else if(state is DodajReviewPageUploadingState){

      return Center(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height/3,),
            Text(textAlign: TextAlign.center,'Trwa wysyłanie pliku.\n Poczekaj do zakończenia.'),

            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: (state as DodajReviewPageUploadingState).progress * 100,
              ),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: cDarkBlue),
                );
              },
            ),

          ],
        ),
      );
    }

    else {
      return const Loading(key: ValueKey('Loading'));
    }
  }
}

TileLayer get openStreetMap => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleatflet.flutter.map.example',
);