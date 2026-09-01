import 'dart:math';

import 'package:dio/dio.dart';
import 'package:qb/shared/globals.dart';

Response<dynamic> mockUserResponse(RequestOptions options) {
  return Response(
    requestOptions: options,
    statusCode: 200,
    data: {
      "status": "Success",
      "code": 200,
      "message": null,
      'data': {
        "id": "user_" + (Random().nextInt(10)).toString(),
        "country": {"id": "bcd4e129-3d43-414c-9d08-293371e6e68f", "name": "Poland", "country_code": "PL"},
        "role": null,
        "user_can_vote": true,
        "country_code": "PL",
        "first_name": "Wojtek",
        "last_name": "Galusz",
        "email": "johndoe@example.com",
        "role": "freeman",
        "team_name": "Alpha Team",
        "team_id": "team_456",
        "chat_id": "Chat_Id_789",
        "chat_token": "Chat_Token_abc123",
        "business_tasks": [],
        "action_flags": ["vote", "sticker"] // 'vote', 'sticker_1'
      },
    },
  );
}
