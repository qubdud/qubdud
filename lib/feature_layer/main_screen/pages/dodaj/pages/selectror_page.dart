import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_smallest_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../../../shared/functions/effective_role.dart';
import '../../../../../shared/widgets/w_card.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/dodaj_page_bloc.dart';

class DodajFilmSelectorPage extends StatelessWidget {
  const DodajFilmSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<DodajPageBloc>(), // używa tej samej instancji
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

    return BlocConsumer<DodajPageBloc, DodajPageState>(
      listener: (context, state) {
        if (state is DodajPageNextState) {
          context.read<MainScreenBloc>().add(InitEvent());
        }
      },
      builder: (context, state) {
        return
          Column(
          children: [
            if (isCompanyMode(user)) const SizedBox(height: kGapS),
            if (isCompanyMode(user)) WSmallestLabel(text: 'PREZENTACJA'),
            if (isCompanyMode(user))
              WCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(kGapL),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      Text(
                        textAlign: TextAlign.center,
                        'Tutaj dodasz film prezentujący Twoje usługi',
                        style: TextStyle(fontSize: 14),
                      ),

                      const SizedBox(height: kGapM),

                      InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickVideo(
                            source: ImageSource.camera, maxDuration: const Duration(seconds: 90),
                          );
                          if (pickedFile == null) return;
                          final file = File(pickedFile.path);

                           context.read<DodajPageBloc>().add(SelectedDodajPageEvent(fileType: 'video', file: file, selectType: 'promo', ))  ;},

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
                              Icon(Icons.camera_alt_outlined),
                              const SizedBox(width: kGapM),

                              const Expanded(
                                child: Text(
                                  'Nagraj z kamery',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
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



        context.read<DodajPageBloc>().add(SelectedDodajPageEvent(fileType: 'video', file: file, selectType: 'promo', ))  ;},

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
                              Icon(Icons.video_collection_outlined),
                              const SizedBox(width: kGapM),

                              const Expanded(
                                child: Text(
                                  'Wybierz z galerii',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
            if (!isCompanyMode(user)) const SizedBox(height: kGapS),

            if (!isCompanyMode(user)) WSmallestLabel(text: 'ZGŁOSZENIE '),

            if (!isCompanyMode(user)) WCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(kGapL),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      'Tutaj dodasz zgłoszenie — opisz, czego potrzebujesz, a firmy z okolicy odpowiedzą.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: kGapM),
                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                        if (pickedFile == null) return;

                        final file = File(pickedFile.path);



                        context.read<DodajPageBloc>().add(SelectedDodajPageEvent(fileType: 'img', file: file, selectType: 'request', ))  ;},

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
                            const SizedBox(width: kGapM),

                            const Expanded(
                              child: Text(
                                'Zrób zdjęcie',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
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



                        context.read<DodajPageBloc>().add(SelectedDodajPageEvent(fileType: 'video', file: file, selectType: 'request', ))  ;},
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
                            const SizedBox(width: kGapM),

                            const Expanded(
                              child: Text(
                                'Nagraj z kamery',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
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



                        context.read<DodajPageBloc>().add(SelectedDodajPageEvent(fileType: 'img', file: file, selectType: 'request', ))  ;},
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
                            const SizedBox(width: kGapM),

                            const Expanded(
                              child: Text(
                                'Wybierz obraz',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
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



                        context.read<DodajPageBloc>().add(SelectedDodajPageEvent(fileType: 'video', file: file, selectType: 'request', ))  ;},
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
                            const SizedBox(width: kGapM),

                            const Expanded(
                              child: Text(
                                'Wybierz wideo',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: kGapS),

                    InkWell(
                      onTap: () => context.read<DodajPageBloc>().add(SkipFileDodajPageEvent()),
                      borderRadius: BorderRadius.circular(kRadius),
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cLighterBrown,
                          borderRadius: BorderRadius.circular(kRadius),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.edit_note_outlined),
                            const SizedBox(width: kGapM),
                            const Expanded(
                              child: Text(
                                'Bez zdjęcia — tylko opis',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
