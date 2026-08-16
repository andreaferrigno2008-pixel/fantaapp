import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/player.dart';

class PlayersListScreen extends ConsumerStatefulWidget {
  const PlayersListScreen({super.key});

  @override
  ConsumerState<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends ConsumerState<PlayersListScreen> {
  List<Player> _players = [];
  bool _loading = true;
  bool _offline = false;
  String? _ruoloFilter;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = ref.read(playersRepositoryProvider);
    final cache = ref.read(localCacheProvider);
    try {
      final players = await repo.fetchPlayers();
      await cache.savePlayers(players);
      setState(() {
        _players = players;
        _offline = false;
      });
    } catch (_) {
      final cached = await cache.loadPlayers();
      setState(() {
        _players = cached;
        _offline = true;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Player> get _filtered {
    return _players.where((p) {
      final matchesRuolo = _ruoloFilter == null || p.ruoloClassic == _ruoloFilter;
      final matchesSearch =
          _search.isEmpty || p.nome.toLowerCase().contains(_search.toLowerCase());
      return matchesRuolo && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listone giocatori'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          if (_offline)
            const StatusBanner(message: "Modalità offline: dati dall'ultima sincronizzazione"),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cerca giocatore',
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Wrap(
              spacing: 8,
              children: [
                _RuoloChip(
                  label: 'Tutti',
                  selected: _ruoloFilter == null,
                  onSelected: () => setState(() => _ruoloFilter = null),
                ),
                for (final ruolo in const ['P', 'D', 'C', 'A'])
                  _RuoloChip(
                    label: ruolo,
                    selected: _ruoloFilter == ruolo,
                    onSelected: () => setState(() => _ruoloFilter = ruolo),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        message: 'Nessun giocatore trovato',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final player = _filtered[index];
                          return ListTile(
                            leading: RoleAvatar(ruolo: player.ruoloClassic),
                            title: Text(player.nome),
                            subtitle: Text(player.team.nome),
                            trailing: Text(
                              '${player.quotazioneAttuale}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            onTap: () => context.push('/players/${player.id}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _RuoloChip extends StatelessWidget {
  const _RuoloChip({required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onSelected());
  }
}
