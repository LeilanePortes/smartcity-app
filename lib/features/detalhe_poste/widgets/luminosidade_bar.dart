import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_typography.dart';

/// Barra de luminosidade 0–100% com marcação do piso operacional (50%, PRD §5.2),
/// conforme o design aprovado: trilho tênue, preenchimento em `destaque` e um
/// traço de tinta no piso.
class LuminosidadeBar extends StatelessWidget {
  const LuminosidadeBar({
    super.key,
    required this.valor,
    this.piso = 50,
    this.desligado = false,
  });

  final double valor;
  final double piso;
  final bool desligado;

  @override
  Widget build(BuildContext context) {
    final pct = (valor.clamp(0, 100)) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('LUMINOSIDADE', style: BrutType.label(10)),
            const Spacer(),
            Text(
              desligado ? 'DESLIGADO' : '${valor.toStringAsFixed(0)}%',
              style: BrutType.mono(15, weight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return SizedBox(
              height: 10,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Trilho.
                  const Positioned.fill(
                    child: ColoredBox(color: BrutColors.lineSoft),
                  ),
                  // Preenchimento.
                  if (!desligado)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: SizedBox(
                        width: w * pct,
                        child: const ColoredBox(color: BrutColors.destaque),
                      ),
                    ),
                  // Marcação do piso.
                  Positioned(
                    left: (w * (piso / 100)).clamp(0, w) - 0.5,
                    top: -3,
                    bottom: -3,
                    child: Container(width: 1, color: BrutColors.ink),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0%', style: BrutType.mono(9, color: BrutColors.inkMuted)),
            Text('BASE ${piso.toStringAsFixed(0)}%',
                style: BrutType.mono(9, color: BrutColors.inkMuted)),
            Text('100%', style: BrutType.mono(9, color: BrutColors.inkMuted)),
          ],
        ),
      ],
    );
  }
}
