/// ===============================
/// MODEL
/// ===============================
class NotificationResponse {
  final bool result;
  final String message;
  final List<AstroNotification> notifications;

  NotificationResponse({
    required this.result,
    required this.message,
    required this.notifications,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      result: json['result'] == true,
      message: json['message']?.toString() ?? '',
      notifications: (json['notifications'] as List?)
              ?.map((e) => AstroNotification.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AstroNotification {
  final String id;
  final String title;
  final String description;
  final String addedOn;
  final bool isRead;

  AstroNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.addedOn,
    required this.isRead,
  });

  factory AstroNotification.fromJson(Map<String, dynamic> json) {
    return AstroNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      addedOn: json['added_on']?.toString() ?? '',
      isRead: json['read_status'] == "1",
    );
  }
}