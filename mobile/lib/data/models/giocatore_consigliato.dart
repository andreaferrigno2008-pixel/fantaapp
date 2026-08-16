class GiocatoreConsigliato {
  GiocatoreConsigliato({
    required this.id,
    required this.nome,
    required this.ruolo,
    required this.fvm,
    required this.fascia,
  });

  final String id;
  final String nome;
  final String ruolo;
  final int fvm;
  final String fascia; // "top" | "semitop" | "fascia_media" | "scommessa"

  factory GiocatoreConsigliato.fromJson(Map<String, dynamic> json) => GiocatoreConsigliato(
        id: json['id'] as String,
        nome: json['nome'] as String,
        ruolo: json['ruolo'] as String,
        fvm: json['fvm'] as int,
        fascia: json['fascia'] as String,
      );
}
