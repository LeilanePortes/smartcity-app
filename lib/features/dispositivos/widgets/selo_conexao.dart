import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';

/// Selo ONLINE / OFFLINE do dispositivo (RF-DIS-06): ponto + rótulo.
class SeloConexao extends StatelessWidget {
  const SeloConexao({super.key, required this.online, this.compacto = false});

  final bool online;

  /// Sem borda e fundo (para a linha da lista).
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cor = online ? BrutColors.statusNormal : BrutColors.statusFalha;
    final conteudo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          online ? 'ONLINE' : 'OFFLINE',
          style: BrutType.mono(10,
              weight: FontWeight.w700, color: cor, letterSpacing: 0.8),
        ),
      ],
    );
    if (compacto) return conteudo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BrutSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: online ? BrutColors.statusNormalSoft : BrutColors.statusFalhaSoft,
        border: Border.all(color: cor, width: BrutStroke.thin),
      ),
      child: conteudo,
    );
  }
}
