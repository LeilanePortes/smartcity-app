import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'card_titulo.dart';

/// Gateways do fog por bairro (postes online / total) e o buffer de mensagens
/// guardadas no fog esperando a nuvem.
class GatewaysFog extends StatelessWidget {
  const GatewaysFog({super.key, required this.fog, required this.modoInterno});

  final FogInfo? fog;
  final bool modoInterno;

  @override
  Widget build(BuildContext context) {
    final f = fog;
    if (f == null) {
      return BrutCard(
        padding: const EdgeInsets.all(BrutSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CardTitulo('Gateways do fog'),
            BrutEmpty(
              message: modoInterno
                  ? 'Indisponível no modo de reserva.'
                  : 'Aguardando o fog se anunciar.',
              icon: Icons.router_outlined,
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
            'Gateways do fog · ${f.gateways.length} bairros',
            trailing: '${f.totalOnline}/${f.totalPostes} ONLINE',
          ),
          const SizedBox(height: BrutSpacing.md),
          if (f.gateways.isEmpty)
            Text('Nenhum gateway reportado.',
                style: BrutType.sans(12, color: BrutColors.inkMuted))
          else
            for (final g in f.gateways) _LinhaGateway(gateway: g),
          const SizedBox(height: BrutSpacing.sm),
          const Divider(height: 1, thickness: 1, color: BrutColors.lineSoft),
          const SizedBox(height: BrutSpacing.sm),
          _Buffer(buffer: f.buffer),
        ],
      ),
    );
  }
}

class _LinhaGateway extends StatelessWidget {
  const _LinhaGateway({required this.gateway});

  final GatewayFog gateway;

  @override
  Widget build(BuildContext context) {
    final g = gateway;
    final completo = g.offline == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              g.bairro,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BrutType.sans(13, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: BrutSpacing.sm),
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 6,
              child: g.postes == 0
                  ? const ColoredBox(color: BrutColors.lineSoft)
                  : Row(
                      children: [
                        if (g.online > 0)
                          Expanded(
                            flex: g.online,
                            child: const ColoredBox(
                                color: BrutColors.statusNormal),
                          ),
                        if (g.offline > 0)
                          Expanded(
                            flex: g.offline,
                            child: const ColoredBox(
                                color: BrutColors.statusFalha),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: BrutSpacing.sm),
          SizedBox(
            width: 52,
            child: Text(
              '${g.online}/${g.postes}',
              textAlign: TextAlign.right,
              style: BrutType.mono(
                13,
                weight: FontWeight.w700,
                color: completo ? BrutColors.ink : BrutColors.statusFalha,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Buffer extends StatelessWidget {
  const _Buffer({required this.buffer});

  final int buffer;

  @override
  Widget build(BuildContext context) {
    final emDia = buffer == 0;
    return Row(
      children: [
        Icon(
          emDia ? Icons.inventory_2_outlined : Icons.inventory_2,
          size: 18,
          color: emDia ? BrutColors.inkMuted : BrutColors.destaque,
        ),
        const SizedBox(width: BrutSpacing.sm),
        Text('BUFFER', style: BrutType.label(10)),
        const SizedBox(width: BrutSpacing.sm),
        Expanded(
          child: Text(
            emDia
                ? 'em dia — nada esperando a nuvem'
                : '${Fmt.inteiro(buffer)} mensagens aguardando a nuvem',
            style: BrutType.sans(
              12,
              weight: emDia ? FontWeight.w400 : FontWeight.w700,
              color: emDia ? BrutColors.inkMuted : BrutColors.destaque,
            ),
          ),
        ),
        Text(
          Fmt.inteiro(buffer),
          style: BrutType.mono(
            16,
            weight: FontWeight.w700,
            color: emDia ? BrutColors.ink : BrutColors.destaque,
          ),
        ),
      ],
    );
  }
}
