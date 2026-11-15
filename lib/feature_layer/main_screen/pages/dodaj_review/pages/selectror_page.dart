import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:qb/shared/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


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
            WCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(kGapL),
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
                        final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                        if (pickedFile == null) return;

                        final file = File(pickedFile.path);


                        context.read<DodajReviewPageBloc>().add(SelectedDodajReviewPageEvent(fileType: 'img', file: file, selectType: 'review', ))  ;},

                      borderRadius: BorderRadius.circular(kRadius),
                      // jeśli chcesz rounded splash
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cLighterBrown,
                          borderRadius: BorderRadius.circular(kRadius),
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
                    const SizedBox(height: kGapS),

                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickVideo(
                          source: ImageSource.camera, maxDuration: const Duration(seconds: 90),
                        );
                        if (pickedFile == null) return;

                        final file = File(pickedFile.path);



                        context.read<DodajReviewPageBloc>().add(SelectedDodajReviewPageEvent(fileType: 'video', file: file, selectType: 'review', ))  ;},
                      borderRadius: BorderRadius.circular(kRadius),
                      // jeśli chcesz rounded splash
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cLighterBrown,
                          borderRadius: BorderRadius.circular(kRadius),
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

                    const SizedBox(height: kGapS),

                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (pickedFile == null) return;

                        final file = File(pickedFile.path);



                        context.read<DodajReviewPageBloc>().add(SelectedDodajReviewPageEvent(fileType: 'img', file: file, selectType: 'review', ))  ;},
                      borderRadius: BorderRadius.circular(kRadius),
                      // jeśli chcesz rounded splash
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cLighterBrown,
                          borderRadius: BorderRadius.circular(kRadius),
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

                    const SizedBox(height: kGapS),

                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickVideo(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile == null) return;

                        final file = File(pickedFile.path);



                        context.read<DodajReviewPageBloc>().add(SelectedDodajReviewPageEvent(fileType: 'video', file: file, selectType: 'review', ))  ;},
                      borderRadius: BorderRadius.circular(kRadius),
                      // jeśli chcesz rounded splash
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cLighterBrown,
                          borderRadius: BorderRadius.circular(kRadius),
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

                    const SizedBox(height: kGapS),

                    InkWell(
                      onTap: () => context.read<DodajReviewPageBloc>().add(SkipFileDodajReviewPageEvent()),
                      borderRadius: BorderRadius.circular(kRadius),
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cLighterBrown,
                          borderRadius: BorderRadius.circular(kRadius),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_note_outlined),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Bez zdjęcia — tylko ocena i opis',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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
