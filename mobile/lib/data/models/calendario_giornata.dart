class CalendarioGiornata {
  CalendarioGiornata({
    required this.id,
    required this.stagione,
    required this.giornata,
    required this.avversario,
  });

  final String id;
  final String stagione;
  final int giornata;
  final String avversario;

  factory CalendarioGiornata.fromJson(Map<String, dynamic> json) => CalendarioGiornata(
        id: json['id'] as String,
        stagione: json['stagione'] as String,
        giornata: json['giornata'] as int,
        avversario: json['avversario'] as String,
      );
}
