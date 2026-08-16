class GiocatoreConsigliato {
  GiocatoreConsigliato({
    required this.id,
    required this.nome,
    required this.ruolo,
    required this.fvm,
  });

  final String id;
  final String nome;
  final String ruolo;
  final int fvm;

  factory GiocatoreConsigliato.fromJson(Map<String, dynamic> json) => GiocatoreConsigliato(
        id: json['id'] as String,
        nome: json['nome'] as String,
        ruolo: json['ruolo'] as String,
        fvm: json['fvm'] as int,
      );
}
