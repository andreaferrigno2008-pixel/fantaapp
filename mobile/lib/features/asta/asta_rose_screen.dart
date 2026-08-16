import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/asta.dart';
import '../../data/models/asta_partecipante.dart';
import '../../data/models/asta_pick.dart';

const _ordineRuoli = ['P', 'D', 'C', 'A'];

class AstaRoseScreen extends ConsumerStatefulWidget {
  const AstaRoseScreen({super.key, required this.astaId});

  final String astaId;

  @override
  ConsumerState<AstaRoseScreen> createState() => _AstaRoseScreenState();
}

class _AstaRoseScreenState extends ConsumerState<AstaRoseScreen> {
  Asta? _asta;
  bool _loading = true;
  String? _errore;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    setState(() => _loading = true);
    try {
      final asta = await ref.read(astaRepositoryProvider).getAsta(widget.astaId);
      setState(() {
        _asta = asta;
        _errore = null;
      });
    } catch (_) {
      setState(() => _errore = 'Impossibile caricare le rose: backend non raggiungibile');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asta = _asta;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rose partecipanti'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _carica)],
      ),
      body: _loading && asta == null
          ? const Center(child: CircularProgressIndicator())
          : _errore != null && asta == null
              ? Center(child: Text(_errore!))
              : asta == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _carica,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          for (final partecipante in _partecipantiOrdinati(asta.partecipanti))
                            _RosaPartecipante(
                              partecipante: partecipante,
                              picks: asta.picks
                                  .where((p) => p.partecipanteId == partecipante.id)
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
    );
  }

  List<AstaPartecipante> _partecipantiOrdinati(List<AstaPartecipante> partecipanti) {
    final copia = [...partecipanti];
    copia.sort((a, b) {
      if (a.sonIo != b.sonIo) return a.sonIo ? -1 : 1;
      return a.nome.compareTo(b.nome);
    });
    return copia;
  }
}

class _RosaPartecipante extends StatelessWidget {
  const _RosaPartecipante({required this.partecipante, required this.picks});

  final AstaPartecipante partecipante;
  final List<AstaPick> picks;

  @override
  Widget build(BuildContext context) {
    final speso = picks.fold<int>(0, (sum, p) => sum + p.prezzo);
    final perRuolo = {
      for (final ruolo in _ordineRuoli)
        ruolo: picks.where((p) => p.player.ruoloClassic == ruolo).toList(),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (partecipante.sonIo) ...[
                  const Icon(Icons.star, size: 18, color: Color(0xFFB8860B)),
                  const SizedBox(width: 4),
                ],
                Text(partecipante.nome, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  '$speso crediti',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(),
            if (picks.isEmpty)
              const EmptyState(icon: Icons.person_off_outlined, message: 'Nessun giocatore ancora')
            else
              for (final ruolo in _ordineRuoli)
                if (perRuolo[ruolo]!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 2),
                    child: Text(
                      ruolo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: RoleColors.of(ruolo),
                      ),
                    ),
                  ),
                  for (final pick in perRuolo[ruolo]!)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(pick.player.nome),
                      subtitle: Text(pick.player.team.nome),
                      trailing: Text('${pick.prezzo}'),
                    ),
                ],
          ],
        ),
      ),
    );
  }
}
