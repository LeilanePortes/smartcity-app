import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';

/// Nota contextual do poste: ícone, cor, título e detalhe derivados do status
/// e do último evento do sensor. Fonte única — usada pelo card de consumo em
/// tempo real (rodapé) e pelo widget [TextoContextual].
typedef NotaContextual = ({IconData icon, Color cor, String titulo, String detalhe});

NotaContextual notaContextual(Poste poste, List<EventoSensor>? eventos) {
  if (poste.status == StatusPoste.falhaOffline) {
    final ultima = poste.ultimaLeituraEm;
    return (
      icon: Icons.wifi_off,
      cor: BrutColors.statusFalha,
      titulo: 'Telemetria ausente',
      detalhe: ultima == null
          ? 'Sem leitura válida registrada. Chamado aberto automaticamente.'
          : 'Última leitura válida em ${Fmt.dataHora(ultima)} '
              '(${Fmt.desde(ultima)}). Chamado aberto automaticamente.',
    );
  }

  if (poste.status == StatusPoste.manutencao) {
    return (
      icon: Icons.build,
      cor: BrutColors.statusManutencao,
      titulo: 'Em manutenção',
      detalhe: 'Luminosidade desligada. Status atribuído manualmente pelo '
          'técnico.',
    );
  }

  final ultimoEvento =
      (eventos != null && eventos.isNotEmpty) ? eventos.first : null;

  if (ultimoEvento != null &&
      ultimoEvento.tipo == TipoEventoSensor.veiculoDetectado &&
      poste.luminosidadeAtual >= 99) {
    final sentido = ultimoEvento.sentido;
    final dir = sentido == null
        ? ''
        : ' ${sentido == SentidoVeiculo.aproximando ? 'se aproximando' : 'se afastando'}';
    return (
      icon: Icons.directions_car,
      cor: BrutColors.statusAtencao,
      titulo: 'Veículo detectado$dir',
      detalhe: 'Sensor 360° elevou a luminosidade para 100% às '
          '${Fmt.hora(ultimoEvento.timestamp)}.',
    );
  }

  if (poste.status == StatusPoste.consumoAlto) {
    return (
      icon: Icons.trending_up,
      cor: BrutColors.statusAtencao,
      titulo: 'Consumo acima da média',
      detalhe: 'Consumo acima da média do trecho nas últimas 24 h.',
    );
  }

  return (
    icon: Icons.nightlight_round,
    cor: BrutColors.statusNormal,
    titulo: 'Operando no piso de 50%',
    detalhe: 'Nenhum veículo na via. A luz sobe para 100% quando o sensor '
        '360° detectar aproximação.',
  );
}

/// Texto contextual dinâmico (PRD §5.2): evento de veículo detectado, aviso de
/// telemetria ausente com abertura de chamado, ou operação no piso.
class TextoContextual extends StatelessWidget {
  const TextoContextual({super.key, required this.poste, this.eventos});

  final Poste poste;
  final List<EventoSensor>? eventos;

  @override
  Widget build(BuildContext context) {
    final c = notaContextual(poste, eventos);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BrutSpacing.md),
      decoration: BoxDecoration(
        color: BrutColors.surface,
        border: Border.all(color: BrutColors.line, width: BrutStroke.regular),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: c.cor, width: BrutStroke.regular),
            ),
            child: Icon(c.icon, size: 18, color: c.cor),
          ),
          const SizedBox(width: BrutSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.titulo,
                    style: BrutType.sans(14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(c.detalhe,
                    style: BrutType.sans(12, color: BrutColors.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
