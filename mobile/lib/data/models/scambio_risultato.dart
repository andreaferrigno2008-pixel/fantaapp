class DettaglioGiocatoreScambio {
  DettaglioGiocatoreScambio({
    required this.id,
    required this.nome,
    required this.valoreBase,
    required this.fattoreForma,
    required this.fattoreTrend,
    required this.valoreScambio,
  });

  final String id;
  final String nome;
  final int valoreBase;
  final double fattoreForma;
  final double fattoreTrend;
  final int valoreScambio;

  factory DettaglioGiocatoreScambio.fromJson(Map<String, dynamic> json) =>
      DettaglioGiocatoreScambio(
        id: json['id'] as String,
        nome: json['nome'] as String,
        valoreBase: json['valoreBase'] as int,
        fattoreForma: (json['fattoreForma'] as num).toDouble(),
        fattoreTrend: (json['fattoreTrend'] as num).toDouble(),
        valoreScambio: json['valoreScambio'] as int,
      );
}

class ScambioRisultato {
  ScambioRisultato({
    required this.verdetto,
    required this.percentuale,
    required this.totaleDato,
    required this.totaleRicevuto,
    required this.dettaglioDati,
    required this.dettaglioRicevuti,
    required this.nessunaStatisticaDisponibile,
  });

  final String verdetto; // "FAVOREVOLE" | "SFAVOREVOLE" | "EQUILIBRATO"
  final double percentuale;
  final int totaleDato;
  final int totaleRicevuto;
  final List<DettaglioGiocatoreScambio> dettaglioDati;
  final List<DettaglioGiocatoreScambio> dettaglioRicevuti;
  final bool nessunaStatisticaDisponibile;

  factory ScambioRisultato.fromJson(Map<String, dynamic> json) => ScambioRisultato(
        verdetto: json['verdetto'] as String,
        percentuale: (json['percentuale'] as num).toDouble(),
        totaleDato: json['totaleDato'] as int,
        totaleRicevuto: json['totaleRicevuto'] as int,
        dettaglioDati: (json['dettaglioDati'] as List<dynamic>)
            .map((d) => DettaglioGiocatoreScambio.fromJson(d as Map<String, dynamic>))
            .toList(),
        dettaglioRicevuti: (json['dettaglioRicevuti'] as List<dynamic>)
            .map((d) => DettaglioGiocatoreScambio.fromJson(d as Map<String, dynamic>))
            .toList(),
        nessunaStatisticaDisponibile: json['nessunaStatisticaDisponibile'] as bool,
      );
}
