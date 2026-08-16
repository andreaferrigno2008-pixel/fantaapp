import '../api_client.dart';
import '../models/sync_run.dart';

class SyncRepository {
  SyncRepository(this._api);

  final ApiClient _api;

  Future<List<SyncRun>> fetchStatus() async {
    final response = await _api.dio.get('/sync/status');
    return (response.data as List)
        .map((e) => SyncRun.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sincronizzaQuotazioniOnline({required String stagione}) async {
    await _api.dio.post('/sync/quotazioni-online', data: {'stagione': stagione});
  }

  Future<void> importaVoti({required String stagione, required int giornata}) async {
    await _api.dio.post('/sync/voti', data: {'stagione': stagione, 'giornata': giornata});
  }
}
