class Message {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isSentByMe; // Để phân biệt tin nhắn của mình và server (nếu có)

  Message({
    required this.id,
    required this.content,
    required this.timestamp,
    this.isSentByMe = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? DateTime.now().toString(),
      content: json['content'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isSentByMe: json['isSentByMe'] ?? false,
    );
  }
}
