class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.link,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String? body;
  final String? link;
  final bool read;
  final String createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String?,
        link: json['link'] as String?,
        read: json['read'] as bool? ?? false,
        createdAt: json['createdAt'] as String,
      );
}
