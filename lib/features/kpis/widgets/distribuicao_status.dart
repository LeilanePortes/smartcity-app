import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

/// Card "POSTES POR STATUS" (design aprovado): barra empilhada proporcional e a
/// legenda em grade 2×2 com os nomes completos. Começa direto pelo título — sem
/// o contador "N postes na rede".
class DistribuicaoStatus extends StatelessWidget {
  const DistribuicaoStatus({super.key, required this.dados});

  final PostesPorStatus dados;

  static const _ordem = [
    StatusPoste.normal,
    StatusPoste.consumoAlto,
    StatusPoste.falhaOffline,
    StatusPoste.manutencao,
  ];

  static const _label = {
    StatusPoste.normal: 'Operando normal',
    StatusPoste.consumoAlto: 'Consumo alto',
    StatusPoste.falhaOffline: 'Falha / offline',
    StatusPoste.manutencao: 'Manutenção',
  };

  Widget _barra() {
    final visiveis = _ordem.where((s) => dados.quantidadeDe(s) > 0).toList();
    return Row(
      children: [
        for (var i = 0; i < visiveis.length; i++) ...[
          if (i > 0) const SizedBox(width: 1),
          Expanded(
            flex: dados.quantidadeDe(visiveis[i]),
            child: ColoredBox(color: visiveis[i].color),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POSTES POR STATUS',
            style: BrutType.mono(
              10,
              weight: FontWeight.w600,
              color: BrutColors.inkFaint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: BrutSpacing.md),
          // Barra empilhada — flex proporcional à contagem, sulcos de 1px.
          SizedBox(height: 10, child: _barra()),
          const SizedBox(height: BrutSpacing.md),
          // Legenda 2×2.
          Row(
            children: [
              Expanded(child: _Item(status: _ordem[0], n: dados.quantidadeDe(_ordem[0]))),
              const SizedBox(width: BrutSpacing.md),
              Expanded(child: _Item(status: _ordem[1], n: dados.quantidadeDe(_ordem[1]))),
            ],
          ),
          const SizedBox(height: BrutSpacing.sm),
          Row(
            children: [
              Expanded(child: _Item(status: _ordem[2], n: dados.quantidadeDe(_ordem[2]))),
              const SizedBox(width: BrutSpacing.md),
              Expanded(child: _Item(status: _ordem[3], n: dados.quantidadeDe(_ordem[3]))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.status, required this.n});

  final StatusPoste status;
  final int n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: BrutSpacing.sm),
        Expanded(
          child: Text(
            DistribuicaoStatus._label[status]!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BrutType.sans(12, color: BrutColors.inkMuted),
          ),
        ),
        const SizedBox(width: 4),
        Text('$n', style: BrutType.mono(13, weight: FontWeight.w600)),
      ],
    );
  }
}
