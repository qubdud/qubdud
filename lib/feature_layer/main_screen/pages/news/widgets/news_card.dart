import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:qb/app/app.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import 'package:qb/shared/constants.dart';
import 'package:flutter/material.dart';

import '../../../../../domain_layer/domain_models/news.dart';
import '../../../../../shared/widgets/w_button.dart';

Widget BpsNewsCard({required String date, required String title, required String news, required bool isNew, String imageHtml = '', required News newsitem, required BuildContext con}) {
  var context = con;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: isNew
            ? Border.all(
                color: cMidPink, // Możesz zmienić kolor ramki na dowolny
                width: 2.0, // Grubość ramki
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SelectableText(
                date,
                style: TextStyle(color: cMidBrown, fontSize: 14),
              ),
              if (isNew)
                Container(
                  height: 24, // Wysokość
                  decoration: BoxDecoration(
                    color: cMidPink, // Kolor tła
                    borderRadius: BorderRadius.all(
                      Radius.circular(12), // Jednakowe zaokrąglenie
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'NEW POST',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white, // Kolor tekstu
                          fontSize: 12, // Rozmiar tekstu
                          fontWeight: FontWeight.w700, // Pogrubienie tekstu
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 4,
          ),
          SelectableText(
            title,
            style: TextStyle(
              color: cDarkBrown, // Kolor tekstu
              fontSize: 20, // Rozmiar tekstu
              fontWeight: FontWeight.w700, // Pogrubienie tekstu
            ),
            textAlign: TextAlign.start,
          ),
          if (imageHtml.isNotEmpty)
            SizedBox(
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: imageHtml,
                  fit: BoxFit.fitWidth,
                )),

          SelectionArea(
            child: Html(data: news,
            ),
          ),
      //    SelectableText(
      //      news,
      //      style: TextStyle(
      //        color: cDarkBrown, // Kolor tekstu
      //        fontSize: 16, // Rozmiar tekstu
      //      ),
      //      textAlign: TextAlign.start,
      //    ),

          if (newsitem.navigationTarget.isNotEmpty)
            Column (
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 16,),
                Center(
                  child: WButton(text: newsitem.navigationName,
                  onPressed: (){
                    if(newsitem.navigationTarget=='my-account'){
                      con.read<MainScreenBloc>().add(GoToAccountEvent());
                    }
                    else if (newsitem.navigationTarget=='duels'){
                      con.read<MainScreenBloc>().add(GoToDuelsEvent());
                    }
                    else if (newsitem.navigationTarget=='rules'){
                      con.read<MainScreenBloc>().add(GoToRulesEvent());
                    }
                    else if (newsitem.navigationTarget=='wall'){
                      con.read<MainScreenBloc>().add(GoToWallEvent());
                    }
                    else if (newsitem.navigationTarget=='challenges'){
                      con.read<MainScreenBloc>().add(GoToChallengesEvent());
                    }
                    else {}

                  },),
                )
              ],
            )
        ],
      ),
    ),
  );
}
