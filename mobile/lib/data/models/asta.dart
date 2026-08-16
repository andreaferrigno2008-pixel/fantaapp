import 'asta_partecipante.dart';
import 'asta_pick.dart';

class Asta {
  Asta({
    required this.id,
    required this.stagione,
    required this.budgetTotale,
    required this.slotP,
    required this.slotD,
    required this.slotC,
    required this.slotA,
    required this.stato,
    required this.partecipanti,
    required this.picks,
    this.budgetResiduo,
    this.slotResidui,
  });

  final String id;
  final String stagione;
  final int budgetTotale;
  final int slotP;
  final int slotD;
  final int slotC;
  final int slotA;
  final String stato;
  final List<AstaPartecipante> partecipanti;
  final List<AstaPick> picks;
  // Presenti solo nella risposta di GET /aste/:id (calcolati dal backend).
  final int? budgetResiduo;
  final Map<String, int>? slotResidui;

  factory Asta.fromJson(Map<String, dynamic> json) => Asta(
        id: json['id'] as String,
        stagione: json['stagione'] as String,
        budgetTotale: json['budgetTotale'] as int,
        slotP: json['slotP'] as int,
        slotD: json['slotD'] as int,
        slotC: json['slotC'] as int,
        slotA: json['slotA'] as int,
        stato: json['stato'] as String,
        partecipanti: (json['partecipanti'] as List<dynamic>? ?? [])
            .map((e) => AstaPartecipante.fromJson(e as Map<String, dynamic>))
            .toList(),
        picks: (json['picks'] as List<dynamic>? ?? [])
            .map((e) => AstaPick.fromJson(e as Map<String, dynamic>))
            .toList(),
        budgetResiduo: json['budgetResiduo'] as int?,
        slotResidui: (json['slotResidui'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as int)),
      );
}
