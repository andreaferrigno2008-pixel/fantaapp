import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({String? baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? defaultBaseUrl,
          headers: {'x-api-key': apiKey},
        ));

  final Dio dio;

  // Backend in produzione su Render (Postgres su Neon): raggiungibile da
  // qualunque rete, non dipende dal PC. Per sviluppo locale contro il
  // backend sulla LAN, usare 'http://192.168.1.84:3000'; per l'emulatore
  // Android Studio, 'http://10.0.2.2:3000'.
  static const defaultBaseUrl = 'https://fanta-app-backend.onrender.com';

  // Deve combaciare con API_KEY nel .env del backend. App a uso personale,
  // quindi una chiave statica compilata nell'app va bene: non protegge da
  // chi decompila l'APK, solo da chi trova l'URL per caso.
  static const apiKey = 'NVMNotu3sjdIVRsUOrfYwbNXvft2ySbJ';
}
