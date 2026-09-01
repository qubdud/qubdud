import 'package:cached_network_image/cached_network_image.dart';
import 'package:qb/shared/constants.dart';
import 'package:flutter/material.dart';

Widget NotificationCard({required String date, required String title, required String news, required bool isNew, String avatar = '',String createdAt =''}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isNew?Color(0xFFFECEDA):cLighterBrown,
        borderRadius: BorderRadius.circular(16.0),
        border: isNew
            ? Border.all(
                color: cMidPink, // Możesz zmienić kolor ramki na dowolny
                width: 2.0, // Grubość ramki
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle, // Zapewnia okrągły kształt
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2), // Kolor cienia
                  spreadRadius: 2, // Rozprzestrzenienie cienia
                  blurRadius: 8, // Rozmycie cienia
                  offset: Offset(1, 2), // Przesunięcie cienia w prawo i w dół
                ),
              ],
            ),
            child: Image.asset(
              countryFlagImages[avatar] ?? "assets/images/flags/nexi_circle.png",
              width: 48,
              height: 48,
              fit: BoxFit.cover, // Zapewnia proporcjonalne dopasowanie
            ),
          ),
          SizedBox(width: 16,),


          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SelectableText(
                        title,
                        style: TextStyle(
                          color: cDarkBrown, // Kolor tekstu
                          fontSize: 20, // Rozmiar tekstu
                          fontWeight: FontWeight.w700, // Pogrubienie tekstu
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Column(
                      children: [
                        Text(createdAt,
                          style: TextStyle(
                          color: Colors.grey, // Kolor tekstu
                          fontSize: 14, // Rozmiar tekstu
                        ),),
                        Icon(Icons.delete_forever_outlined),



                      ],
                    )
                  ],
                ),
                Text(
                  news, // Usunięto testowy tekst
                  style: TextStyle(
                    color: cDarkBrown, // Kolor tekstu
                    fontSize: 16, // Rozmiar tekstu
                  ),
                  textAlign: TextAlign.start,
                  maxLines: 2, // Ograniczenie do 2 linii
                  overflow: TextOverflow.ellipsis, // Dodanie "..." jeśli tekst jest za długi
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
