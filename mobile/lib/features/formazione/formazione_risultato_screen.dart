import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/formazione_risultato.dart';

const _ordineRuoli = ['P', 'D', 'C', 'A'];

class FormazioneRisultatoScreen extends StatelessWidget {
  const FormazioneRisultatoScreen({super.key, required this.risultato});

  final FormazioneRisultato risultato;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formazione proposta')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatTile(label: 'Budget speso', value: '${risultato.budgetSpeso}/${risultato.budgetTotale}'),
                  StatTile(label: 'Budget residuo', value: '${risultato.budgetResiduo}'),
                  StatTile(label: 'FVM totale', value: '${risultato.fvmTotale}'),
                ],
              ),
            ),
          ),
          if (risultato.warning.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            StatusBanner(
              type: StatusBannerType.warning,
              message: risultato.warning.join('\n'),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          for (final ruolo in _ordineRuoli)
            if ((risultato.formazione[ruolo] ?? []).isNotEmpty) ...[
              SectionHeader(ruolo),
              Card(
                child: Column(
                  children: [
                    for (final p in risultato.formazione[ruolo]!)
                      ListTile(
                        dense: true,
                        leading: RoleAvatar(ruolo: p.ruoloClassic),
                        title: Text(p.nome),
                        subtitle: Text(p.team.nome),
                        trailing: Text(
                          '${p.quotazioneAttuale}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}
