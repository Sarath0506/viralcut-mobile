import '../api/api_base_url.dart';

/// Resolves API-relative upload paths to absolute URLs for [Image.network].
String? resolveCampaignMediaUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    return '$kApiBaseUrl$trimmed';
  }
  return '$kApiBaseUrl/$trimmed';
}
