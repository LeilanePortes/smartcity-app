import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

/// Card "CONSUMO NO PERÍODO" (design aprovado): barra sólida = período atual,
/// barra clara ao fundo = período anterior, alinhadas por índice. Só a linha
/// de base e os rótulos do eixo X — sem eixo Y nem grade.
class GraficoComparativo extends StatelessWidget {
  const GraficoComparativo({super.key, required this.serie});

  final SerieComparativa serie;

  static TextStyle get _rotuloCard => BrutType.mono(
        10,
        weight: FontWeight.w600,
        color: BrutColors.inkFaint,
        letterSpacing: 1.2,
      );

  @override
  Widget build(BuildContext context) {
    final n = serie.atual.length;
    double maxV = 0;
    for (var i = 0; i < n; i++) {
      final a = serie.atual[i].consumoKwh;
      final b = i < serie.anterior.length ? serie.anterior[i].consumoKwh : 0.0;
      maxV = [maxV, a, b].reduce((x, y) => x > y ? x : y);
    }
    final topo = maxV <= 0 ? 1.0 : maxV * 1.15;
    final passo = _passo(n);

    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('CONSUMO NO PERÍODO', style: _rotuloCard),
              const Spacer(),
              Text('ANTERIOR',
                  style: BrutType.mono(9,
                      weight: FontWeight.w600,
                      color: BrutColors.inkFaint,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: BrutSpacing.md),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: topo,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => BrutColors.ink,
                    tooltipBorderRadius: BorderRadius.zero,
                    getTooltipItem: (group, _, rod, _) {
                      final i = group.x;
                      final a = serie.atual[i].consumoKwh;
                      final b = i < serie.anterior.length
                          ? serie.anterior[i].consumoKwh
                          : 0.0;
                      return BarTooltipItem(
                        'atual ${a.toStringAsFixed(1)} kWh\n',
                        BrutType.mono(11,
                            weight: FontWeight.w700, color: BrutColors.paper),
                        children: [
                          TextSpan(
                            text: 'anterior ${b.toStringAsFixed(1)} kWh',
                            style: BrutType.sans(10, color: BrutColors.paper),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= n || i % passo != 0) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            _rotulo(serie.atual[i].inicio, serie.granularidade),
                            style: BrutType.mono(9, color: BrutColors.inkFaint),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: BrutColors.lineMedium, width: 1),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < n; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: serie.atual[i].consumoKwh,
                          color: BrutColors.ink,
                          width: n > 20 ? 5 : 9,
                          borderRadius: BorderRadius.zero,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: i < serie.anterior.length
                                ? serie.anterior[i].consumoKwh
                                : 0,
                            color: BrutColors.lineSoft,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static int _passo(int n) {
    if (n <= 8) return 1;
    if (n <= 14) return 2;
    if (n <= 24) return 4;
    return 6;
  }

  static String _rotulo(DateTime d, String granularidade) {
    final l = d.toLocal();
    return switch (granularidade) {
      'hora' => '${l.hour.toString().padLeft(2, '0')}h',
      'mes' => _mes(l.month),
      _ => '${l.day}/${l.month}',
    };
  }

  static String _mes(int m) => const [
        'jan', 'fev', 'mar', 'abr', 'mai', 'jun', //
        'jul', 'ago', 'set', 'out', 'nov', 'dez'
      ][(m - 1) % 12];
}
