/// Google Drive draft link validation (must match API rules).
bool isValidGoogleDriveUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme != 'https') return false;

  final host = uri.host.toLowerCase();
  if (host != 'drive.google.com') return false;

  final path = uri.path.toLowerCase();
  if (path.startsWith('/file/') ||
      path.startsWith('/open') ||
      path.startsWith('/drive/')) {
    return true;
  }

  return false;
}

String? driveUrlError(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  if (isValidGoogleDriveUrl(trimmed)) return null;
  return 'Enter a valid Google Drive link (https://drive.google.com/...)';
}
