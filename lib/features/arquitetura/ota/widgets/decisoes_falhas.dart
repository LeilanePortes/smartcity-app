import 'package:flutter/material.dart';

import '../../../../core/theme/brut_colors.dart';
import '../../../../core/theme/brut_spacing.dart';
import '../../../../core/theme/brut_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../widgets/card_titulo.dart';
import 'ota_estilo.dart';

/// Histórico dos portões (decisão, onda, motivo, horário) e falhas de instalação.
class DecisoesFalhas extends StatelessWidget {
  const DecisoesFalhas({
    super.key,
    required this.implantacao,
    required this.janelaS,
  });

  final ImplantacaoOta implantacao;
  final int janelaS;

  @override
  Widget build(BuildContext context) {
    final decisoes = implantacao.decisoes;
    final falhas = implantacao.falhas;

    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitulo(
            'Decisões dos portões',
            trailing: decisoes.isEmpty ? null : '${decisoes.length}',
          ),
          const SizedBox(height: BrutSpacing.sm),
          if (decisoes.isEmpty)
            Text(
              'Nenhuma decisão ainda — o 1º portão fecha em até $janelaS s.',
              style: BrutType.sans(12, color: BrutColors.inkMuted),
            )
          else
            for (final d in decisoes) _LinhaDecisao(decisao: d),
          const SizedBox(height: BrutSpacing.md),
          const Divider(height: 1, thickness: 1, color: BrutColors.lineSoft),
          const SizedBox(height: BrutSpacing.md),
          CardTitulo(
            'Falhas de instalação',
            trailing: falhas.isEmpty ? null : '${falhas.length}',
          ),
          const SizedBox(height: BrutSpacing.sm),
          if (falhas.isEmpty)
            Text('Nenhuma falha.',
                style: BrutType.sans(12, color: BrutColors.inkMuted))
          else
            for (final f in falhas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(f.codigo,
                          style: BrutType.mono(13,
                              weight: FontWeight.w700,
                              color: BrutColors.destaque)),
                    ),
                    Expanded(
                      child: Text(f.motivo,
                          style: BrutType.sans(12, color: BrutColors.inkMuted)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _LinhaDecisao extends StatelessWidget {
  const _LinhaDecisao({required this.decisao});

  final DecisaoOta decisao;

  @override
  Widget build(BuildContext context) {
    final d = decisao;
    final (cor, fundo) = OtaEstilo.decisao(d.decisao);
    return Container(
      margin: const EdgeInsets.only(bottom: BrutSpacing.sm),
      padding: const EdgeInsets.only(left: BrutSpacing.sm),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: cor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SeloOta(texto: d.decisao.label, cor: cor, fundo: fundo),
              const SizedBox(width: BrutSpacing.sm),
              Text('onda ${d.ondaPct}%',
                  style: BrutType.mono(12, weight: FontWeight.w600)),
              const Spacer(),
              if (d.em != null)
                Text(Fmt.horaSegundos(d.em!),
                    style: BrutType.mono(11, color: BrutColors.inkMuted)),
            ],
          ),
          if (d.motivo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(d.motivo, style: BrutType.sans(12)),
          ],
        ],
      ),
    );
  }
}
