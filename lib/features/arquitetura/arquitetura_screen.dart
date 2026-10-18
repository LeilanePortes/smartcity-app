import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brut_colors.dart';
import '../../core/theme/brut_spacing.dart';
import '../../core/theme/brut_typography.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/widgets.dart';
import '../detalhe_poste/detalhe_poste_screen.dart';
import '../mapa/mapa_providers.dart';
import 'arquitetura_providers.dart';
import 'widgets/alertas_fog.dart';
import 'widgets/fluxo_camadas.dart';
import 'widgets/gateways_fog.dart';
import 'widgets/reducao_banda.dart';

/// Fase 7 · Arquitetura em camadas (edge → fog → nuvem), via `GET /arquitetura`.
///
/// Consulta a cada [kIntervaloArquitetura] só enquanto a aba está visível.
/// Durante a atualização os dados anteriores continuam na tela.
class ArquiteturaScreen extends ConsumerStatefulWidget {
  const ArquiteturaScreen({super.key});

  @override
  ConsumerState<ArquiteturaScreen> createState() => _ArquiteturaScreenState();
}

class _ArquiteturaScreenState extends ConsumerState<ArquiteturaScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    ref.listenManual<bool>(
      arquiteturaVisivelProvider,
      (anterior, visivel) => _sincronizarConsulta(
        visivel: visivel,
        acabouDeEntrar: anterior == false && visivel,
      ),
      fireImmediately: true,
    );
  }

  void _sincronizarConsulta({required bool visivel, required bool acabouDeEntrar}) {
    if (!visivel) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    // Ao voltar para a aba, busca na hora em vez de esperar o próximo ciclo.
    if (acabouDeEntrar) ref.invalidate(arquiteturaProvider);
    _timer ??= Timer.periodic(
      kIntervaloArquitetura,
      (_) => ref.invalidate(arquiteturaProvider),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _abrirPoste(String posteId) {
    // Mesmo comportamento do ranking de KPIs: sincroniza o mapa e abre o detalhe.
    ref.read(posteSelecionadoProvider.notifier).selecionar(posteId);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetalhePosteScreen(posteId: posteId)),
    );
  }

  Future<void> _recarregar() async {
    ref.invalidate(arquiteturaProvider);
    try {
      await ref.read(arquiteturaProvider.future);
    } catch (_) {
      // O erro já aparece na tela; o RefreshIndicator só precisa terminar.
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(arquiteturaProvider);
    final dados = async.value;

    if (dados == null) {
      if (async.hasError) {
        return BrutError(
          error: async.error!,
          onRetry: () => ref.invalidate(arquiteturaProvider),
        );
      }
      return const BrutLoading();
    }

    return RefreshIndicator(
      color: BrutColors.ink,
      onRefresh: _recarregar,
      child: ListView(
        padding: const EdgeInsets.all(BrutSpacing.md),
        children: [
          if (dados.modoInterno) ...[
            const AvisoModoInterno(),
            const SizedBox(height: BrutSpacing.md),
          ],
          FluxoCamadas(estado: dados),
          const SizedBox(height: BrutSpacing.md),
          ReducaoBanda(trafego: dados.trafego, modoInterno: dados.modoInterno),
          const SizedBox(height: BrutSpacing.md),
          GatewaysFog(fog: dados.fog, modoInterno: dados.modoInterno),
          const SizedBox(height: BrutSpacing.md),
          AlertasFog(
            alertas: dados.alertas,
            modoInterno: dados.modoInterno,
            onTapPoste: _abrirPoste,
          ),
          const SizedBox(height: BrutSpacing.md),
          _Rodape(
            geradoEm: dados.geradoEm,
            falhou: async.hasError,
            atualizando: async.isLoading,
          ),
          const SizedBox(height: BrutSpacing.md),
        ],
      ),
    );
  }
}

/// Faixa de aviso do modo de reserva (`modo == "interno"`).
class AvisoModoInterno extends StatelessWidget {
  const AvisoModoInterno({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BrutSpacing.md),
      decoration: BoxDecoration(
        color: BrutColors.statusFalhaSoft,
        border: Border.all(color: BrutColors.destaque, width: BrutStroke.regular),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: BrutColors.destaque, size: 22),
          const SizedBox(width: BrutSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MODO DE RESERVA · SIMULADOR EMBUTIDO',
                  style: BrutType.mono(12, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'A API está gerando os dados com o simulador interno. Edge, '
                  'fog e tráfego não são reportados neste modo.',
                  style: BrutType.sans(12, color: BrutColors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({
    required this.geradoEm,
    required this.falhou,
    required this.atualizando,
  });

  final DateTime geradoEm;
  final bool falhou;
  final bool atualizando;

  @override
  Widget build(BuildContext context) {
    final segundos = kIntervaloArquitetura.inSeconds;
    final texto = falhou
        ? 'Falha ao atualizar — mostrando dados das ${Fmt.horaSegundos(geradoEm)}'
        : 'Atualizado às ${Fmt.horaSegundos(geradoEm)} · consulta a cada $segundos s';
    return Row(
      children: [
        if (atualizando)
          const Padding(
            padding: EdgeInsets.only(right: BrutSpacing.sm),
            child: SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: BrutColors.inkMuted),
            ),
          ),
        Expanded(
          child: Text(
            texto,
            style: BrutType.sans(
              11,
              color: falhou ? BrutColors.destaque : BrutColors.inkMuted,
            ),
          ),
        ),
      ],
    );
  }
}
