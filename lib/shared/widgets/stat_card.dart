import 'package:flutter/material.dart';

import '../../core/theme/brut_colors.dart';
import '../../core/theme/brut_spacing.dart';
import '../../core/theme/brut_typography.dart';
import 'brut_card.dart';

/// Card de indicador do dashboard (design aprovado): rótulo, número grande em
/// mono, variação percentual em chip e um rodapé opcional. Mesmo estilo de
/// todos os cards do app (bg-surface, hairline) — sem variante de fundo sólido.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.unitLeading = false,
    this.deltaLabel,
    this.deltaPositiveIsGood = false,
    this.deltaValue,
    this.deltaContexto,
    this.footer,
  });

  final String label;
  final String value;
  final String? unit;

  /// `true` põe a unidade antes do valor (ex.: "R$ 6.203").
  final bool unitLeading;

  /// Texto já formatado da variação (ex.: "−5,4%").
  final String? deltaLabel;

  /// Valor bruto da variação, para escolher a cor/seta. `null` = neutro.
  final double? deltaValue;

  /// Se `true`, queda (delta < 0) é boa (verde). Consumo de energia: menos é bom.
  final bool deltaPositiveIsGood;

  /// Complemento ao lado do chip de variação (ex.: "vs. semana anterior").
  final String? deltaContexto;

  /// Linha de rodapé opcional, separada por um hairline (ex.: tarifa vigente).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final unidade = unit == null
        ? null
        : Text(unit!,
            style: BrutType.mono(15,
                weight: FontWeight.w500, color: BrutColors.inkMuted));

    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: BrutType.mono(
              10,
              weight: FontWeight.w600,
              color: BrutColors.inkFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: BrutSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (unidade != null && unitLeading) ...[
                  unidade,
                  const SizedBox(width: 6),
                ],
                Text(
                  value,
                  style: BrutType.mono(44,
                      weight: FontWeight.w600, height: 0.9, letterSpacing: -1),
                ),
                if (unidade != null && !unitLeading) ...[
                  const SizedBox(width: 6),
                  unidade,
                ],
              ],
            ),
          ),
          if (deltaLabel != null) ...[
            const SizedBox(height: BrutSpacing.sm),
            _Delta(
              label: deltaLabel!,
              value: deltaValue,
              positiveIsGood: deltaPositiveIsGood,
              contexto: deltaContexto,
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: BrutSpacing.md),
            const Divider(height: 1, thickness: 1, color: BrutColors.lineSoft),
            const SizedBox(height: BrutSpacing.sm),
            DefaultTextStyle.merge(
              style: BrutType.sans(12, color: BrutColors.inkMuted, height: 1.5),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta({
    required this.label,
    required this.value,
    required this.positiveIsGood,
    this.contexto,
  });

  final String label;
  final double? value;
  final bool positiveIsGood;
  final String? contexto;

  @override
  Widget build(BuildContext context) {
    Color color = BrutColors.inkMuted;
    if (value != null && value != 0) {
      final bom = value! > 0 ? positiveIsGood : !positiveIsGood;
      // Variação desfavorável ganha o accent de destaque (#FF3520); a favorável
      // fica em verde de status. Sem ícone de seta (conforme o design).
      color = bom ? BrutColors.statusNormal : BrutColors.destaque;
    }
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: BrutColors.surface,
            border: Border.all(color: BrutColors.lineMedium, width: 1),
          ),
          child: Text(
            label,
            style: BrutType.mono(12, weight: FontWeight.w600, color: color),
          ),
        ),
        if (contexto != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              contexto!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BrutType.sans(12, color: BrutColors.inkMuted),
            ),
          ),
        ],
      ],
    );
  }
}
