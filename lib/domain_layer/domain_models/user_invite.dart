class UserInvite {
  final String userId;
  final String userName;
  final String department;
  final String departmentCode;
  final String countryCode;
  final String country;
  bool isInvitationSent;

  UserInvite({
    required this.userId,
    required this.userName,
    required this.department,
    required this.departmentCode,
    required this.country,
    required this.countryCode,
    required this.isInvitationSent,
  });

  factory UserInvite.fromJson(Map<String, dynamic> json) {
    return UserInvite(
      userId: json['id']??'',
      userName: json['name']??'',
      department: json['department']??'',
      departmentCode: json['department_code']??'',
      country: json['country_name']??'',
      countryCode: json['country_code']??'',
      isInvitationSent: json['invitation_sent']??false,
    );
  }
}
