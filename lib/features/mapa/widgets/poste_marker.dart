import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../shared/models/models.dart';

/// Marcador de poste no mapa (PRD §5.1): quadrado de borda dura, branco (ou
/// tinta quando selecionado), com o ponto de status no centro.
class PosteMarker extends StatelessWidget {
  const PosteMarker({
    super.key,
    required this.status,
    required this.selecionado,
    required this.onTap,
  });

  final StatusPoste status;
  final bool selecionado;
  final VoidCallback onTap;

  static const double tamanho = 34; // área de toque

  @override
  Widget build(BuildContext context) {
    final base = Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selecionado ? BrutColors.ink : BrutColors.surface,
        border: Border.all(
          color: selecionado ? BrutColors.ink : BrutColors.lineSoft,
          width: selecionado ? 2 : 1,
        ),
      ),
      child: Container(
        width: selecionado ? 10 : 8,
        height: selecionado ? 10 : 8,
        decoration: BoxDecoration(
          color: status.color,
          shape: BoxShape.circle,
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: tamanho,
        height: tamanho,
        child: Center(child: base),
      ),
    );
  }
}
