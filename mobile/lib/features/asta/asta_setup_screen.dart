import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import 'asta_provider.dart';

class AstaSetupScreen extends ConsumerStatefulWidget {
  const AstaSetupScreen({super.key});

  @override
  ConsumerState<AstaSetupScreen> createState() => _AstaSetupScreenState();
}

class _AstaSetupScreenState extends ConsumerState<AstaSetupScreen> {
  final _budgetController = TextEditingController(text: '500');
  final _slotPController = TextEditingController(text: '3');
  final _slotDController = TextEditingController(text: '8');
  final _slotCController = TextEditingController(text: '8');
  final _slotAController = TextEditingController(text: '6');
  final _nuovoAvversarioController = TextEditingController();
  final List<String> _avversari = [];
  bool _creando = false;
  String? _errore;

  void _aggiungiAvversario() {
    final nome = _nuovoAvversarioController.text.trim();
    if (nome.isEmpty || _avversari.contains(nome)) return;
    setState(() {
      _avversari.add(nome);
      _nuovoAvversarioController.clear();
    });
  }

  Future<String> _resolveSeason() async {
    return await ref.read(playersRepositoryProvider).fetchCurrentSeason() ?? '2026-27';
  }

  String _describeError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['error'] is String) {
        return data['error'] as String;
      }
    }
    return 'backend non raggiungibile';
  }

  Future<void> _avviaAsta() async {
    setState(() {
      _creando = true;
      _errore = null;
    });
    try {
      final asta = await ref.read(astaRepositoryProvider).creaAsta(
            stagione: await _resolveSeason(),
            budgetTotale: int.tryParse(_budgetController.text) ?? 500,
            slotP: int.tryParse(_slotPController.text) ?? 3,
            slotD: int.tryParse(_slotDController.text) ?? 8,
            slotC: int.tryParse(_slotCController.text) ?? 8,
            slotA: int.tryParse(_slotAController.text) ?? 6,
            avversari: _avversari,
          );
      await ref.read(astaIdProvider.notifier).set(asta.id);
    } catch (error) {
      setState(() => _errore = "Impossibile creare l'asta: ${_describeError(error)}");
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuova asta')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextField(
            controller: _budgetController,
            decoration: const InputDecoration(labelText: 'Budget totale'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('Slot per ruolo'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _slotPController,
                  decoration: const InputDecoration(labelText: 'P'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _slotDController,
                  decoration: const InputDecoration(labelText: 'D'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _slotCController,
                  decoration: const InputDecoration(labelText: 'C'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _slotAController,
                  decoration: const InputDecoration(labelText: 'A'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            'Avversari',
            subtitle: "Inserisci i nomi di chi partecipa all'asta oltre a te: durante l'asta "
                "selezionerai l'acquirente da questo elenco, senza doverlo digitare.",
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nuovoAvversarioController,
                  decoration: const InputDecoration(labelText: 'Nome avversario'),
                  onSubmitted: (_) => _aggiungiAvversario(),
                ),
              ),
              IconButton(icon: const Icon(Icons.add_circle), onPressed: _aggiungiAvversario),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            children: [
              for (final nome in _avversari)
                Chip(
                  label: Text(nome),
                  onDeleted: () => setState(() => _avversari.remove(nome)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_errore != null) ...[
            StatusBanner(message: _errore!, type: StatusBannerType.error),
            const SizedBox(height: AppSpacing.md),
          ],
          FilledButton(
            onPressed: _creando ? null : _avviaAsta,
            child: _creando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Avvia asta'),
          ),
        ],
      ),
    );
  }
}
