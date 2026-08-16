import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'asta_live_screen.dart';
import 'asta_provider.dart';
import 'asta_setup_screen.dart';

// Entry point della sezione Asta: mostra il setup se non c'e' un'asta
// attiva, altrimenti la schermata live — la scelta segue astaIdProvider,
// persistito localmente cosi' l'app riprende da dove si era.
class AstaScreen extends ConsumerWidget {
  const AstaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final astaId = ref.watch(astaIdProvider);
    if (astaId == null) return const AstaSetupScreen();
    return AstaLiveScreen(astaId: astaId);
  }
}
