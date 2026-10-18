import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';

/// Resumo do poste selecionado no mapa (PRD §5.1): código, endereço, status,
/// consumo instantâneo, luminosidade atual e CTA para o detalhe.
class PosteBottomSheet extends StatelessWidget {
  const PosteBottomSheet({
    super.key,
    required this.poste,
    required this.onFechar,
    required this.onVerDetalhe,
  });

  final PosteResumo poste;
  final VoidCallback onFechar;
  final VoidCallback onVerDetalhe;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrutColors.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: BrutColors.line, width: BrutStroke.regular),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          BrutSpacing.md,
          BrutSpacing.md,
          BrutSpacing.md,
          BrutSpacing.md + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poste.codigo,
                        style: BrutType.mono(
                          15,
                          weight: FontWeight.w700,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${poste.endereco} · ${poste.bairro}',
                        style: BrutType.sans(13, color: BrutColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BrutSpacing.sm),
                _BotaoFechar(onTap: onFechar),
              ],
            ),
            const SizedBox(height: BrutSpacing.md),
            _StatusPill(poste.status),
            const SizedBox(height: BrutSpacing.md),
            _GradeMetricas(
              consumo: poste.semTelemetria
                  ? '—'
                  : Fmt.kw(poste.consumoInstantaneoKw),
              luminosidade: poste.status == StatusPoste.manutencao
                  ? 'desligado'
                  : '${poste.luminosidadeAtual.toStringAsFixed(0)} %',
            ),
            const SizedBox(height: BrutSpacing.md),
            _BotaoDetalhe(onTap: onVerDetalhe),
          ],
        ),
      ),
    );
  }
}

class _BotaoFechar extends StatelessWidget {
  const _BotaoFechar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BrutColors.paper,
          border: Border.all(color: BrutColors.lineSoft, width: 1),
        ),
        child: const Icon(Icons.close, size: 15, color: BrutColors.inkMuted),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final StatusPoste status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: BrutColors.paper,
        border: Border.all(color: BrutColors.lineSoft, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
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

class _GradeMetricas extends StatelessWidget {
  const _GradeMetricas({required this.consumo, required this.luminosidade});

  final String consumo;
  final String luminosidade;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: BrutColors.lineSoft, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Metrica(rotulo: 'Consumo', valor: consumo)),
            Container(width: 1, color: BrutColors.lineSoft),
            Expanded(
              child: _Metrica(rotulo: 'Luminosidade', valor: luminosidade),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo.toUpperCase(), style: BrutType.label(9)),
          const SizedBox(height: 4),
          Text(valor, style: BrutType.mono(19, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _BotaoDetalhe extends StatelessWidget {
  const _BotaoDetalhe({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: BrutColors.destaque,
        child: Text(
          'Ver detalhe do poste',
          textAlign: TextAlign.center,
          style: BrutType.sans(
            13,
            weight: FontWeight.w600,
            color: BrutColors.surface,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
