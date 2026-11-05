/// Backend base URL.
///
/// - Emulator Android: http://10.0.2.2:3000
/// - Phone USB with `adb reverse tcp:3000 tcp:3000`: http://127.0.0.1:3000
/// - Phone Wi-Fi: http://IP_PC:3000
///
/// Override: flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );
}
