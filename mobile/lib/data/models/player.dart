import 'matchday_stat.dart';
import 'player_quotation.dart';
import 'team.dart';

class Player {
  Player({
    required this.id,
    required this.nome,
    required this.team,
    required this.ruoloClassic,
    required this.quotazioneIniziale,
    required this.quotazioneAttuale,
    this.fvm,
    required this.stagione,
    this.quotazioni = const [],
    this.statistiche = const [],
  });

  final String id;
  final String nome;
  final Team team;
  final String ruoloClassic;
  final int quotazioneIniziale;
  final int quotazioneAttuale;
  final int? fvm;
  final String stagione;
  final List<PlayerQuotation> quotazioni;
  final List<MatchdayStat> statistiche;

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        nome: json['nome'] as String,
        team: Team.fromJson(json['team'] as Map<String, dynamic>),
        ruoloClassic: json['ruoloClassic'] as String,
        quotazioneIniziale: json['quotazioneIniziale'] as int,
        quotazioneAttuale: json['quotazioneAttuale'] as int,
        fvm: json['fvm'] as int?,
        stagione: json['stagione'] as String,
        quotazioni: (json['quotazioni'] as List<dynamic>?)
                ?.map((e) => PlayerQuotation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        statistiche: (json['statistiche'] as List<dynamic>?)
                ?.map((e) => MatchdayStat.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  // Usato solo per la cache locale (lista sintetica, senza storico) —
  // vedi LocalCache in data/local_cache.dart.
  Map<String, dynamic> toCacheJson() => {
        'id': id,
        'nome': nome,
        'team': team.toJson(),
        'ruoloClassic': ruoloClassic,
        'quotazioneIniziale': quotazioneIniziale,
        'quotazioneAttuale': quotazioneAttuale,
        'fvm': fvm,
        'stagione': stagione,
      };
}
