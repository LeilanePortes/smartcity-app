import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';

/// Título interno dos cards da tela Arquitetura — mesmo estilo dos cards do
/// dashboard (mono 10, caixa alta, `inkFaint`), com complemento à direita.
class CardTitulo extends StatelessWidget {
  const CardTitulo(this.texto, {super.key, this.trailing});

  final String texto;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final estilo = BrutType.mono(
      10,
      weight: FontWeight.w600,
      color: BrutColors.inkFaint,
      letterSpacing: 1.2,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(texto.toUpperCase(), style: estilo)),
        if (trailing != null) ...[
          const SizedBox(width: BrutSpacing.sm),
          Text(trailing!, style: estilo),
        ],
      ],
    );
  }
}
