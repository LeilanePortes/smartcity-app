import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/smartcity_api.dart';
import '../../../shared/models/models.dart';

/// Consulta enquanto há implantação `EM_ANDAMENTO` (portões a cada 120 s; as
/// ondas e contadores mudam em segundos).
const Duration kIntervaloOtaAtivo = Duration(seconds: 5);

/// Consulta sem implantação em andamento.
const Duration kIntervaloOtaOcioso = Duration(seconds: 15);

/// Intervalo da próxima consulta conforme o último estado conhecido.
Duration intervaloOta(EstadoOta? estado) =>
    (estado?.emAndamento ?? false) ? kIntervaloOtaAtivo : kIntervaloOtaOcioso;

/// Estado da OTA (`GET /ota`) e as ações `POST /ota/implantacoes` e
/// `POST /ota/reverter`. As ações devolvem o mesmo corpo do GET, que vira o
/// estado na hora — sem esperar a próxima consulta. Erros (400/409) sobem como
/// `ApiException` para a UI mostrar e o estado não muda.
class OtaNotifier extends AsyncNotifier<EstadoOta> {
  @override
  Future<EstadoOta> build() => ref.watch(smartcityApiProvider).ota();

  Future<EstadoOta> iniciar(String versao) async {
    final novo = await ref.read(smartcityApiProvider).iniciarOta(versao);
    if (ref.mounted) state = AsyncData(novo);
    return novo;
  }

  Future<EstadoOta> reverter() async {
    final novo = await ref.read(smartcityApiProvider).reverterOta();
    if (ref.mounted) state = AsyncData(novo);
    return novo;
  }
}

final otaProvider =
    AsyncNotifierProvider.autoDispose<OtaNotifier, EstadoOta>(OtaNotifier.new);
