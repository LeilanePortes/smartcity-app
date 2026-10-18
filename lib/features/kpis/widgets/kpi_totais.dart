import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

/// Cards de consumo total e custo total, empilhados em largura total, com a
/// variação % frente ao período anterior equivalente e a tarifa vigente no
/// rodapé do card de custo (PRD §5.3 · design aprovado).
class KpiTotais extends StatelessWidget {
  const KpiTotais({super.key, required this.kpis});

  final KpisResumo kpis;

  String get _periodoLabel => kpis.periodo.label;

  String get _periodoAnterior => switch (kpis.periodo) {
        PeriodoKpi.dia => 'ontem',
        PeriodoKpi.semana => 'semana anterior',
        PeriodoKpi.mes => 'mês anterior',
        PeriodoKpi.ano => 'ano anterior',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatCard(
          label: 'Consumo total · $_periodoLabel',
          value: Fmt.inteiro(kpis.atual.consumoKwh.round()),
          unit: 'kWh',
          deltaLabel: Fmt.percentualVariacao(kpis.variacaoConsumoPct),
          deltaValue: kpis.variacaoConsumoPct,
          deltaContexto: 'vs. $_periodoAnterior',
        ),
        const SizedBox(height: BrutSpacing.md),
        StatCard(
          label: 'Custo total · $_periodoLabel',
          value: Fmt.reais(kpis.atual.custoReais),
          unit: r'R$',
          unitLeading: true,
          deltaLabel: Fmt.percentualVariacao(kpis.variacaoCustoPct),
          deltaValue: kpis.variacaoCustoPct,
          deltaContexto: 'vs. $_periodoAnterior',
          footer: Text.rich(
            TextSpan(
              text: 'Tarifa ${kpis.tarifa.classe} ${kpis.tarifa.descricao}: ',
              children: [
                TextSpan(
                  text: '${Fmt.moeda(kpis.tarifa.valorKwh)}/kWh',
                  style: BrutType.mono(
                    12,
                    weight: FontWeight.w700,
                    color: BrutColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
