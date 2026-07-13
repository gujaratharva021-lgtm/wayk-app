class ApiConfig {
  // Physical device over USB: run `adb reverse tcp:8080 tcp:8080` once
  // before `flutter run` so the phone's localhost:8080 forwards to your
  // PC's backend (which is what makes "localhost" work here even though
  // the app runs on a separate device).
  //
  // Android emulator instead of a real device? Use 10.0.2.2 instead of
  // localhost: static const String baseUrl = 'http://10.0.2.2:8080/api';
  static const String baseUrl = 'http://3.108.40.179/api';
}
