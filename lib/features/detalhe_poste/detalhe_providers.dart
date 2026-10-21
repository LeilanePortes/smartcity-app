import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/smartcity_api.dart';
import '../../shared/models/models.dart';

/// Detalhe do poste (`GET /postes/:id`). Recarregável para refletir o `PATCH`
/// de status e, na fase 5, os empurrões do WebSocket.
final posteDetalheProvider =
    FutureProvider.autoDispose.family<Poste, String>((ref, id) async {
  final api = ref.watch(smartcityApiProvider);
  return api.detalhePoste(id);
});

/// Período selecionado no histórico de consumo (Hoje / Semana / Mês).
class TelemetriaPeriodoNotifier extends Notifier<PeriodoTelemetria> {
  @override
  PeriodoTelemetria build() => PeriodoTelemetria.hoje;

  void ir(PeriodoTelemetria p) => state = p;
}

final telemetriaPeriodoProvider =
    NotifierProvider<TelemetriaPeriodoNotifier, PeriodoTelemetria>(
        TelemetriaPeriodoNotifier.new);

/// Histórico de consumo do poste (`GET /postes/:id/telemetria`), reagindo ao
/// período selecionado.
final telemetriaProvider = FutureProvider.autoDispose
    .family<TelemetriaHistorico, String>((ref, id) async {
  final periodo = ref.watch(telemetriaPeriodoProvider);
  final api = ref.watch(smartcityApiProvider);
  return api.telemetria(id, periodo: periodo);
});

/// Log de eventos do sensor 360° (`GET /postes/:id/eventos`): a 1ª página,
/// com os 50 mais recentes (ordem padrão do backend) e o `total` do poste.
final eventosProvider = FutureProvider.autoDispose
    .family<Pagina<EventoSensor>, String>((ref, id) async {
  final api = ref.watch(smartcityApiProvider);
  return api.eventos(id, tamanho: 50);
});

/// Aplica o `PATCH /postes/:id/status` e recarrega as fontes afetadas.
/// A UI cuida do estado de carregamento local do botão.
Future<Poste> alterarStatusPoste(
  WidgetRef ref,
  String id,
  StatusPoste alvo,
) async {
  final api = ref.read(smartcityApiProvider);
  final atualizado = await api.alterarStatus(id, alvo);
  ref.invalidate(posteDetalheProvider(id));
  ref.invalidate(telemetriaProvider(id));
  ref.invalidate(eventosProvider(id));
  return atualizado;
}
