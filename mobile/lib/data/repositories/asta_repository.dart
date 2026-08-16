import '../api_client.dart';
import '../models/asta.dart';
import '../models/asta_pick.dart';
import '../models/consiglio_asta.dart';
import '../models/giocatore_consigliato.dart';

class AstaRepository {
  AstaRepository(this._api);

  final ApiClient _api;

  Future<Asta> creaAsta({
    required String stagione,
    required int budgetTotale,
    int slotP = 3,
    int slotD = 8,
    int slotC = 8,
    int slotA = 6,
    List<String> avversari = const [],
  }) async {
    final response = await _api.dio.post('/aste', data: {
      'stagione': stagione,
      'budgetTotale': budgetTotale,
      'slotP': slotP,
      'slotD': slotD,
      'slotC': slotC,
      'slotA': slotA,
      'avversari': avversari,
    });
    return Asta.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Asta> getAsta(String astaId) async {
    final response = await _api.dio.get('/aste/$astaId');
    return Asta.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AstaPick> registraPick({
    required String astaId,
    required String playerId,
    required String partecipanteId,
    required int prezzo,
  }) async {
    final response = await _api.dio.post('/aste/$astaId/picks', data: {
      'playerId': playerId,
      'partecipanteId': partecipanteId,
      'prezzo': prezzo,
    });
    return AstaPick.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> eliminaPick({required String astaId, required String pickId}) async {
    await _api.dio.delete('/aste/$astaId/picks/$pickId');
  }

  Future<ConsiglioAsta> getConsiglio({
    required String astaId,
    required String playerId,
    required int prezzoAttuale,
  }) async {
    final response = await _api.dio.get('/aste/$astaId/consiglio', queryParameters: {
      'playerId': playerId,
      'prezzoAttuale': prezzoAttuale,
    });
    return ConsiglioAsta.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<GiocatoreConsigliato>> getConsigliati({
    required String astaId,
    int limit = 20,
  }) async {
    final response = await _api.dio.get(
      '/aste/$astaId/consigliati',
      queryParameters: {'limit': limit},
    );
    return (response.data as List)
        .map((e) => GiocatoreConsigliato.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
