class GiocatoreFormazione {
  GiocatoreFormazione({
    required this.id,
    required this.nome,
    required this.ruolo,
    required this.valoreForma,
    required this.formaReale,
  });

  final String id;
  final String nome;
  final String ruolo;
  final double valoreForma;
  final bool formaReale;

  factory GiocatoreFormazione.fromJson(Map<String, dynamic> json) => GiocatoreFormazione(
        id: json['id'] as String,
        nome: json['nome'] as String,
        ruolo: json['ruolo'] as String,
        valoreForma: (json['valoreForma'] as num).toDouble(),
        formaReale: json['formaReale'] as bool,
      );
}

class ModuloValutazione {
  ModuloValutazione({required this.modulo, required this.fattibile, this.valoreTotale});

  final String modulo;
  final bool fattibile;
  final double? valoreTotale;

  factory ModuloValutazione.fromJson(Map<String, dynamic> json) => ModuloValutazione(
        modulo: json['modulo'] as String,
        fattibile: json['fattibile'] as bool,
        valoreTotale: (json['valoreTotale'] as num?)?.toDouble(),
      );
}

const _ordineRuoli = ['P', 'D', 'C', 'A'];

class FormazioneTitolareRisultato {
  FormazioneTitolareRisultato({
    required this.modulo,
    required this.titolari,
    required this.panchina,
    required this.moduliValutati,
    required this.warning,
  });

  final String modulo;
  final Map<String, List<GiocatoreFormazione>> titolari;
  final List<GiocatoreFormazione> panchina;
  final List<ModuloValutazione> moduliValutati;
  final List<String> warning;

  List<GiocatoreFormazione> get titolariOrdinati =>
      _ordineRuoli.expand((ruolo) => titolari[ruolo] ?? const <GiocatoreFormazione>[]).toList();

  factory FormazioneTitolareRisultato.fromJson(Map<String, dynamic> json) =>
      FormazioneTitolareRisultato(
        modulo: json['modulo'] as String,
        titolari: (json['titolari'] as Map<String, dynamic>).map(
          (ruolo, giocatori) => MapEntry(
            ruolo,
            (giocatori as List<dynamic>)
                .map((g) => GiocatoreFormazione.fromJson(g as Map<String, dynamic>))
                .toList(),
          ),
        ),
        panchina: (json['panchina'] as List<dynamic>)
            .map((g) => GiocatoreFormazione.fromJson(g as Map<String, dynamic>))
            .toList(),
        moduliValutati: (json['moduliValutati'] as List<dynamic>)
            .map((m) => ModuloValutazione.fromJson(m as Map<String, dynamic>))
            .toList(),
        warning: (json['warning'] as List<dynamic>).map((w) => w as String).toList(),
      );
}
