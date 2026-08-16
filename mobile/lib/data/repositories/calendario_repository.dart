import '../api_client.dart';
import '../models/calendario_giornata.dart';

class CalendarioRepository {
  CalendarioRepository(this._api);

  final ApiClient _api;

  Future<List<CalendarioGiornata>> fetchCalendario({required String stagione}) async {
    final response = await _api.dio.get('/calendario', queryParameters: {'stagione': stagione});
    return (response.data as List)
        .map((e) => CalendarioGiornata.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> salvaGiornata({
    required String stagione,
    required int giornata,
    required String avversario,
  }) async {
    await _api.dio.put('/calendario', data: {
      'stagione': stagione,
      'giornata': giornata,
      'avversario': avversario,
    });
  }

  Future<void> eliminaGiornata(String id) async {
    await _api.dio.delete('/calendario/$id');
  }
}
