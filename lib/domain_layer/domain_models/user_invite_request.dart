class UserInviteRequest {
  final String userId;
  final String userName;
  final String department;
  final String departmentCode;
  final String country;
  final String countryCode;
  final String receivedDate;

  UserInviteRequest({
    required this.userId,
    required this.userName,
    required this.department,
    required this.departmentCode,
    required this.countryCode,
    required this.country,
    required this.receivedDate,
  });

  factory UserInviteRequest.fromJson(Map<String, dynamic> json) {
    return UserInviteRequest(
      userId: json['id'],
      userName: json['name'],
      department: json['department'],
      departmentCode: json['department_code'],
      country: json['country_name'],
      countryCode: json['country_code'],
      receivedDate: json['received_date'],
    );
  }
}
