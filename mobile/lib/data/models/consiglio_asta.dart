class ConsiglioAsta {
  ConsiglioAsta({
    required this.verdetto,
    required this.prezzoMassimoConsigliato,
    required this.budgetResiduo,
    required this.slotResiduiRuolo,
    required this.slotResiduiTotali,
    required this.fascia,
    required this.motivazione,
  });

  final String verdetto; // "RILANCIA" | "ABBANDONA"
  final int prezzoMassimoConsigliato;
  final int budgetResiduo;
  final int slotResiduiRuolo;
  final int slotResiduiTotali;
  final String fascia; // "top" | "semitop" | "fascia_media" | "scommessa"
  final String motivazione;

  bool get isRilancia => verdetto == 'RILANCIA';

  static const _etichetteFascia = {
    'top': 'Top',
    'semitop': 'Semitop',
    'fascia_media': 'Fascia media',
    'scommessa': 'Scommessa',
  };

  String get fasciaEtichetta => _etichetteFascia[fascia] ?? fascia;

  factory ConsiglioAsta.fromJson(Map<String, dynamic> json) => ConsiglioAsta(
        verdetto: json['verdetto'] as String,
        prezzoMassimoConsigliato: json['prezzoMassimoConsigliato'] as int,
        budgetResiduo: json['budgetResiduo'] as int,
        slotResiduiRuolo: json['slotResiduiRuolo'] as int,
        slotResiduiTotali: json['slotResiduiTotali'] as int,
        fascia: json['fascia'] as String,
        motivazione: json['motivazione'] as String,
      );
}
