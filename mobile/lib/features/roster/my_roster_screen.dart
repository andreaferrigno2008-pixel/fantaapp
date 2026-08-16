import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/formazione_titolare_risultato.dart';
import '../../data/models/player.dart';
import '../../data/models/rosa_entry.dart';

const _ordineRuoli = ['P', 'D', 'C', 'A'];

class MyRosterScreen extends ConsumerStatefulWidget {
  const MyRosterScreen({super.key});

  @override
  ConsumerState<MyRosterScreen> createState() => _MyRosterScreenState();
}

class _MyRosterScreenState extends ConsumerState<MyRosterScreen> {
  List<RosaEntry> _rosa = [];
  bool _loading = true;
  String? _errore;

  final _searchController = TextEditingController();
  List<Player> _risultatiRicerca = [];
  int _ricercaInCorso = 0;

  bool _generandoFormazione = false;
  FormazioneTitolareRisultato? _formazione;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    setState(() => _loading = true);
    try {
      final rosa = await ref.read(rosaRepositoryProvider).getRosa();
      setState(() {
        _rosa = rosa;
        _errore = null;
      });
    } catch (_) {
      setState(() => _errore = 'Impossibile caricare la rosa: backend non raggiungibile');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cerca(String query) async {
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

  Future<void> _aggiungi(Player player) async {
    setState(() {
      _risultatiRicerca = [];
      _searchController.clear();
    });
    try {
      await ref.read(rosaRepositoryProvider).aggiungiGiocatore(player.id);
      await _carica();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aggiungere: già in rosa?')),
        );
      }
    }
  }

  Future<void> _rimuovi(RosaEntry entry) async {
    try {
      await ref.read(rosaRepositoryProvider).rimuoviGiocatore(entry.player.id);
      await _carica();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Impossibile rimuovere il giocatore')));
      }
    }
  }

  Future<void> _generaFormazione() async {
    setState(() => _generandoFormazione = true);
    try {
      final risultato = await ref.read(rosaRepositoryProvider).getFormazioneTitolare();
      setState(() => _formazione = risultato);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile generare la formazione: servono più giocatori?')),
        );
      }
    } finally {
      if (mounted) setState(() => _generandoFormazione = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('La mia squadra')),
      body: _loading && _rosa.isEmpty && _errore == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (_errore != null) ...[
                  StatusBanner(message: _errore!, type: StatusBannerType.error),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SectionHeader('Cerca giocatore da aggiungere'),
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
                    onTap: () => _aggiungi(p),
                  ),
                const Divider(),
                SectionHeader('Rosa (${_rosa.length})'),
                if (_rosa.isEmpty)
                  const EmptyState(
                    icon: Icons.shield_outlined,
                    message: 'Nessun giocatore in rosa. Cercalo qui sopra per aggiungerlo.',
                  )
                else
                  Card(
                    child: Column(
                      children: [
                        for (final entry in _rosa)
                          ListTile(
                            dense: true,
                            leading: RoleAvatar(ruolo: entry.player.ruoloClassic),
                            title: Text(entry.player.nome),
                            subtitle: Text(entry.player.team.nome),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _rimuovi(entry),
                            ),
                          ),
                      ],
                    ),
                  ),
                const Divider(),
                const SectionHeader(
                  'Formazione titolare consigliata',
                  subtitle: 'Basata sul rendimento recente dei tuoi giocatori (media fantavoto). '
                      'Non tiene ancora conto del calendario/avversari.',
                ),
                const SizedBox(height: AppSpacing.xs),
                FilledButton(
                  onPressed: _generandoFormazione ? null : _generaFormazione,
                  child: _generandoFormazione
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Consiglia formazione'),
                ),
                if (_formazione != null) ...[
                  const SizedBox(height: 16),
                  _RisultatoFormazioneTitolare(risultato: _formazione!),
                ],
              ],
            ),
    );
  }
}

class _RisultatoFormazioneTitolare extends StatelessWidget {
  const _RisultatoFormazioneTitolare({required this.risultato});

  final FormazioneTitolareRisultato risultato;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modulo: ${risultato.modulo}', style: Theme.of(context).textTheme.titleMedium),
            if (risultato.warning.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final w in risultato.warning)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber, size: 18, color: Theme.of(context).colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(w, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
            ],
            const Divider(),
            for (final ruolo in _ordineRuoli)
              if ((risultato.titolari[ruolo] ?? []).isNotEmpty) ...[
                Text(ruolo, style: Theme.of(context).textTheme.labelLarge),
                for (final g in risultato.titolari[ruolo]!)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(g.nome),
                    trailing: Text(
                      g.valoreForma.toStringAsFixed(1) + (g.formaReale ? '' : ' (stimato)'),
                    ),
                  ),
              ],
            if (risultato.panchina.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Panchina', style: Theme.of(context).textTheme.labelLarge),
              Text(
                risultato.panchina.map((g) => g.nome).join(', '),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
