import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'card_titulo.dart';

/// Card de destaque: quanto o fog reduz o que sobe para a nuvem na janela
/// (entrada postes → fog × saída fog → nuvem). As porcentagens vêm prontas do
/// backend; `null` vira "—" (o app não recalcula).
class ReducaoBanda extends StatelessWidget {
  const ReducaoBanda({
    super.key,
    required this.trafego,
    required this.modoInterno,
  });

  final TrafegoInfo? trafego;
  final bool modoInterno;

  @override
  Widget build(BuildContext context) {
    final t = trafego;
    if (t == null) {
      return BrutCard(
        padding: const EdgeInsets.all(BrutSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CardTitulo('Redução de banda no fog'),
            BrutEmpty(
              message: modoInterno
                  ? 'Indisponível no modo de reserva.'
                  : 'Aguardando a primeira janela de tráfego do fog.',
              icon: Icons.swap_vert,
            ),
          ],
        ),
      );
    }

    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitulo(
            'Redução de banda no fog',
            trailing: t.em == null
                ? null
                : 'JANELA ENCERRADA ÀS ${Fmt.horaSegundos(t.em!)}',
          ),
          const SizedBox(height: BrutSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Percentual(
                    valor: t.reducaoMsgsPct,
                    rotulo: 'menos mensagens',
                  ),
                ),
                Container(width: 1, color: BrutColors.lineSoft),
                const SizedBox(width: BrutSpacing.md),
                Expanded(
                  child: _Percentual(
                    valor: t.reducaoBytesPct,
                    rotulo: 'menos bytes',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BrutSpacing.md),
          const Divider(height: 1, thickness: 1, color: BrutColors.lineSoft),
          const SizedBox(height: BrutSpacing.sm),
          _Tabela(entrada: t.entrada, saida: t.saida),
          const SizedBox(height: BrutSpacing.sm),
          Text(
            'Janela de ${t.janelaS} s · ${t.postesOnline} de ${t.postesTotal} '
            'postes reportando',
            style: BrutType.sans(12, color: BrutColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Percentual extends StatelessWidget {
  const _Percentual({required this.valor, required this.rotulo});

  final double? valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                valor == null ? '—' : Fmt.decimal(valor!, casas: 0),
                style: BrutType.mono(52,
                    weight: FontWeight.w700, height: 0.95, letterSpacing: -1.5),
              ),
              if (valor != null)
                Text('%',
                    style: BrutType.mono(22,
                        weight: FontWeight.w600, color: BrutColors.inkMuted)),
            ],
          ),
        ),
        const SizedBox(height: BrutSpacing.xs),
        Text(rotulo, style: BrutType.sans(13, weight: FontWeight.w600)),
      ],
    );
  }
}

/// Entrada × saída em mensagens e KB.
class _Tabela extends StatelessWidget {
  const _Tabela({required this.entrada, required this.saida});

  final FluxoTrafego entrada;
  final FluxoTrafego saida;

  @override
  Widget build(BuildContext context) {
    final cabecalho = BrutType.label(9, color: BrutColors.inkFaint);
    final rotulo = BrutType.sans(12, color: BrutColors.inkMuted);
    final valor = BrutType.mono(14, weight: FontWeight.w700);

    TableRow linha(String nome, String e, String s) => TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(nome, style: rotulo),
            ),
            Text(e, style: valor, textAlign: TextAlign.right),
            Text(s, style: valor, textAlign: TextAlign.right),
          ],
        );

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.1),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1.4),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            Text('ENTRADA\npostes → fog',
                style: cabecalho, textAlign: TextAlign.right),
            Text('SAÍDA\nfog → nuvem',
                style: cabecalho, textAlign: TextAlign.right),
          ],
        ),
        linha('Mensagens', Fmt.inteiro(entrada.msgs), Fmt.inteiro(saida.msgs)),
        linha('Dados', Fmt.kb(entrada.bytes), Fmt.kb(saida.bytes)),
      ],
    );
  }
}
