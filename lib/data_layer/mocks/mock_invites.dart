import 'package:dio/dio.dart';

Response<dynamic> mockInvitesResponse(RequestOptions options) {
  if (options.path == '/invites/teams/available') {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: [
        {"team_id": "team_123", "team_name": "Alpha Squad", "points": 100, "member_count": 5, "is_invitation_sent": false},
        {"team_id": "team_456", "team_name": "Beta Crew", "points": 200, "member_count": 8, "is_invitation_sent": true},
        {"team_id": "team_123", "team_name": "XXX Squad", "points": 22, "member_count": 5, "is_invitation_sent": false},
        {"team_id": "team_456", "team_name": "Red Crew", "points": 55, "member_count": 8, "is_invitation_sent": true},
        {"team_id": "team_456", "team_name": "Blue Crew", "points": 33, "member_count": 8, "is_invitation_sent": true},
      ],
    );
  } else if (options.path.startsWith('/invites/teams/send/')) {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: {"status": "success", "message": "Request to join sent successfully."},
    );
  } else if (options.path == '/invites/teams/pending') {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: [
        {"invitation_id": "inv_001", "team_id": "team_123", "team_name": "Alpha Squad", "date": "Today 22:22", "points": 100, "member_count": 5},
        {"invitation_id": "inv_001", "team_id": "team_123", "team_name": "Riders of the Srom", "date": "Today 11:22", "points": 0, "member_count": 0}
      ],
    );
  } else if (options.path.startsWith('/invites/teams/accept/')) {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: {"status": "success", "message": "Invite accepted successfully."},
    );
  } else if (options.path == '/invites/users/available') {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: [
        {"user_id": "user_001", "user_name": "John Doe", "department": "Sales", "country_code": "US", "is_invitation_sent": false},
        {"user_id": "user_002", "user_name": "Jane Smith", "department": "Marketing", "country_code": "UK", "is_invitation_sent": true}
      ],
    );
  } else if (options.path.startsWith('/invites/users/send/')) {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: {"status": "success", "message": "User invited successfully."},
    );
  } else if (options.path == '/invites/users/pending') {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: [
        {"invitation_id": "inv_002", "user_id": "user_001", "user_name": "John Doe", "department": "Sales", "country_code": "US"}
      ],
    );
  } else if (options.path.startsWith('/invites/users/accept/')) {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: {"status": "success", "message": "User accepted successfully."},
    );
  }

  return Response(
    requestOptions: options,
    statusCode: 400,
    data: {
      "status": "error",
      "message": "Invalid request data",
    },
  );
}
