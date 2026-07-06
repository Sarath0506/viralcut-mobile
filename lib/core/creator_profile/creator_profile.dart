class CreatorProfile {
  CreatorProfile({
    required this.id,
    required this.platform,
    required this.handle,
    required this.isDefault,
    this.label,
    this.avatarUrl,
  });

  final String id;
  final String platform;
  final String handle;
  final bool isDefault;
  final String? label;
  final String? avatarUrl;

  String get displayName => label ?? handle;

  factory CreatorProfile.fromJson(Map<String, dynamic> json) => CreatorProfile(
        id: json['id'] as String,
        platform: json['platform'] as String,
        handle: json['handle'] as String,
        isDefault: json['isDefault'] as bool? ?? false,
        label: json['label'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
}
