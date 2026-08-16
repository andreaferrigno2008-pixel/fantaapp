class PlayerQuotation {
  PlayerQuotation({required this.id, required this.data, required this.valore});

  final String id;
  final DateTime data;
  final int valore;

  factory PlayerQuotation.fromJson(Map<String, dynamic> json) => PlayerQuotation(
        id: json['id'] as String,
        data: DateTime.parse(json['data'] as String),
        valore: json['valore'] as int,
      );
}
