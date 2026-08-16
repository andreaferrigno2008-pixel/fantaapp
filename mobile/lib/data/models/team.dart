class Team {
  Team({required this.id, required this.nome, required this.sigla, this.logoUrl});

  final String id;
  final String nome;
  final String sigla;
  final String? logoUrl;

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        nome: json['nome'] as String,
        sigla: json['sigla'] as String,
        logoUrl: json['logoUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'sigla': sigla,
        'logoUrl': logoUrl,
      };
}
