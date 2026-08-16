import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/sync_run.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<SyncRun> _runs = [];
  DateTime? _lastLocalSync;
  bool _loading = true;
  String? _error;

  final _stagioneController = TextEditingController(text: '2026-27');
  final _giornataController = TextEditingController(text: '1');
  bool _sincronizzandoQuotazioni = false;
  bool _importandoVoti = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final runs = await ref.read(syncRepositoryProvider).fetchStatus();
      final lastLocal = await ref.read(localCacheProvider).lastSyncedAt();
      setState(() {
        _runs = runs;
        _lastLocalSync = lastLocal;
      });
    } catch (_) {
      setState(() => _error = 'Backend non raggiungibile');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshData() async {
    final repo = ref.read(playersRepositoryProvider);
    final cache = ref.read(localCacheProvider);
    try {
      final players = await repo.fetchPlayers();
      await cache.savePlayers(players);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Dati aggiornati')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aggiornare: backend non raggiungibile')),
        );
      }
    }
  }

  Future<void> _sincronizzaQuotazioniOnline() async {
    setState(() => _sincronizzandoQuotazioni = true);
    try {
      await ref
          .read(syncRepositoryProvider)
          .sincronizzaQuotazioniOnline(stagione: _stagioneController.text.trim());
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotazioni aggiornate da fantacalcio.it')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Sincronizzazione quotazioni fallita')));
      }
    } finally {
      if (mounted) setState(() => _sincronizzandoQuotazioni = false);
    }
  }

  Future<void> _importaVoti() async {
    final giornata = int.tryParse(_giornataController.text.trim());
    if (giornata == null) return;
    setState(() => _importandoVoti = true);
    try {
      await ref.read(syncRepositoryProvider).importaVoti(
            stagione: _stagioneController.text.trim(),
            giornata: giornata,
          );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Voti giornata $giornata importati')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Import voti fallito')));
      }
    } finally {
      if (mounted) setState(() => _importandoVoti = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: ListTile(
                title: const Text('Ultimo aggiornamento locale'),
                subtitle: Text(_lastLocalSync?.toString() ?? 'Mai sincronizzato'),
                trailing: FilledButton(onPressed: _refreshData, child: const Text('Aggiorna')),
              ),
            ),
            const Divider(),
            const SectionHeader('Dati reali (fantacalcio.it)'),
            TextField(
              controller: _stagioneController,
              decoration: const InputDecoration(labelText: 'Stagione (es. 2026-27)'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _sincronizzandoQuotazioni ? null : _sincronizzaQuotazioniOnline,
              child: _sincronizzandoQuotazioni
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Aggiorna quotazioni da fantacalcio.it'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _giornataController,
                    decoration: const InputDecoration(labelText: 'Giornata'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _importandoVoti ? null : _importaVoti,
                  child: _importandoVoti
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Importa voti'),
                ),
              ],
            ),
            const Divider(),
            const SectionHeader('Storico sincronizzazioni backend'),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null) StatusBanner(message: _error!, type: StatusBannerType.error),
            if (!_loading && _runs.isEmpty && _error == null)
              const EmptyState(icon: Icons.history, message: 'Nessuna sincronizzazione ancora')
            else
              Card(
                child: Column(
                  children: [
                    for (final run in _runs)
                      ListTile(
                        leading: Icon(
                          run.status == 'success'
                              ? Icons.check_circle
                              : run.status == 'error'
                                  ? Icons.error
                                  : Icons.hourglass_top,
                          color: run.status == 'success'
                              ? Theme.of(context).colorScheme.primary
                              : run.status == 'error'
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        title: Text(run.source),
                        subtitle: Text(run.startedAt.toString()),
                        trailing: Text(run.recordsCount != null ? '${run.recordsCount} record' : run.status),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
