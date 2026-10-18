import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'card_titulo.dart';

/// Alertas recentes diagnosticados pelo fog (mudanças de status), mais
/// recentes primeiro. Toque abre o detalhe do poste.
class AlertasFog extends StatelessWidget {
  const AlertasFog({
    super.key,
    required this.alertas,
    required this.modoInterno,
    this.onTapPoste,
  });

  final List<AlertaFog> alertas;
  final bool modoInterno;
  final void Function(String posteId)? onTapPoste;

  @override
  Widget build(BuildContext context) {
    return BrutCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(BrutSpacing.md),
            child: CardTitulo(
              'Alertas do fog',
              trailing: alertas.isEmpty ? null : '${alertas.length} RECENTES',
            ),
          ),
          if (alertas.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: BrutSpacing.md),
              child: BrutEmpty(
                message: modoInterno
                    ? 'Sem alertas do fog no modo de reserva.'
                    : 'Nenhum alerta recente.',
                icon: Icons.notifications_none,
              ),
            )
          else
            for (final a in alertas)
              _LinhaAlerta(
                alerta: a,
                onTap: (onTapPoste == null || !a.temPoste)
                    ? null
                    : () => onTapPoste!(a.posteId),
              ),
        ],
      ),
    );
  }
}

class _LinhaAlerta extends StatelessWidget {
  const _LinhaAlerta({required this.alerta, this.onTap});

  final AlertaFog alerta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = alerta;
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BrutSpacing.md,
          vertical: BrutSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: const Border(
            top: BorderSide(color: BrutColors.lineSoft, width: 1),
          ),
          color: a.status.softColor.withValues(alpha: 0.35),
        ),
        child: Row(
          children: [
            Container(width: 4, height: 44, color: a.status.color),
            const SizedBox(width: BrutSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(a.codigo,
                          style: BrutType.mono(14, weight: FontWeight.w700)),
                      const SizedBox(width: BrutSpacing.sm),
                      Expanded(
                        child: Text(
                          a.bairro,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BrutType.sans(12, color: BrutColors.inkMuted),
                        ),
                      ),
                      if (a.em != null)
                        Text(Fmt.horaSegundos(a.em!),
                            style: BrutType.mono(11,
                                color: BrutColors.inkMuted)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: BrutSpacing.xs,
                    children: [
                      StatusBadge(a.statusAnterior, compact: true),
                      const Icon(Icons.arrow_forward,
                          size: 12, color: BrutColors.inkMuted),
                      StatusBadge(a.status, compact: true),
                    ],
                  ),
                  if (a.motivo.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(a.motivo,
                        style: BrutType.sans(12, color: BrutColors.inkMuted)),
                  ],
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: BrutSpacing.sm),
              const Icon(Icons.chevron_right, size: 20, color: BrutColors.ink),
            ],
          ],
        ),
      ),
    );
  }
}
