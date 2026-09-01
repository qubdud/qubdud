class Message {
  final String id;
  final String from;
  final String to;
  final String content;
  final int timestamp;
  final bool read;

  Message({
    required this.id,
    required this.from,
    required this.to,
    required this.content,
    required this.timestamp,
    required this.read,
  });

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] ?? 0,
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': from,
      'content': content,
      'timestamp': timestamp,
      'read': read,
    };
  }
}
