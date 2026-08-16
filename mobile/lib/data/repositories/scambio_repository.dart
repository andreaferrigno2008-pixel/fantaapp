import '../api_client.dart';
import '../models/scambio_risultato.dart';

class ScambioRepository {
  ScambioRepository(this._api);

  final ApiClient _api;

  Future<ScambioRisultato> valuta({
    required List<String> datiIds,
    required List<String> ricevutiIds,
  }) async {
    final response = await _api.dio.post('/scambi/valuta', data: {
      'datiIds': datiIds,
      'ricevutiIds': ricevutiIds,
    });
    return ScambioRisultato.fromJson(response.data as Map<String, dynamic>);
  }
}
