class News {
  final String id;
  final String title;
  final String content;
  final String publicationAt;
  final String imageUrl;
  final String navigationTarget;
  final String navigationName;
  final String pdf;
  final bool isNew;
  final bool isPin;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.publicationAt,
    this.imageUrl = '',
    this.navigationTarget = '',
    this.navigationName = '',
    this.pdf = '',
    required this.isNew,
    this.isPin = false,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      publicationAt: json['publication_at'] ?? '',
      imageUrl: json['image_url'] ?? '',
      navigationTarget: json['button']['route_name'] ?? '',
      navigationName: json['button']['name'] ?? '',
      pdf: json['pdf'] ?? '',
      isNew: json['is_new'] ?? false,
      isPin: json['is_pin'] ?? false,
    );
  }
}
