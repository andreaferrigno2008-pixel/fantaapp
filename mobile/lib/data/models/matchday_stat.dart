class MatchdayStat {
  MatchdayStat({
    required this.giornata,
    this.voto,
    this.fantavoto,
    required this.gol,
    required this.assist,
  });

  final int giornata;
  final double? voto;
  final double? fantavoto;
  final int gol;
  final int assist;

  factory MatchdayStat.fromJson(Map<String, dynamic> json) => MatchdayStat(
        giornata: json['giornata'] as int,
        voto: (json['voto'] as num?)?.toDouble(),
        fantavoto: (json['fantavoto'] as num?)?.toDouble(),
        gol: json['gol'] as int? ?? 0,
        assist: json['assist'] as int? ?? 0,
      );
}
