/// API host for the mobile app.
///
/// - **Android emulator:** default `http://10.0.2.2:3001` reaches your PC's localhost.
/// - **Physical device:** use your PC's LAN IP, e.g.
///   `flutter run --dart-define=API_BASE_URL=http://192.168.1.42:3001`
/// - **Production:** `flutter build apk --dart-define=API_BASE_URL=https://api.viralcut.com`
///
/// Ensure the API is running and Windows firewall allows port 3001.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3001',
);
