import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'luminosidade_bar.dart';
import 'texto_contextual.dart';

/// Card único de consumo em tempo real (PRD §5.2 · design aprovado): consumo
/// instantâneo, barra de luminosidade e a nota contextual no rodapé — tudo no
/// mesmo card, sem bloco de ícone à parte.
class ConsumoAoVivo extends StatelessWidget {
  const ConsumoAoVivo({
    super.key,
    required this.poste,
    this.eventos,
    this.aoVivo = false,
  });

  final Poste poste;
  final List<EventoSensor>? eventos;

  /// Conexão WebSocket ativa (fase 5).
  final bool aoVivo;

  @override
  Widget build(BuildContext context) {
    final offline = poste.status == StatusPoste.falhaOffline;
    final manutencao = poste.status == StatusPoste.manutencao;
    final temTelemetria = !offline && !manutencao;
    final nota = notaContextual(poste, eventos);

    return BrutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('CONSUMO EM TEMPO REAL', style: BrutType.label(10)),
              const Spacer(),
              LiveIndicator(active: aoVivo && temTelemetria),
            ],
          ),
          const SizedBox(height: BrutSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                temTelemetria
                    ? Fmt.inteiro(poste.consumoInstantaneoKw * 1000)
                    : '—',
                style: BrutType.mono(44, weight: FontWeight.w700, height: 1),
              ),
              const SizedBox(width: BrutSpacing.xs),
              Text('W', style: BrutType.mono(16, color: BrutColors.inkMuted)),
              const SizedBox(width: BrutSpacing.sm),
              if (temTelemetria)
                Text(
                  '(${Fmt.kw(poste.consumoInstantaneoKw)})',
                  style: BrutType.mono(12, color: BrutColors.inkMuted),
                ),
            ],
          ),
          const SizedBox(height: BrutSpacing.lg),
          LuminosidadeBar(
            valor: poste.luminosidadeAtual,
            desligado: manutencao,
          ),
          const SizedBox(height: BrutSpacing.md),
          const Divider(height: 1, thickness: 1, color: BrutColors.lineSoft),
          const SizedBox(height: BrutSpacing.sm),
          Text(
            nota.detalhe,
            style: BrutType.sans(12, color: BrutColors.inkMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
