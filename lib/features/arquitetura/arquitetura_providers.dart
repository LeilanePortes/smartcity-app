import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/smartcity_api.dart';
import '../../shared/models/models.dart';
import '../shell/shell_providers.dart';

/// Intervalo de consulta enquanto a aba está visível. O fog fecha uma janela a
/// cada 60 s; 12 s mostra a virada do minuto sem atraso perceptível.
const Duration kIntervaloArquitetura = Duration(seconds: 12);

/// `GET /arquitetura` — estado das camadas edge · fog · nuvem.
final arquiteturaProvider =
    FutureProvider.autoDispose<EstadoArquitetura>((ref) async {
  final api = ref.watch(smartcityApiProvider);
  return api.arquitetura();
});

/// `true` quando a aba Arquitetura está selecionada. As abas ficam vivas no
/// `IndexedStack`, então é isto que liga/desliga a consulta periódica.
final arquiteturaVisivelProvider = Provider<bool>((ref) {
  return ref.watch(homeTabProvider) == HomeTab.arquitetura;
});
