import '../api_client.dart';
import '../models/player.dart';
import '../models/team.dart';

class PlayersRepository {
  PlayersRepository(this._api);

  final ApiClient _api;

  Future<List<Player>> fetchPlayers({String? ruolo, String? teamId, String? search}) async {
    final response = await _api.dio.get('/players', queryParameters: {
      if (ruolo != null) 'ruolo': ruolo,
      if (teamId != null) 'team': teamId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (response.data as List)
        .map((e) => Player.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String?> fetchCurrentSeason() async {
    final response = await _api.dio.get('/players/current-season');
    return (response.data as Map<String, dynamic>)['stagione'] as String?;
  }

  Future<Player> fetchPlayerDetail(String id) async {
    final response = await _api.dio.get('/players/$id');
    return Player.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Team>> fetchTeams() async {
    final response = await _api.dio.get('/teams');
    return (response.data as List).map((e) => Team.fromJson(e as Map<String, dynamic>)).toList();
  }
}
