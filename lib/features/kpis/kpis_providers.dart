import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/smartcity_api.dart';
import '../../shared/models/models.dart';

/// Período do dashboard (Dia / Semana / Mês / Ano — PRD §5.3).
class KpiPeriodoNotifier extends Notifier<PeriodoKpi> {
  @override
  PeriodoKpi build() => PeriodoKpi.mes;

  void ir(PeriodoKpi p) => state = p;
}

final kpiPeriodoProvider =
    NotifierProvider<KpiPeriodoNotifier, PeriodoKpi>(KpiPeriodoNotifier.new);

/// `GET /kpis` — consumo, custo, variação e série comparativa.
final kpisProvider = FutureProvider.autoDispose<KpisResumo>((ref) async {
  final periodo = ref.watch(kpiPeriodoProvider);
  final api = ref.watch(smartcityApiProvider);
  return api.kpis(periodo: periodo);
});

/// `GET /kpis/maior-consumo` — ranking dos 5 postes de maior consumo.
final maiorConsumoProvider =
    FutureProvider.autoDispose<RankingConsumo>((ref) async {
  final periodo = ref.watch(kpiPeriodoProvider);
  final api = ref.watch(smartcityApiProvider);
  return api.maiorConsumo(periodo: periodo, tamanho: 5);
});

/// `GET /kpis/postes-por-status` — distribuição da rede (sem período).
final postesPorStatusProvider =
    FutureProvider.autoDispose<PostesPorStatus>((ref) async {
  final api = ref.watch(smartcityApiProvider);
  return api.postesPorStatus();
});
