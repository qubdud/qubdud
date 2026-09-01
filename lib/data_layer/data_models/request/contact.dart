class ContactRequest {
  final String subject;
  final String message;

  ContactRequest({
    required this.subject,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'topic': subject,
      'message': message,
    };
  }
}
