import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
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
            if (isCompanyMode(user)) SizedBox(height: 16),
            if (isCompanyMode(user)) WSmallLabel(text: 'PREZENTACJA'),
            if (isCompanyMode(user))
              WCard(
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      Text(
                        textAlign: TextAlign.center,
                        'Tutaj dodasz film prezentujący Twoje usługi',
                        style: TextStyle(fontSize: 14),
                      ),

                      SizedBox(height: 16),

                      InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickVideo(
                            source: ImageSource.camera, maxDuration: const Duration(seconds: 90),
                          );
                          if (pickedFile == null) return;
                          final file = File(pickedFile.path);

                           context.read<DodajPageBloc>().add(SelectedDodajPageEvent(fileType: 'video', file: file, selectType: 'promo', ))  ;},

                        borderRadius: BorderRadius.circular(8.0),
                        // jeśli chcesz rounded splash
                        child: Ink(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cLighterBrown,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt_outlined),
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
        final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        );
        if (pickedFile == null) return;

        final file = File(pickedFile.path);



        context.read<DodajPageBloc>().add(SelectedDodajPageEvent(fileType: 'video', file: file, selectType: 'promo', ))  ;},

                        borderRadius: BorderRadius.circular(8.0),
                        // jeśli chcesz rounded splash
                        child: Ink(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cLighterBrown,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.video_collection_outlined),
                              SizedBox(width: 16),

                              Text(
                                'Wybierz z galerii',
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
            if (!isCompanyMode(user)) SizedBox(height: 32),

            if (!isCompanyMode(user)) WSmallLabel(text: 'ZGŁOSZENIE '),

            if (!isCompanyMode(user)) WCard(
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      'Tutaj dodasz zgłoszenie — opisz, czego potrzebujesz, a firmy z okolicy odpowiedzą.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                        if (pickedFile == null) return;

                        final file = File(pickedFile.path);



                        context.read<DodajPageBloc>().add(SelectedDodajPageEvent(fileType: 'img', file: file, selectType: 'request', ))  ;},

                      borderRadius: BorderRadius.circular(8.0),
                      // jeśli chcesz rounded splash
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cLighterBrown,
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
                          source: ImageSource.camera, maxDuration: const Duration(seconds: 90),
                        );
                        if (pickedFile == null) return;

                        final file = File(pickedFile.path);



                        context.read<DodajPageBloc>().add(SelectedDodajPageEvent(fileType: 'video', file: file, selectType: 'request', ))  ;},
                      borderRadius: BorderRadius.circular(8.0),
                      // jeśli chcesz rounded splash
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cLighterBrown,
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
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (pickedFile == null) return;

                        final file = File(pickedFile.path);



                        context.read<DodajPageBloc>().add(SelectedDodajPageEvent(fileType: 'img', file: file, selectType: 'request', ))  ;},
                      borderRadius: BorderRadius.circular(8.0),
                      // jeśli chcesz rounded splash
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cLighterBrown,
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



                        context.read<DodajPageBloc>().add(SelectedDodajPageEvent(fileType: 'video', file: file, selectType: 'request', ))  ;},
                      borderRadius: BorderRadius.circular(8.0),
                      // jeśli chcesz rounded splash
                      child: Ink(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cLighterBrown,
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
