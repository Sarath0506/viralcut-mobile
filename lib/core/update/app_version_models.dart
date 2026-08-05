class PlatformVersionInfo {
  const PlatformVersionInfo({this.latestVersion, this.storeUrl});

  final String? latestVersion;
  final String? storeUrl;

  factory PlatformVersionInfo.fromJson(Map<String, dynamic> json) {
    return PlatformVersionInfo(
      latestVersion: json['latestVersion'] as String?,
      storeUrl: json['storeUrl'] as String?,
    );
  }
}

class AppVersionInfo {
  const AppVersionInfo({required this.ios, required this.android});

  final PlatformVersionInfo ios;
  final PlatformVersionInfo android;

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      ios: PlatformVersionInfo.fromJson(
        json['ios'] as Map<String, dynamic>? ?? const {},
      ),
      android: PlatformVersionInfo.fromJson(
        json['android'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
