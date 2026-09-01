import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qb/data_layer/data_models/request/create_team.dart';
import 'package:qb/data_layer/data_models/request/edit_team.dart';
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

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_card.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/dodaj_rev_page_bloc.dart';

class DodajFilmSelectorPage extends StatelessWidget {
  const DodajFilmSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<DodajReviewPageBloc>(), // używa tej samej instancji
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
  @override
    Widget build(BuildContext context) {



    var user = context.read<MainScreenBloc>().state.user;

    return BlocConsumer<DodajReviewPageBloc, DodajReviewPageState>(
      listener: (context, state) {
        if (state is DodajReviewPageNextState) {
          context.read<MainScreenBloc>().add(InitEvent());
        }
      },
      builder: (context, state) {
        return
          Column(
          children: [


            WSmallLabel(text: 'DODAJ RECENZJĘ'),

            WCard(
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      'Tutaj dodasz recenzję za wykonaną usługę.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (pickedFile == null) return;

                        final file = File(pickedFile.path);
                        final fileName = pickedFile.name;


                        context.read<DodajReviewPageBloc>().add(SelectedDodajReviewPageEvent(fileType: 'img', file: file, selectType: 'review', ))  ;},

                      borderRadius: BorderRadius.circular(8.0),
                      // jeśli chcesz rounded splash
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: cLighterBrown,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.photo_camera_outlined),
                            SizedBox(width: 16),

                            Text(
                              'Zrób zdjęcie',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(),

                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickVideo(
                          source: ImageSource.camera,
                        );
                        if (pickedFile == null) return;

                        final file = File(pickedFile.path);
                        final fileName = pickedFile.name;



                        context.read<DodajReviewPageBloc>().add(SelectedDodajReviewPageEvent(fileType: 'video', file: file, selectType: 'review', ))  ;},
                      borderRadius: BorderRadius.circular(8.0),
                      // jeśli chcesz rounded splash
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: cLighterBrown,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.video_call_outlined),
                            SizedBox(width: 16),

                            Text(
                              'Nagraj z kamery',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Divider(),

                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile == null) return;

                        final file = File(pickedFile.path);
                        final fileName = pickedFile.name;



                        context.read<DodajReviewPageBloc>().add(SelectedDodajReviewPageEvent(fileType: 'img', file: file, selectType: 'review', ))  ;},
                      borderRadius: BorderRadius.circular(8.0),
                      // jeśli chcesz rounded splash
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: cLighterBrown,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.photo_outlined),
                            SizedBox(width: 16),

                            Text(
                              'Wybierz obraz',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Divider(),

                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickVideo(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile == null) return;

                        final file = File(pickedFile.path);
                        final fileName = pickedFile.name;



                        context.read<DodajReviewPageBloc>().add(SelectedDodajReviewPageEvent(fileType: 'video', file: file, selectType: 'review', ))  ;},
                      borderRadius: BorderRadius.circular(8.0),
                      // jeśli chcesz rounded splash
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: cLighterBrown,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.video_library_outlined),
                            SizedBox(width: 16),

                            Text(
                              'Wybierz wideo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      },
    );
  }
}
