import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

/// Card "MAIOR CONSUMO" (design aprovado): número simples, ponto de status,
/// código, endereço e o consumo em kWh. Sem caixa numerada, sem valor em R$,
/// sem barra sob a linha.
class RankingConsumoWidget extends StatelessWidget {
  const RankingConsumoWidget({
    super.key,
    required this.ranking,
    this.onTapPoste,
  });

  final RankingConsumo ranking;
  final void Function(String posteId)? onTapPoste;

  static TextStyle get _rotuloCard => BrutType.mono(
        10,
        weight: FontWeight.w600,
        color: BrutColors.inkFaint,
        letterSpacing: 1.2,
      );

  @override
  Widget build(BuildContext context) {
    return BrutCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(BrutSpacing.md),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: BrutColors.lineSoft, width: 1),
              ),
            ),
            child: Row(
              children: [
                Text('MAIOR CONSUMO', style: _rotuloCard),
                const Spacer(),
                Text('kWh',
                    style: BrutType.mono(9,
                        weight: FontWeight.w600,
                        color: BrutColors.inkFaint,
                        letterSpacing: 1)),
              ],
            ),
          ),
          if (ranking.itens.isEmpty)
            Padding(
              padding: const EdgeInsets.all(BrutSpacing.md),
              child: Text('Sem consumo registrado no período.',
                  style: BrutType.sans(13, color: BrutColors.inkMuted)),
            )
          else
            for (var i = 0; i < ranking.itens.length; i++)
              _Linha(
                item: ranking.itens[i],
                ultima: i == ranking.itens.length - 1,
                onTap: onTapPoste == null
                    ? null
                    : () => onTapPoste!(ranking.itens[i].posteId),
              ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.item, required this.ultima, this.onTap});

  final ItemRanking item;
  final bool ultima;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: ultima
              ? null
              : const Border(
                  bottom: BorderSide(color: BrutColors.lineSoft, width: 1),
                ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              child: Text(
                item.posicao.toString().padLeft(2, '0'),
                style: BrutType.mono(
                  10,
                  weight: FontWeight.w600,
                  color: BrutColors.inkFaint,
                ),
              ),
            ),
            const SizedBox(width: BrutSpacing.md),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.status?.color ?? BrutColors.inkFaint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: BrutSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.codigo,
                    style: BrutType.mono(12,
                        weight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.endereco,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BrutType.sans(11, color: BrutColors.inkFaint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BrutSpacing.sm),
            Text(
              Fmt.decimal(item.consumoKwh),
              style: BrutType.mono(13, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
