import '../api_client.dart';
import '../models/formazione_titolare_risultato.dart';
import '../models/rosa_entry.dart';

class RosaRepository {
  RosaRepository(this._api);

  final ApiClient _api;

  Future<List<RosaEntry>> getRosa() async {
    final response = await _api.dio.get('/rosa');
    return (response.data as List)
        .map((e) => RosaEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> aggiungiGiocatore(String playerId) async {
    await _api.dio.post('/rosa', data: {'playerId': playerId});
  }

  Future<void> rimuoviGiocatore(String playerId) async {
    await _api.dio.delete('/rosa/$playerId');
  }

  Future<FormazioneTitolareRisultato> getFormazioneTitolare() async {
    final response = await _api.dio.get('/rosa/formazione-titolare');
    return FormazioneTitolareRisultato.fromJson(response.data as Map<String, dynamic>);
  }
}
