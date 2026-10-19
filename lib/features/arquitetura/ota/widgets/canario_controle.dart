import 'package:flutter/material.dart';

import '../../../../core/theme/brut_colors.dart';
import '../../../../core/theme/brut_spacing.dart';
import '../../../../core/theme/brut_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../widgets/card_titulo.dart';

/// Canário × controle no último portão: consumo normalizado dos dois grupos e a
/// razão em destaque, comparada ao limite dos critérios.
class CanarioControle extends StatelessWidget {
  const CanarioControle({
    super.key,
    required this.metricas,
    required this.criterios,
  });

  final MetricasOta? metricas;
  final CriteriosOta criterios;

  @override
  Widget build(BuildContext context) {
    final m = metricas;
    if (m == null) {
      return BrutCard(
        padding: const EdgeInsets.all(BrutSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CardTitulo('Canário × controle'),
            BrutEmpty(
              message: 'Aguardando o 1º portão '
                  '(janela de ${criterios.janelaS} s).',
              icon: Icons.hourglass_bottom,
            ),
          ],
        ),
      );
    }

    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardTitulo('Canário × controle', trailing: 'ÚLTIMO PORTÃO'),
          const SizedBox(height: BrutSpacing.md),
          _Razao(razao: m.razaoConsumo, limite: criterios.limiarRazaoConsumo),
          const SizedBox(height: BrutSpacing.md),
          const Divider(height: 1, thickness: 1, color: BrutColors.lineSoft),
          const SizedBox(height: BrutSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Grupo(
                    nome: 'Canário',
                    subtitulo: 'versão nova',
                    grupo: m.canario,
                    vazio: 'Sem dados do canário.',
                  ),
                ),
                Container(width: 1, color: BrutColors.lineSoft),
                const SizedBox(width: BrutSpacing.md),
                Expanded(
                  child: _Grupo(
                    nome: 'Controle',
                    subtitulo: 'versão antiga',
                    grupo: m.controle,
                    vazio: 'Sem grupo de controle na onda de 100%.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BrutSpacing.sm),
          Text(
            'Consumo normalizado = kW a 100% de luminosidade · '
            'razão = canário ÷ controle',
            style: BrutType.sans(11, color: BrutColors.inkFaint),
          ),
        ],
      ),
    );
  }
}

/// "1,82×" grande + barra com a marca do limite.
class _Razao extends StatelessWidget {
  const _Razao({required this.razao, required this.limite});

  final double? razao;
  final double limite;

  @override
  Widget build(BuildContext context) {
    final r = razao;
    final acima = r != null && r > limite;
    final cor = r == null
        ? BrutColors.inkFaint
        : (acima ? BrutColors.destaque : BrutColors.statusNormal);
    // Escala da barra: cabe o limite com folga e a razão observada.
    final escala = [limite * 1.5, (r ?? 0) * 1.1].reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              r == null ? '—' : '${Fmt.decimal(r, casas: 2)}×',
              style: BrutType.mono(44,
                  weight: FontWeight.w700, height: 0.95, color: cor),
            ),
            const SizedBox(width: BrutSpacing.sm),
            Expanded(
              child: Text(
                'limite ${Fmt.decimal(limite, casas: 2)}×',
                style: BrutType.mono(13,
                    weight: FontWeight.w600, color: BrutColors.inkMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          r == null
              ? 'Razão de consumo indisponível'
              : (acima
                  ? 'Canário consome acima do limite → reverter'
                  : 'Canário dentro do limite'),
          style: BrutType.sans(12, weight: FontWeight.w600, color: cor),
        ),
        const SizedBox(height: BrutSpacing.sm),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final fill = r == null ? 0.0 : (r / escala).clamp(0.0, 1.0);
            final marca = (limite / escala).clamp(0.0, 1.0) * w;
            return SizedBox(
              height: 14,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: BrutColors.paper,
                      border: Border.all(color: BrutColors.line, width: 1.5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fill,
                    child: Container(color: cor),
                  ),
                  Positioned(
                    left: marca - 1,
                    top: -4,
                    bottom: -4,
                    child: Container(width: 2, color: BrutColors.ink),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({
    required this.nome,
    required this.subtitulo,
    required this.grupo,
    required this.vazio,
  });

  final String nome;
  final String subtitulo;
  final GrupoMetricas? grupo;
  final String vazio;

  @override
  Widget build(BuildContext context) {
    final g = grupo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nome.toUpperCase(), style: BrutType.label(10, color: BrutColors.ink)),
        Text(subtitulo, style: BrutType.sans(11, color: BrutColors.inkMuted)),
        const SizedBox(height: BrutSpacing.sm),
        if (g == null)
          Text(vazio, style: BrutType.sans(12, color: BrutColors.inkMuted))
        else ...[
          Text(
            g.consumoNormalizadoMedio == null
                ? '—'
                : Fmt.kw(g.consumoNormalizadoMedio!),
            style: BrutType.mono(18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'consumo alto: ${g.consumoAltoPct == null ? '—' : Fmt.percentual(g.consumoAltoPct!)}',
            style: BrutType.sans(12, color: BrutColors.inkMuted),
          ),
          Text(
            'reportaram: ${g.reportaram}/${g.aparelhos}',
            style: BrutType.sans(12, color: BrutColors.inkMuted),
          ),
        ],
      ],
    );
  }
}
