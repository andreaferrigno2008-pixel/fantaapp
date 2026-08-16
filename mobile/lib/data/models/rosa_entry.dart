import 'player.dart';

class RosaEntry {
  RosaEntry({required this.id, required this.player, required this.createdAt});

  final String id;
  final Player player;
  final DateTime createdAt;

  factory RosaEntry.fromJson(Map<String, dynamic> json) => RosaEntry(
        id: json['id'] as String,
        player: Player.fromJson(json['player'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
