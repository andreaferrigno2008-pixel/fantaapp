import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tiene traccia solo dell'id dell'asta attiva, persistito cosi' riaprendo
// l'app durante l'asta si riprende da dove si era. Lo stato completo
// dell'asta (picks, budget, ecc.) vive nella schermata live, che lo
// ricarica dal backend — stesso pattern gia' usato in Fase 1.
class AstaIdNotifier extends StateNotifier<String?> {
  AstaIdNotifier() : super(null) {
    _load();
  }

  static const _key = 'asta_attiva_id';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> set(String? astaId) async {
    state = astaId;
    final prefs = await SharedPreferences.getInstance();
    if (astaId == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, astaId);
    }
  }
}

final astaIdProvider = StateNotifierProvider<AstaIdNotifier, String?>(
  (ref) => AstaIdNotifier(),
);
