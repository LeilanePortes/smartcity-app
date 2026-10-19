import 'package:flutter/material.dart';

import '../../../../core/theme/brut_colors.dart';
import '../../../../core/theme/brut_spacing.dart';
import '../../../../core/theme/brut_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../widgets/card_titulo.dart';
import 'ota_estilo.dart';

/// Quantos postes rodam cada versão: barra empilhada + legenda em chips.
class VersoesEmCampo extends StatelessWidget {
  const VersoesEmCampo({super.key, required this.estado});

  final EstadoOta estado;

  @override
  Widget build(BuildContext context) {
    final versoes = estado.versoesEmCampo;
    final comPostes = [
      for (var i = 0; i < versoes.length; i++)
        if (versoes[i].postes > 0) (versoes[i], i),
    ];

    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitulo(
            'Versões em campo',
            trailing: '${Fmt.inteiro(estado.totalEmCampo)} POSTES',
          ),
          const SizedBox(height: BrutSpacing.md),
          if (comPostes.isEmpty)
            Text('Nenhum poste reportou a versão ainda.',
                style: BrutType.sans(12, color: BrutColors.inkMuted))
          else ...[
            SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (var k = 0; k < comPostes.length; k++) ...[
                    if (k > 0) const SizedBox(width: 1),
                    Expanded(
                      flex: comPostes[k].$1.postes,
                      child: ColoredBox(
                        color: OtaEstilo.versao(
                            comPostes[k].$1.versao, estado, comPostes[k].$2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: BrutSpacing.md),
            Wrap(
              spacing: BrutSpacing.sm,
              runSpacing: BrutSpacing.sm,
              children: [
                for (var i = 0; i < versoes.length; i++)
                  _Chip(
                    versao: versoes[i],
                    cor: OtaEstilo.versao(versoes[i].versao, estado, i),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.versao, required this.cor});

  final VersaoEmCampo versao;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BrutSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: BrutColors.surface,
        border: Border.all(color: BrutColors.lineMedium, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, color: cor),
          const SizedBox(width: 6),
          Text(versao.versao,
              style: BrutType.mono(12, weight: FontWeight.w700)),
          Text(' · ${Fmt.inteiro(versao.postes)}',
              style: BrutType.mono(12, color: BrutColors.inkMuted)),
        ],
      ),
    );
  }
}
