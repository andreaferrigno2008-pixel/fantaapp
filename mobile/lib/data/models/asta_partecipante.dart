class AstaPartecipante {
  AstaPartecipante({
    required this.id,
    required this.astaId,
    required this.nome,
    required this.sonIo,
  });

  final String id;
  final String astaId;
  final String nome;
  final bool sonIo;

  factory AstaPartecipante.fromJson(Map<String, dynamic> json) => AstaPartecipante(
        id: json['id'] as String,
        astaId: json['astaId'] as String,
        nome: json['nome'] as String,
        sonIo: json['sonIo'] as bool,
      );
}
