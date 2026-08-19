import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/player.dart';
import 'formazione_risultato_screen.dart';

class FormazioneSetupScreen extends ConsumerStatefulWidget {
  const FormazioneSetupScreen({super.key});

  @override
  ConsumerState<FormazioneSetupScreen> createState() => _FormazioneSetupScreenState();
}

class _FormazioneSetupScreenState extends ConsumerState<FormazioneSetupScreen> {
  final _budgetController = TextEditingController(text: '500');
  final _slotPController = TextEditingController(text: '3');
  final _slotDController = TextEditingController(text: '8');
  final _slotCController = TextEditingController(text: '8');
  final _slotAController = TextEditingController(text: '6');

  final _searchController = TextEditingController();
  List<Player> _risultatiRicerca = [];
  int _ricercaInCorso = 0;
  final List<Player> _obiettivi = [];

  bool _generando = false;
  String? _errore;

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

  void _aggiungiObiettivo(Player player) {
    if (_obiettivi.any((p) => p.id == player.id)) return;
    setState(() {
      _obiettivi.add(player);
      _risultatiRicerca = [];
      _searchController.clear();
    });
  }

  Future<String> _resolveSeason() async {
    if (_obiettivi.isNotEmpty) return _obiettivi.first.stagione;
    return await ref.read(playersRepositoryProvider).fetchCurrentSeason() ?? '2026-27';
  }

  String _describeError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['error'] is String) {
        return data['error'] as String;
      }
    }
    return 'verifica budget e obiettivi';
  }

  Future<void> _generaFormazione() async {
    setState(() {
      _generando = true;
      _errore = null;
    });
    try {
      final risultato = await ref.read(formazioneRepositoryProvider).genera(
            stagione: await _resolveSeason(),
            budgetTotale: int.tryParse(_budgetController.text) ?? 500,
            slotP: int.tryParse(_slotPController.text) ?? 3,
            slotD: int.tryParse(_slotDController.text) ?? 8,
            slotC: int.tryParse(_slotCController.text) ?? 8,
            slotA: int.tryParse(_slotAController.text) ?? 6,
            obiettiviPlayerIds: _obiettivi.map((p) => p.id).toList(),
          );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FormazioneRisultatoScreen(risultato: risultato)),
        );
      }
    } catch (error) {
      setState(() => _errore = 'Impossibile generare la formazione: ${_describeError(error)}');
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formazione ottimale')),
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
            'Giocatori obiettivo',
            subtitle:
                'Opzionale: i giocatori che scegli qui saranno sempre inclusi nella formazione proposta.',
          ),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cerca giocatore',
            ),
            onChanged: _cerca,
          ),
          for (final p in _risultatiRicerca)
            ListTile(
              dense: true,
              leading: RoleAvatar(ruolo: p.ruoloClassic),
              title: Text(p.nome),
              subtitle: Text('${p.team.nome} · FVM ${p.fvm ?? '-'}'),
              onTap: () => _aggiungiObiettivo(p),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            children: [
              for (final p in _obiettivi)
                Chip(
                  avatar: RoleAvatar(ruolo: p.ruoloClassic, radius: 12),
                  label: Text(p.nome),
                  onDeleted: () => setState(() => _obiettivi.remove(p)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_errore != null) ...[
            StatusBanner(message: _errore!, type: StatusBannerType.error),
            const SizedBox(height: AppSpacing.md),
          ],
          FilledButton(
            onPressed: _generando ? null : _generaFormazione,
            child: _generando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Genera formazione'),
          ),
        ],
      ),
    );
  }
}
