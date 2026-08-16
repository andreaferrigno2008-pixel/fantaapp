import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/calendario_giornata.dart';

class CalendarioScreen extends ConsumerStatefulWidget {
  const CalendarioScreen({super.key});

  @override
  ConsumerState<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends ConsumerState<CalendarioScreen> {
  final _stagioneController = TextEditingController(text: '2026-27');
  final _giornataController = TextEditingController();
  final _avversarioController = TextEditingController();

  List<CalendarioGiornata> _giornate = [];
  bool _loading = true;
  bool _salvando = false;
  String? _errore;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    setState(() => _loading = true);
    try {
      final giornate = await ref
          .read(calendarioRepositoryProvider)
          .fetchCalendario(stagione: _stagioneController.text.trim());
      setState(() {
        _giornate = giornate;
        _errore = null;
      });
    } catch (_) {
      setState(() => _errore = 'Impossibile caricare il calendario: backend non raggiungibile');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salva() async {
    final giornata = int.tryParse(_giornataController.text.trim());
    final avversario = _avversarioController.text.trim();
    if (giornata == null || avversario.isEmpty) {
      setState(() => _errore = 'Inserisci giornata e avversario');
      return;
    }
    setState(() {
      _salvando = true;
      _errore = null;
    });
    try {
      await ref.read(calendarioRepositoryProvider).salvaGiornata(
            stagione: _stagioneController.text.trim(),
            giornata: giornata,
            avversario: avversario,
          );
      _giornataController.clear();
      _avversarioController.clear();
      await _carica();
    } catch (_) {
      setState(() => _errore = 'Impossibile salvare la giornata');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _elimina(CalendarioGiornata g) async {
    try {
      await ref.read(calendarioRepositoryProvider).eliminaGiornata(g.id);
      await _carica();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Impossibile eliminare la giornata')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario lega')),
      body: RefreshIndicator(
        onRefresh: _carica,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SectionHeader(
              'Avversari per giornata',
              subtitle: 'Dati della tua lega privata su leghe.fantacalcio.it: nessuna fonte '
                  'pubblica li conosce, vanno inseriti a mano copiandoli dal sito.',
            ),
            TextField(
              controller: _stagioneController,
              decoration: const InputDecoration(labelText: 'Stagione (es. 2026-27)'),
              onSubmitted: (_) => _carica(),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _giornataController,
                    decoration: const InputDecoration(labelText: 'Giornata'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _avversarioController,
                    decoration: const InputDecoration(labelText: 'Avversario'),
                    onSubmitted: (_) => _salva(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _salvando ? null : _salva,
              child: _salvando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salva giornata'),
            ),
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.md),
              StatusBanner(message: _errore!, type: StatusBannerType.error),
            ],
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_giornate.isEmpty)
              const EmptyState(
                icon: Icons.calendar_month,
                message: 'Nessuna giornata inserita ancora',
              )
            else
              Card(
                child: Column(
                  children: [
                    for (final g in _giornate)
                      ListTile(
                        leading: CircleAvatar(child: Text('${g.giornata}')),
                        title: Text(g.avversario),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _elimina(g),
                        ),
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
