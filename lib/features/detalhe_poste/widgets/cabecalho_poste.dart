import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';

/// Cabeçalho fixo do detalhe (PRD §5.2 · design aprovado): voltar + rótulo,
/// código do poste (única ocorrência), endereço, coordenadas e o badge de
/// status em linha própria abaixo.
class CabecalhoPoste extends StatelessWidget {
  const CabecalhoPoste({super.key, required this.poste});

  final Poste poste;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BrutSpacing.md),
      decoration: const BoxDecoration(
        color: BrutColors.surface,
        border: Border(
          bottom: BorderSide(color: BrutColors.lineSoft, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(
                      right: BrutSpacing.md, top: 2, bottom: 2),
                  child: Icon(Icons.arrow_back_ios_new,
                      size: 15, color: BrutColors.ink),
                ),
              ),
              Text('DETALHE DO POSTE', style: BrutType.label(11)),
            ],
          ),
          const SizedBox(height: BrutSpacing.md),
          Text(
            poste.codigo,
            style: BrutType.mono(26, weight: FontWeight.w700, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          Text(poste.endereco,
              style: BrutType.sans(14, color: BrutColors.inkMuted)),
          const SizedBox(height: 2),
          Text(
            '${Fmt.coordenadas(poste.latitude, poste.longitude)} · '
            '${poste.cidade}-${poste.uf}',
            style: BrutType.mono(11, color: BrutColors.inkMuted),
          ),
          const SizedBox(height: BrutSpacing.md),
          _BadgeStatus(poste.status),
        ],
      ),
    );
  }
}

class _BadgeStatus extends StatelessWidget {
  const _BadgeStatus(this.status);

  final StatusPoste status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: BrutColors.surface,
        border: Border.all(color: BrutColors.lineSoft, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: BrutSpacing.sm),
          Text(
            status.label.toUpperCase(),
            style: BrutType.mono(
              10,
              weight: FontWeight.w700,
              color: BrutColors.ink,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
