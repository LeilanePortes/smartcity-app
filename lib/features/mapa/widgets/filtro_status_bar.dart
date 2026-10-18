import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../shared/models/models.dart';
import '../mapa_providers.dart';

/// Filtro por status (PRD §5.1): Todos, Normal, Atenção, Falha, Manut.
/// Cinco botões de largura igual, sem ponto de status (o design reserva o
/// ponto para os marcadores e o bottom sheet).
class FiltroStatusBar extends ConsumerWidget {
  const FiltroStatusBar({super.key});

  static String _label(StatusPoste s) => switch (s) {
        StatusPoste.manutencao => 'Manut.',
        _ => s.labelFiltro,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selecionado = ref.watch(mapaFiltroProvider).status;

    void selecionar(StatusPoste? s) =>
        ref.read(mapaFiltroProvider.notifier).setStatus(s);

    return Row(
      children: [
        Expanded(
          child: _Chip(
            label: 'Todos',
            ativo: selecionado == null,
            onTap: () => selecionar(null),
          ),
        ),
        for (final s in StatusPoste.values) ...[
          const SizedBox(width: 4),
          Expanded(
            child: _Chip(
              label: _label(s),
              ativo: selecionado == s,
              onTap: () => selecionar(s),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.ativo, required this.onTap});

  final String label;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: ativo ? BrutColors.ink : BrutColors.surface,
          border: Border.all(
            color: ativo ? BrutColors.ink : BrutColors.lineSoft,
            width: ativo ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: BrutType.mono(
            10,
            weight: FontWeight.w600,
            color: ativo ? BrutColors.paper : BrutColors.inkMuted,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
