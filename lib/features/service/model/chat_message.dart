class ChatMessage {
  String name;
  String to;
  String from;
  String message;
  String type;
  String messageId;
  int dateTime;
  bool seen;

  ChatMessage({
    required this.name,
    required this.to,
    required this.from,
    required this.message,
    required this.type,
    required this.messageId,
    required this.dateTime,
    required this.seen,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      name: json['name'] ?? '',
      to: json['to'] ?? '',
      from: json['from'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'text',
      messageId: json['message_id'] ?? '',
      dateTime: json['date_time'] ?? 0,
      seen: json['seen'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'to': to,
    'from': from,
    'message': message,
    'type': type,
    'message_id': messageId,
    'date_time': dateTime,
  };
}
