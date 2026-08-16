import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : dio = Dio(BaseOptions(baseUrl: baseUrl ?? defaultBaseUrl));

  final Dio dio;

  // IP LAN del PC che esegue il backend (rete di casa, scheda Ethernet).
  // Va aggiornato se il PC cambia rete o riceve un altro IP dal router.
  // Per l'emulatore Android Studio usare invece 'http://10.0.2.2:3000'.
  static const defaultBaseUrl = 'http://192.168.1.84:3000';
}
