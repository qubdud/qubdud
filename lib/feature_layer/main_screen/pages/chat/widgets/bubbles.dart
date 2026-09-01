import 'package:flutter/material.dart';

import '../../../../../shared/constants.dart';
import '../functions/format_timestamp.dart';

class MyMessageBubble extends StatelessWidget {
  final String content;
  final int timestamp;

  MyMessageBubble({required this.content, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(48.0+32.0,0,0,8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0,0,12,0),
              child: SelectableText(
                "You • ${formatTimestamp(timestamp)}",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 4, bottom: 8, right: 12),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Cień
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],


                color: cMidBrown,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: SelectableText(
                content,
                style: TextStyle(color: Colors.white,fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserMessageBubble extends StatelessWidget {
  final String content;
  final int timestamp;
  final String userName;
  final String country;

  UserMessageBubble({
    required this.content,
    required this.timestamp,
    required this.userName,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0,0,44,8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 8,),
            // Avatar użytkownika
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
              child:
              CircleAvatar(radius: 16,
                  child: Text(country)),

            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    "$userName • ${formatTimestamp(timestamp)}",
                    style: TextStyle(fontSize: 12),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 4, bottom: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // Cień
                          blurRadius: 10.0,
                          offset: const Offset(0, 4),
                        ),
                      ],



                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: SelectableText(
                      content,
                      style: TextStyle(color: cDarkBrown,fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyPostBubble extends StatelessWidget {
  final String content;
  final String timestamp;

  MyPostBubble({required this.content, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(48.0+32.0,0,0,8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0,0,12,0),
              child: SelectableText(
                "You • ${timestamp}",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 4, bottom: 8, right: 12),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Cień
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],


                color: cMidBrown,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: SelectableText(
                content,
                style: TextStyle(color: Colors.white,fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserPostBubble extends StatelessWidget {
  final String content;
  final String timestamp;
  final String userName;
  final String country;

  UserPostBubble({
    required this.content,
    required this.timestamp,
    required this.userName,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0,0,44,8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 8,),
            // Avatar użytkownika
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 16,
                child: Text(country),
              )
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    "$userName • $timestamp",
                    style: TextStyle(fontSize: 12),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 4, bottom: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // Cień
                          blurRadius: 10.0,
                          offset: const Offset(0, 4),
                        ),
                      ],



                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: SelectableText(
                      content,
                      style: TextStyle(color: cDarkBrown,fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
