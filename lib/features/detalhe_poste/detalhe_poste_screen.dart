import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/realtime_providers.dart';
import '../../core/theme/brut_colors.dart';
import '../../core/theme/brut_spacing.dart';
import '../../shared/widgets/widgets.dart';
import 'detalhe_providers.dart';
import 'widgets/acoes_poste.dart';
import 'widgets/cabecalho_poste.dart';
import 'widgets/consumo_ao_vivo.dart';
import 'widgets/historico_consumo.dart';
import 'widgets/log_eventos.dart';

/// Fase 3 · Tela Detalhe do poste. Sem AppBar: o cabeçalho fixo traz o botão
/// voltar e a identificação do poste (uma única vez), conforme o design.
class DetalhePosteScreen extends ConsumerWidget {
  const DetalhePosteScreen({super.key, required this.posteId});

  final String posteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(posteDetalheProvider(posteId));
    final eventos = ref.watch(eventosProvider(posteId)).value;
    final live = ref.watch(posteAoVivoProvider(posteId)).value;
    final aoVivo = ref.watch(aoVivoProvider);

    return Scaffold(
      body: async.when(
        loading: () => const SafeArea(child: BrutLoading()),
        error: (e, _) => SafeArea(
          child: BrutError(
            error: e,
            onRetry: () => ref.invalidate(posteDetalheProvider(posteId)),
          ),
        ),
        data: (posteRest) {
          final poste = live == null
              ? posteRest
              : posteRest.comAoVivo(
                  status: live.status,
                  luminosidadeAtual: live.luminosidadeAtual,
                  consumoInstantaneoKw: live.consumoInstantaneoKw,
                  ultimaLeituraEm: live.ultimaLeituraEm,
                );
          return Column(
            children: [
              SafeArea(bottom: false, child: CabecalhoPoste(poste: poste)),
              Expanded(
                child: RefreshIndicator(
                  color: BrutColors.ink,
                  onRefresh: () async {
                    ref.invalidate(posteDetalheProvider(posteId));
                    ref.invalidate(telemetriaProvider(posteId));
                    ref.invalidate(eventosProvider(posteId));
                    await ref.read(posteDetalheProvider(posteId).future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(BrutSpacing.md),
                    children: [
                      ConsumoAoVivo(
                        poste: poste,
                        eventos: eventos,
                        aoVivo: aoVivo,
                      ),
                      const SizedBox(height: BrutSpacing.lg),
                      HistoricoConsumo(posteId: posteId),
                      const SizedBox(height: BrutSpacing.lg),
                      LogEventos(posteId: posteId),
                      const SizedBox(height: BrutSpacing.md),
                    ],
                  ),
                ),
              ),
              AcoesPoste(poste: poste),
            ],
          );
        },
      ),
    );
  }
}
