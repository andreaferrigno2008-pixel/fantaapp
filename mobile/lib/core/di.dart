import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/local_cache.dart';
import '../data/repositories/asta_repository.dart';
import '../data/repositories/formazione_repository.dart';
import '../data/repositories/players_repository.dart';
import '../data/repositories/rosa_repository.dart';
import '../data/repositories/scambio_repository.dart';
import '../data/repositories/sync_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final localCacheProvider = Provider<LocalCache>((ref) => LocalCache());

final playersRepositoryProvider = Provider<PlayersRepository>(
  (ref) => PlayersRepository(ref.watch(apiClientProvider)),
);

final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => SyncRepository(ref.watch(apiClientProvider)),
);

final astaRepositoryProvider = Provider<AstaRepository>(
  (ref) => AstaRepository(ref.watch(apiClientProvider)),
);

final formazioneRepositoryProvider = Provider<FormazioneRepository>(
  (ref) => FormazioneRepository(ref.watch(apiClientProvider)),
);

final scambioRepositoryProvider = Provider<ScambioRepository>(
  (ref) => ScambioRepository(ref.watch(apiClientProvider)),
);

final rosaRepositoryProvider = Provider<RosaRepository>(
  (ref) => RosaRepository(ref.watch(apiClientProvider)),
);
