
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qb/shared/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/dodaj_page_bloc.dart';
import '../pages/request_page.dart';
import '../pages/selectror_page.dart';

class DodajPage extends StatelessWidget {
  const DodajPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DodajPageBloc(firebase: context.read<FirebaseService>()),
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
    final state = context.read<DodajPageBloc>().state;
    if (state is DodajPageMainState) {}
  }

  Widget build(BuildContext context) {
    return BlocConsumer<DodajPageBloc, DodajPageState>(
      listener: (context, state) {
        if (state is DodajPageNextState) {
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
    DodajPageState state,
    BuildContext context,
  ) {

    if (state is DodajPageLoadingState) {
      return const Loading(key: ValueKey('Loading'));
    }
    else if (state is DodajPageMainState) {

      return SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
             child:DodajFilmSelectorPage()));


    }
    else if (state is DodajRequestPromoState) {

      return DodajRequestFormPage();
    }




    else if(state is DodajPageUploadingState){

     return Center(
       child: Column(
         children: [
           SizedBox(height: MediaQuery.of(context).size.height/3,),
           Text(textAlign: TextAlign.center,'Trwa wysyłanie pliku.\n Poczekaj do zakończenia.'),
           const SizedBox(height: kGapS),

           TweenAnimationBuilder<double>(
             tween: Tween<double>(
               begin: 0,
               end: (state).progress * 100,
             ),
             duration: const Duration(milliseconds: 500),
             builder: (context, value, child) {
               return Text(
                 '${value.toInt()}%',
                 style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cDarkBlue),
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
  userAgentPackageName: 'com.qb.zkv.pl.qb',
);

Widget get osmAttribution => RichAttributionWidget(
  showFlutterMapAttribution: false,
  attributions: [
    TextSourceAttribution('OpenStreetMap',
        onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'))),
  ],
);

