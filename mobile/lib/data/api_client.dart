import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : dio = Dio(BaseOptions(baseUrl: baseUrl ?? defaultBaseUrl));

  final Dio dio;

  // Backend in produzione su Render (Postgres su Neon): raggiungibile da
  // qualunque rete, non dipende dal PC. Per sviluppo locale contro il
  // backend sulla LAN, usare 'http://192.168.1.84:3000'; per l'emulatore
  // Android Studio, 'http://10.0.2.2:3000'.
  static const defaultBaseUrl = 'https://fanta-app-backend.onrender.com';
}
