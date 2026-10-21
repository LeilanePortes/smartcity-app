import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../detalhe_providers.dart';

/// Log de eventos do sensor 360° (PRD §5.2), consumindo `GET /postes/:id/eventos`.
class LogEventos extends ConsumerWidget {
  const LogEventos({super.key, required this.posteId});

  final String posteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventosProvider(posteId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Sensor 360°'),
        const SizedBox(height: BrutSpacing.md),
        BrutCard(
          padding: EdgeInsets.zero,
          child: async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: BrutLoading(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: BrutError(
                error: e,
                onRetry: () => ref.invalidate(eventosProvider(posteId)),
              ),
            ),
            data: (pagina) {
              final eventos = pagina.itens;
              if (eventos.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: BrutEmpty(
                    message: 'Nenhum evento registrado.',
                    icon: Icons.sensors_off,
                  ),
                );
              }
              final visiveis = eventos.take(12).toList();
              // `total` do envelope conta todos os eventos do poste, não só os
              // da página carregada.
              final anteriores = pagina.total - visiveis.length;
              return Column(
                children: [
                  for (var i = 0; i < visiveis.length; i++)
                    _LinhaEvento(
                      evento: visiveis[i],
                      primeira: i == 0,
                    ),
                  if (anteriores > 0)
                    Padding(
                      padding: const EdgeInsets.all(BrutSpacing.sm),
                      child: Text(
                        '+ $anteriores eventos anteriores',
                        style: BrutType.sans(11, color: BrutColors.inkMuted),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LinhaEvento extends StatelessWidget {
  const _LinhaEvento({required this.evento, required this.primeira});

  final EventoSensor evento;
  final bool primeira;

  @override
  Widget build(BuildContext context) {
    final detectou = evento.subiuParaPico;
    final cor = detectou ? BrutColors.statusAtencao : BrutColors.statusNormal;
    final sentido = evento.sentido;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BrutSpacing.md,
        vertical: BrutSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: primeira
            ? null
            : const Border(
                top: BorderSide(color: BrutColors.line, width: BrutStroke.thin),
              ),
      ),
      child: Row(
        children: [
          Icon(
            detectou ? Icons.directions_car : Icons.nightlight_round,
            size: 16,
            color: cor,
          ),
          const SizedBox(width: BrutSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.tipo.label,
                  style: BrutType.sans(13, weight: FontWeight.w600),
                ),
                if (sentido != null)
                  Text(
                    'Sentido ${sentido.label.toLowerCase()}',
                    style: BrutType.sans(11, color: BrutColors.inkMuted),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${evento.luminosidadeResultante.toStringAsFixed(0)}%',
                style: BrutType.mono(13, weight: FontWeight.w700, color: cor),
              ),
              Text(
                Fmt.hora(evento.timestamp),
                style: BrutType.mono(10, color: BrutColors.inkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
