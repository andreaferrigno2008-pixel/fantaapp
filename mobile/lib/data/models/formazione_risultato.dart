import 'player.dart';

class FormazioneRisultato {
  FormazioneRisultato({
    required this.formazione,
    required this.budgetTotale,
    required this.budgetSpeso,
    required this.budgetResiduo,
    required this.fvmTotale,
    required this.warning,
  });

  final Map<String, List<Player>> formazione;
  final int budgetTotale;
  final int budgetSpeso;
  final int budgetResiduo;
  final int fvmTotale;
  final List<String> warning;

  factory FormazioneRisultato.fromJson(Map<String, dynamic> json) => FormazioneRisultato(
        formazione: (json['formazione'] as Map<String, dynamic>).map(
          (ruolo, giocatori) => MapEntry(
            ruolo,
            (giocatori as List<dynamic>)
                .map((g) => Player.fromJson(g as Map<String, dynamic>))
                .toList(),
          ),
        ),
        budgetTotale: json['budgetTotale'] as int,
        budgetSpeso: json['budgetSpeso'] as int,
        budgetResiduo: json['budgetResiduo'] as int,
        fvmTotale: json['fvmTotale'] as int,
        warning: (json['warning'] as List<dynamic>).map((w) => w as String).toList(),
      );
}
