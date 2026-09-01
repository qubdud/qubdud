import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain_layer/domain_models/chat_user.dart';
import '../../../../../shared/constants.dart';
import '../bloc/chat_page_bloc.dart';
import '../functions/format_timestamp.dart';

class ChatUsersList extends StatelessWidget {
  final List<ChatUser> chatUsers;
  final bool isMobile;
  final ChatPageBloc bloc;
  const ChatUsersList({super.key, required this.chatUsers, required this.isMobile, required this.bloc,});

  @override
  Widget build(BuildContext context) {
    var filter = chatUsers;
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: filter.length,
      itemBuilder: (context, index) {
        final user = filter[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            hoverColor: cDarkBlue.withOpacity(0.1),
            onTap: () {
              bloc.add(StartUserChatChatPageEvent(user.uid,isMobile));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
              child: Row(
                children: [
                  // Flaga jako obrazek PNG
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
                      countryFlagImages[user.countryCode] ?? "assets/images/placeholder.png",
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover, // Zapewnia proporcjonalne dopasowanie
                    ),
                  ),
                  SizedBox(width: 10),

                  // Kod kraju
                  SizedBox(
                      width: 30,
                      child: Text(user.countryCode,
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey))),
                  SizedBox(width: 10),

                  // Imię i nazwisko
                  Expanded(
                    child: Text(user.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
