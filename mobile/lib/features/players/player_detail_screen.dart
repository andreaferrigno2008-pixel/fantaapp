import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/player.dart';

class PlayerDetailScreen extends ConsumerStatefulWidget {
  const PlayerDetailScreen({super.key, required this.playerId});

  final String playerId;

  @override
  ConsumerState<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends ConsumerState<PlayerDetailScreen> {
  Player? _player;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final player =
          await ref.read(playersRepositoryProvider).fetchPlayerDetail(widget.playerId);
      setState(() => _player = player);
    } catch (_) {
      setState(() => _error = 'Impossibile caricare il dettaglio: dato non disponibile offline');
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    return Scaffold(
      appBar: AppBar(title: Text(player?.nome ?? 'Dettaglio giocatore')),
      body: _error != null
          ? Center(child: Text(_error!))
          : player == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Row(
                      children: [
                        RoleAvatar(ruolo: player.ruoloClassic, radius: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(player.team.nome, style: Theme.of(context).textTheme.titleMedium),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatTile(label: 'Quot. attuale', value: '${player.quotazioneAttuale}'),
                            StatTile(label: 'Quot. iniziale', value: '${player.quotazioneIniziale}'),
                            if (player.fvm != null) StatTile(label: 'FVM', value: '${player.fvm}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader('Storico quotazioni'),
                    if (player.quotazioni.isEmpty)
                      const EmptyState(icon: Icons.show_chart, message: 'Nessuno storico disponibile')
                    else
                      Card(
                        child: Column(
                          children: [
                            for (final q in player.quotazioni)
                              ListTile(
                                dense: true,
                                title: Text('${q.data.day}/${q.data.month}/${q.data.year}'),
                                trailing: Text(
                                  '${q.valore}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader('Statistiche per giornata'),
                    if (player.statistiche.isEmpty)
                      const EmptyState(
                        icon: Icons.bar_chart,
                        message: 'Nessuna statistica disponibile ancora',
                      )
                    else
                      Card(
                        child: Column(
                          children: [
                            for (final s in player.statistiche)
                              ListTile(
                                dense: true,
                                title: Text('Giornata ${s.giornata}'),
                                subtitle: Text('Gol: ${s.gol} - Assist: ${s.assist}'),
                                trailing: Text(
                                  s.fantavoto?.toStringAsFixed(1) ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
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
