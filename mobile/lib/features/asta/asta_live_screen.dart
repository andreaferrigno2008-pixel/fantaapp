import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/asta.dart';
import '../../data/models/asta_partecipante.dart';
import '../../data/models/consiglio_asta.dart';
import '../../data/models/player.dart';
import 'asta_provider.dart';

class AstaLiveScreen extends ConsumerStatefulWidget {
  const AstaLiveScreen({super.key, required this.astaId});

  final String astaId;

  @override
  ConsumerState<AstaLiveScreen> createState() => _AstaLiveScreenState();
}

class _AstaLiveScreenState extends ConsumerState<AstaLiveScreen> {
  Asta? _asta;
  bool _loading = true;
  String? _errore;

  final _searchController = TextEditingController();
  List<Player> _risultatiRicerca = [];
  Player? _giocatoreSelezionato;
  int _ricercaInCorso = 0;

  final _prezzoAttualeController = TextEditingController();
  ConsiglioAsta? _consiglio;
  bool _caricandoConsiglio = false;

  AstaPartecipante? _acquirenteSelezionato;
  final _prezzoFinaleController = TextEditingController();
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    _ricaricaAsta();
  }

  Future<void> _ricaricaAsta() async {
    setState(() => _loading = true);
    try {
      final asta = await ref.read(astaRepositoryProvider).getAsta(widget.astaId);
      setState(() {
        _asta = asta;
        _errore = null;
      });
    } catch (_) {
      setState(() => _errore = 'Impossibile caricare lo stato asta: backend non raggiungibile');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cerca(String query) async {
    // Ogni chiamata ha un token progressivo: le risposte di rete possono
    // arrivare in un ordine diverso da quello delle richieste (es. la
    // risposta per "L" arriva dopo quella per "Lautaro"), quindi si
    // applica solo il risultato della ricerca piu' recente.
    final richiesta = ++_ricercaInCorso;

    if (query.trim().length < 2) {
      setState(() => _risultatiRicerca = []);
      return;
    }
    try {
      final risultati = await ref.read(playersRepositoryProvider).fetchPlayers(search: query);
      if (richiesta == _ricercaInCorso) {
        setState(() => _risultatiRicerca = risultati);
      }
    } catch (_) {
      // ricerca best-effort: se il backend non risponde lasciamo la lista com'e'
    }
  }

  void _selezionaGiocatore(Player player) {
    setState(() {
      _giocatoreSelezionato = player;
      _risultatiRicerca = [];
      _searchController.text = player.nome;
      _consiglio = null;
      _acquirenteSelezionato = null;
      _prezzoFinaleController.clear();
    });
  }

  Future<void> _chiediConsiglio() async {
    final player = _giocatoreSelezionato;
    final prezzo = int.tryParse(_prezzoAttualeController.text);
    if (player == null || prezzo == null) return;

    setState(() => _caricandoConsiglio = true);
    try {
      final consiglio = await ref.read(astaRepositoryProvider).getConsiglio(
            astaId: widget.astaId,
            playerId: player.id,
            prezzoAttuale: prezzo,
          );
      setState(() => _consiglio = consiglio);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile calcolare il consiglio')),
        );
      }
    } finally {
      if (mounted) setState(() => _caricandoConsiglio = false);
    }
  }

  Future<void> _registraAssegnazione() async {
    final player = _giocatoreSelezionato;
    final acquirente = _acquirenteSelezionato;
    final prezzo = int.tryParse(_prezzoFinaleController.text);
    if (player == null || acquirente == null || prezzo == null) return;

    setState(() => _registrando = true);
    try {
      await ref.read(astaRepositoryProvider).registraPick(
            astaId: widget.astaId,
            playerId: player.id,
            partecipanteId: acquirente.id,
            prezzo: prezzo,
          );
      setState(() {
        _giocatoreSelezionato = null;
        _consiglio = null;
        _acquirenteSelezionato = null;
        _searchController.clear();
        _prezzoAttualeController.clear();
        _prezzoFinaleController.clear();
      });
      await _ricaricaAsta();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile registrare: giocatore già assegnato?')),
        );
      }
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  Future<void> _eliminaPick(String pickId) async {
    try {
      await ref.read(astaRepositoryProvider).eliminaPick(astaId: widget.astaId, pickId: pickId);
      await _ricaricaAsta();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Impossibile annullare il pick')));
      }
    }
  }

  Future<void> _terminaAsta() async {
    await ref.read(astaIdProvider.notifier).set(null);
  }

  @override
  Widget build(BuildContext context) {
    final asta = _asta;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asta in corso'),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Rose partecipanti',
            onPressed: () => context.push('/asta/${widget.astaId}/rose'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _ricaricaAsta),
          IconButton(icon: const Icon(Icons.stop_circle_outlined), onPressed: _terminaAsta),
        ],
      ),
      body: _loading && asta == null
          ? const Center(child: CircularProgressIndicator())
          : _errore != null && asta == null
              ? Center(child: Text(_errore!))
              : asta == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        _RiepilogoAsta(asta: asta),
                        const Divider(),
                        const SectionHeader('Cerca giocatore'),
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Nome giocatore',
                          ),
                          onChanged: _cerca,
                        ),
                        for (final p in _risultatiRicerca)
                          ListTile(
                            dense: true,
                            leading: RoleAvatar(ruolo: p.ruoloClassic),
                            title: Text(p.nome),
                            subtitle: Text('${p.team.nome} · FVM ${p.fvm ?? '-'}'),
                            onTap: () => _selezionaGiocatore(p),
                          ),
                        if (_giocatoreSelezionato != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _SezioneConsiglio(
                            giocatore: _giocatoreSelezionato!,
                            prezzoAttualeController: _prezzoAttualeController,
                            consiglio: _consiglio,
                            caricando: _caricandoConsiglio,
                            onChiediConsiglio: _chiediConsiglio,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _SezioneRegistraAssegnazione(
                            partecipanti: asta.partecipanti,
                            acquirenteSelezionato: _acquirenteSelezionato,
                            onAcquirenteSelezionato: (p) =>
                                setState(() => _acquirenteSelezionato = p),
                            prezzoFinaleController: _prezzoFinaleController,
                            registrando: _registrando,
                            onRegistra: _registraAssegnazione,
                          ),
                        ],
                        const Divider(),
                        const SectionHeader('Picks recenti'),
                        if (asta.picks.isEmpty)
                          const EmptyState(
                            icon: Icons.gavel,
                            message: 'Nessuna assegnazione registrata ancora',
                          )
                        else
                          Card(
                            child: Column(
                              children: [
                                for (final pick in asta.picks.reversed.take(15))
                                  ListTile(
                                    dense: true,
                                    leading: RoleAvatar(ruolo: pick.player.ruoloClassic),
                                    title: Text(pick.player.nome),
                                    subtitle: Text(pick.partecipante.nome),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${pick.prezzo}',
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.undo, size: 18),
                                          onPressed: () => _eliminaPick(pick.id),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }
}

class _RiepilogoAsta extends StatelessWidget {
  const _RiepilogoAsta({required this.asta});

  final Asta asta;

  @override
  Widget build(BuildContext context) {
    final slot = asta.slotResidui;
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget residuo',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
            Text(
              '${asta.budgetResiduo ?? asta.budgetTotale}',
              style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (slot != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                children: [
                  for (final ruolo in const ['P', 'D', 'C', 'A'])
                    Text(
                      '$ruolo: ${slot[ruolo]}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SezioneConsiglio extends StatelessWidget {
  const _SezioneConsiglio({
    required this.giocatore,
    required this.prezzoAttualeController,
    required this.consiglio,
    required this.caricando,
    required this.onChiediConsiglio,
  });

  final Player giocatore;
  final TextEditingController prezzoAttualeController;
  final ConsiglioAsta? consiglio;
  final bool caricando;
  final VoidCallback onChiediConsiglio;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${giocatore.nome} — a quanto siamo?', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: prezzoAttualeController,
                    decoration: const InputDecoration(labelText: 'Prezzo attuale asta'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: caricando ? null : onChiediConsiglio,
                  child: const Text('Consiglio'),
                ),
              ],
            ),
            if (consiglio != null) ...[
              const SizedBox(height: 12),
              VerdictBadge(
                tone: consiglio!.isRilancia ? VerdictTone.positive : VerdictTone.negative,
                icon: consiglio!.isRilancia ? Icons.trending_up : Icons.block,
                label: consiglio!.isRilancia
                    ? 'RILANCIA (fino a ${consiglio!.prezzoMassimoConsigliato})'
                    : 'ABBANDONA (max consigliato ${consiglio!.prezzoMassimoConsigliato})',
              ),
              const SizedBox(height: 8),
              Text(consiglio!.motivazione, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _SezioneRegistraAssegnazione extends StatelessWidget {
  const _SezioneRegistraAssegnazione({
    required this.partecipanti,
    required this.acquirenteSelezionato,
    required this.onAcquirenteSelezionato,
    required this.prezzoFinaleController,
    required this.registrando,
    required this.onRegistra,
  });

  final List<AstaPartecipante> partecipanti;
  final AstaPartecipante? acquirenteSelezionato;
  final ValueChanged<AstaPartecipante> onAcquirenteSelezionato;
  final TextEditingController prezzoFinaleController;
  final bool registrando;
  final VoidCallback onRegistra;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registra assegnazione', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in partecipanti)
                  ChoiceChip(
                    label: Text(p.nome),
                    selected: acquirenteSelezionato?.id == p.id,
                    onSelected: (_) => onAcquirenteSelezionato(p),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: prezzoFinaleController,
                    decoration: const InputDecoration(labelText: 'Prezzo finale'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: registrando ? null : onRegistra,
                  child: const Text('Registra'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
