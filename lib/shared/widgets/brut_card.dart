import 'package:flutter/material.dart';

import '../../core/theme/brut_colors.dart';
import '../../core/theme/brut_spacing.dart';

/// Card do design aprovado: hairline de 1px (`lineSoft`), radius 0, sem sombra.
/// Opcionalmente clicável e com uma faixa de acento à esquerda (status).
class BrutCard extends StatelessWidget {
  const BrutCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BrutSpacing.lg),
    this.onTap,
    this.accent,
    this.background = BrutColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Faixa de 6px à esquerda (ex.: cor do status do poste).
  final Color? accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final border = accent == null
        ? Border.all(color: BrutColors.lineSoft, width: 1)
        : Border(
            top: const BorderSide(color: BrutColors.lineSoft, width: 1),
            right: const BorderSide(color: BrutColors.lineSoft, width: 1),
            bottom: const BorderSide(color: BrutColors.lineSoft, width: 1),
            left: BorderSide(color: accent!, width: 4),
          );

    final content = Container(
      decoration: BoxDecoration(color: background, border: border),
      padding: padding,
      child: child,
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      child: content,
    );
  }
}
