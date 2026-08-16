import 'asta_partecipante.dart';
import 'player.dart';

class AstaPick {
  AstaPick({
    required this.id,
    required this.astaId,
    required this.playerId,
    required this.partecipanteId,
    required this.prezzo,
    required this.player,
    required this.partecipante,
  });

  final String id;
  final String astaId;
  final String playerId;
  final String partecipanteId;
  final int prezzo;
  final Player player;
  final AstaPartecipante partecipante;

  factory AstaPick.fromJson(Map<String, dynamic> json) => AstaPick(
        id: json['id'] as String,
        astaId: json['astaId'] as String,
        playerId: json['playerId'] as String,
        partecipanteId: json['partecipanteId'] as String,
        prezzo: json['prezzo'] as int,
        player: Player.fromJson(json['player'] as Map<String, dynamic>),
        partecipante: AstaPartecipante.fromJson(json['partecipante'] as Map<String, dynamic>),
      );
}
