import '../api_client.dart';
import '../models/formazione_risultato.dart';

class FormazioneRepository {
  FormazioneRepository(this._api);

  final ApiClient _api;

  Future<FormazioneRisultato> genera({
    required String stagione,
    required int budgetTotale,
    int slotP = 3,
    int slotD = 8,
    int slotC = 8,
    int slotA = 6,
    List<String> obiettiviPlayerIds = const [],
  }) async {
    final response = await _api.dio.post('/formazioni/genera', data: {
      'stagione': stagione,
      'budgetTotale': budgetTotale,
      'slotP': slotP,
      'slotD': slotD,
      'slotC': slotC,
      'slotA': slotA,
      'obiettiviPlayerIds': obiettiviPlayerIds,
    });
    return FormazioneRisultato.fromJson(response.data as Map<String, dynamic>);
  }
}
