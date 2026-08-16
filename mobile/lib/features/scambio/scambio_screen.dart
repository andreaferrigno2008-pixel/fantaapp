import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/player.dart';
import '../../data/models/scambio_risultato.dart';

class ScambioScreen extends ConsumerStatefulWidget {
  const ScambioScreen({super.key});

  @override
  ConsumerState<ScambioScreen> createState() => _ScambioScreenState();
}

class _ScambioScreenState extends ConsumerState<ScambioScreen> {
  final List<Player> _dati = [];
  final List<Player> _ricevuti = [];

  bool _valutando = false;
  String? _errore;
  ScambioRisultato? _risultato;

  Future<void> _valutaScambio() async {
    if (_dati.isEmpty || _ricevuti.isEmpty) {
      setState(() => _errore = 'Seleziona almeno un giocatore da dare e uno da ricevere');
      return;
    }
    setState(() {
      _valutando = true;
      _errore = null;
    });
    try {
      final risultato = await ref.read(scambioRepositoryProvider).valuta(
            datiIds: _dati.map((p) => p.id).toList(),
            ricevutiIds: _ricevuti.map((p) => p.id).toList(),
          );
      setState(() => _risultato = risultato);
    } catch (_) {
      setState(() => _errore = 'Impossibile valutare lo scambio: verifica i giocatori scelti');
    } finally {
      if (mounted) setState(() => _valutando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consigliere Scambi')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Aggiungi i giocatori che dai e quelli che ricevi per sapere se conviene.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SezioneGiocatori(
            titolo: 'Cosa dai',
            selezionati: _dati,
            onAggiungi: (p) => setState(() => _dati.add(p)),
            onRimuovi: (p) => setState(() => _dati.remove(p)),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SezioneGiocatori(
            titolo: 'Cosa ricevi',
            selezionati: _ricevuti,
            onAggiungi: (p) => setState(() => _ricevuti.add(p)),
            onRimuovi: (p) => setState(() => _ricevuti.remove(p)),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_errore != null) ...[
            StatusBanner(message: _errore!, type: StatusBannerType.error),
            const SizedBox(height: AppSpacing.md),
          ],
          FilledButton(
            onPressed: _valutando ? null : _valutaScambio,
            child: _valutando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Valuta scambio'),
          ),
          if (_risultato != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _RisultatoScambio(risultato: _risultato!),
          ],
        ],
      ),
    );
  }
}

class _SezioneGiocatori extends ConsumerStatefulWidget {
  const _SezioneGiocatori({
    required this.titolo,
    required this.selezionati,
    required this.onAggiungi,
    required this.onRimuovi,
  });

  final String titolo;
  final List<Player> selezionati;
  final ValueChanged<Player> onAggiungi;
  final ValueChanged<Player> onRimuovi;

  @override
  ConsumerState<_SezioneGiocatori> createState() => _SezioneGiocatoriState();
}

class _SezioneGiocatoriState extends ConsumerState<_SezioneGiocatori> {
  final _searchController = TextEditingController();
  List<Player> _risultati = [];
  int _ricercaInCorso = 0;

  Future<void> _cerca(String query) async {
    final richiesta = ++_ricercaInCorso;
    if (query.trim().length < 2) {
      setState(() => _risultati = []);
      return;
    }
    try {
      final risultati = await ref.read(playersRepositoryProvider).fetchPlayers(search: query);
      if (richiesta == _ricercaInCorso) {
        setState(() => _risultati = risultati);
      }
    } catch (_) {
      // ricerca best-effort: se il backend non risponde lasciamo la lista com'e'
    }
  }

  void _seleziona(Player player) {
    if (widget.selezionati.any((p) => p.id == player.id)) return;
    widget.onAggiungi(player);
    setState(() {
      _risultati = [];
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(widget.titolo),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Cerca giocatore',
          ),
          onChanged: _cerca,
        ),
        for (final p in _risultati)
          ListTile(
            dense: true,
            leading: RoleAvatar(ruolo: p.ruoloClassic),
            title: Text(p.nome),
            subtitle: Text('${p.team.nome} · FVM ${p.fvm ?? '-'}'),
            onTap: () => _seleziona(p),
          ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          children: [
            for (final p in widget.selezionati)
              Chip(
                avatar: RoleAvatar(ruolo: p.ruoloClassic, radius: 12),
                label: Text(p.nome),
                onDeleted: () => widget.onRimuovi(p),
              ),
          ],
        ),
      ],
    );
  }
}

class _RisultatoScambio extends StatelessWidget {
  const _RisultatoScambio({required this.risultato});

  final ScambioRisultato risultato;

  VerdictTone get _tono {
    switch (risultato.verdetto) {
      case 'FAVOREVOLE':
        return VerdictTone.positive;
      case 'SFAVOREVOLE':
        return VerdictTone.negative;
      default:
        return VerdictTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentualeTesto = '${(risultato.percentuale * 100).toStringAsFixed(1)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VerdictBadge(label: '${risultato.verdetto} ($percentualeTesto)', tone: _tono),
            const SizedBox(height: AppSpacing.sm),
            Text('Valore dato: ${risultato.totaleDato} · Valore ricevuto: ${risultato.totaleRicevuto}'),
            if (risultato.nessunaStatisticaDisponibile) ...[
              const SizedBox(height: 8),
              Text(
                'Nessuno dei giocatori ha ancora statistiche di rendimento importate: '
                'la valutazione si basa solo su valore e andamento quotazione.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
            const Divider(),
            Text('Dai', style: Theme.of(context).textTheme.labelLarge),
            for (final d in risultato.dettaglioDati) _RigaDettaglio(dettaglio: d),
            const SizedBox(height: 12),
            Text('Ricevi', style: Theme.of(context).textTheme.labelLarge),
            for (final d in risultato.dettaglioRicevuti) _RigaDettaglio(dettaglio: d),
          ],
        ),
      ),
    );
  }
}

class _RigaDettaglio extends StatelessWidget {
  const _RigaDettaglio({required this.dettaglio});

  final DettaglioGiocatoreScambio dettaglio;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(dettaglio.nome),
      subtitle: Text(
        'base ${dettaglio.valoreBase} · forma ${dettaglio.fattoreForma.toStringAsFixed(2)}x '
        '· trend ${dettaglio.fattoreTrend.toStringAsFixed(2)}x',
      ),
      trailing: Text('${dettaglio.valoreScambio}'),
    );
  }
}
