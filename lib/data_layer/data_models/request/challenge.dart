import 'dart:io';

class ChallengeRequest {
  final String id;
  final bool public;
  final bool copyright;
  final String description;
  final List<String> files;

  ChallengeRequest({
    required this.id,
    required this.public,
    required this.copyright,
    required this.description,
    required this.files,

  });
}
