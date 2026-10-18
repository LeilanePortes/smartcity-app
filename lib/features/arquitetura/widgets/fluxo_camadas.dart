import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'card_titulo.dart';

/// Estado exibido no selo de cada camada.
enum EstadoCamada {
  noAr('NO AR', BrutColors.statusNormal),
  foraDoAr('FORA DO AR', BrutColors.destaque),
  semDados('SEM DADOS', BrutColors.inkFaint);

  const EstadoCamada(this.label, this.cor);

  final String label;
  final Color cor;

  /// `null` = ainda não reportado.
  static EstadoCamada de(bool? online) => switch (online) {
        true => EstadoCamada.noAr,
        false => EstadoCamada.foraDoAr,
        null => EstadoCamada.semDados,
      };
}

/// Fluxo Edge → Fog → Nuvem, de cima para baixo (cabe em 412 px). As setas
/// carregam o tráfego da última janela.
class FluxoCamadas extends StatelessWidget {
  const FluxoCamadas({super.key, required this.estado});

  final EstadoArquitetura estado;

  @override
  Widget build(BuildContext context) {
    final interno = estado.modoInterno;
    final edge = estado.edge;
    final fog = estado.fog;
    final trafego = estado.trafego;

    // Postes reportando: preferimos a visão do tráfego; senão, a soma dos gateways.
    String postesEdge = '248 postes simulados';
    if (trafego != null && trafego.postesTotal > 0) {
      postesEdge = '${trafego.postesOnline} de ${trafego.postesTotal} postes online';
    } else if (fog != null && fog.gateways.isNotEmpty) {
      postesEdge = '${fog.totalOnline} de ${fog.totalPostes} postes online';
    }

    final String detalheFog;
    if (fog == null) {
      detalheFog = interno ? 'Não usado no modo de reserva' : 'Aguardando o fog se anunciar';
    } else {
      final buffer = fog.buffer == 0
          ? 'buffer em dia'
          : 'buffer ${Fmt.inteiro(fog.buffer)} msgs';
      final relatorio = fog.atualizadoEm == null
          ? ''
          : ' · relatório às ${Fmt.horaSegundos(fog.atualizadoEm!)}';
      detalheFog = '${fog.gateways.length} gateways por bairro · $buffer$relatorio';
    }

    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardTitulo('Camadas', trailing: 'EDGE → FOG → NUVEM'),
          const SizedBox(height: BrutSpacing.md),
          _Camada(
            nome: 'EDGE',
            papel: 'Postes decidem a luz localmente',
            detalhe: edge == null
                ? (interno
                    ? 'Não usado no modo de reserva'
                    : 'Aguardando o 1º relatório do fog')
                : postesEdge,
            selos: [
              _Selo(rotulo: 'POSTES', estado: EstadoCamada.de(edge?.online)),
            ],
          ),
          _Seta(fluxo: trafego?.entrada, janelaS: trafego?.janelaS, de: 'postes → fog'),
          _Camada(
            nome: 'FOG',
            papel: 'Gateway por bairro: diagnostica e agrega',
            detalhe: detalheFog,
            selos: [
              _Selo(rotulo: 'GATEWAYS', estado: EstadoCamada.de(fog?.online)),
            ],
          ),
          _Seta(fluxo: trafego?.saida, janelaS: trafego?.janelaS, de: 'fog → nuvem'),
          _Camada(
            nome: 'NUVEM',
            papel: 'API + broker MQTT da nuvem',
            detalhe: 'Recebe resumos, eventos e alertas do fog',
            // A resposta chegou, então a API está no ar. O broker é separado:
            // pode cair (demonstração do buffer) sem a nuvem inteira cair.
            selos: [
              const _Selo(rotulo: 'API', estado: EstadoCamada.noAr),
              _Selo(
                rotulo: 'BROKER MQTT',
                estado: EstadoCamada.de(estado.brokerConectado),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Camada extends StatelessWidget {
  const _Camada({
    required this.nome,
    required this.papel,
    required this.detalhe,
    required this.selos,
  });

  final String nome;
  final String papel;
  final String detalhe;
  final List<_Selo> selos;

  @override
  Widget build(BuildContext context) {
    // Faixa à esquerda: verde se tudo no ar, destaque se algo caiu, cinza sem dados.
    final estados = selos.map((s) => s.estado).toList();
    final faixa = estados.contains(EstadoCamada.foraDoAr)
        ? EstadoCamada.foraDoAr.cor
        : estados.every((e) => e == EstadoCamada.noAr)
            ? EstadoCamada.noAr.cor
            : EstadoCamada.semDados.cor;

    return Container(
      decoration: BoxDecoration(
        color: BrutColors.surface,
        border: Border(
          top: const BorderSide(color: BrutColors.line, width: BrutStroke.regular),
          right: const BorderSide(color: BrutColors.line, width: BrutStroke.regular),
          bottom: const BorderSide(color: BrutColors.line, width: BrutStroke.regular),
          left: BorderSide(color: faixa, width: 6),
        ),
      ),
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nome, style: BrutType.mono(18, weight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(papel, style: BrutType.sans(12, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(detalhe, style: BrutType.sans(12, color: BrutColors.inkMuted)),
          const SizedBox(height: BrutSpacing.sm),
          Wrap(
            spacing: BrutSpacing.md,
            runSpacing: BrutSpacing.xs,
            children: selos,
          ),
        ],
      ),
    );
  }
}

/// "API: NO AR" — rótulo + ponto + estado.
class _Selo extends StatelessWidget {
  const _Selo({required this.rotulo, required this.estado});

  final String rotulo;
  final EstadoCamada estado;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$rotulo:', style: BrutType.label(10)),
        const SizedBox(width: BrutSpacing.xs),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: estado.cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: BrutSpacing.xs),
        Text(
          estado.label,
          style: BrutType.mono(11, weight: FontWeight.w700, color: estado.cor),
        ),
      ],
    );
  }
}

/// Seta entre camadas com o volume da janela.
class _Seta extends StatelessWidget {
  const _Seta({required this.fluxo, required this.janelaS, required this.de});

  final FluxoTrafego? fluxo;
  final int? janelaS;
  final String de;

  @override
  Widget build(BuildContext context) {
    final texto = fluxo == null
        ? 'sem dados de tráfego'
        : '${Fmt.inteiro(fluxo!.msgs)} msgs · ${Fmt.kb(fluxo!.bytes)} em ${janelaS ?? 60} s';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BrutSpacing.xs),
      child: Row(
        children: [
          const SizedBox(width: BrutSpacing.md),
          const Icon(Icons.arrow_downward, size: 20, color: BrutColors.ink),
          const SizedBox(width: BrutSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: texto,
                    style: BrutType.mono(12, weight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: '  $de',
                    style: BrutType.sans(11, color: BrutColors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
