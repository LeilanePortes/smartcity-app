import 'package:flutter/material.dart';

import '../../../../core/theme/brut_colors.dart';
import '../../../../core/theme/brut_spacing.dart';
import '../../../../core/theme/brut_typography.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../widgets/card_titulo.dart';

/// Um botão por versão do catálogo para iniciar a implantação, e "Reverter
/// frota" enquanto houver uma em andamento.
class ImplantarVersao extends StatelessWidget {
  const ImplantarVersao({
    super.key,
    required this.estado,
    required this.enviando,
    required this.onImplantar,
    required this.onReverter,
  });

  final EstadoOta estado;

  /// Uma ação (POST) está em curso.
  final bool enviando;
  final void Function(VersaoFirmware versao) onImplantar;
  final VoidCallback onReverter;

  @override
  Widget build(BuildContext context) {
    final bloqueado = enviando || estado.emAndamento || !estado.otaDisponivel;
    final predominante = estado.versaoPredominante;

    String? aviso;
    if (!estado.otaDisponivel) {
      aviso = 'OTA só funciona no modo camadas — a API está no modo de reserva.';
    } else if (estado.emAndamento) {
      aviso = 'Implantação em andamento: novas versões ficam bloqueadas até ela '
          'concluir ou ser revertida.';
    }

    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardTitulo('Implantar versão'),
          if (aviso != null) ...[
            const SizedBox(height: BrutSpacing.sm),
            Text(
              aviso,
              style: BrutType.sans(12,
                  weight: FontWeight.w600,
                  color: estado.otaDisponivel
                      ? BrutColors.statusAtencao
                      : BrutColors.destaque),
            ),
          ],
          const SizedBox(height: BrutSpacing.sm),
          for (var i = 0; i < estado.catalogo.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: BrutColors.lineSoft),
            _LinhaVersao(
              versao: estado.catalogo[i],
              emCampo: estado.catalogo[i].versao == predominante,
              onImplantar: bloqueado
                  ? null
                  : () => onImplantar(estado.catalogo[i]),
            ),
          ],
          if (estado.emAndamento) ...[
            const SizedBox(height: BrutSpacing.md),
            BrutButton(
              key: const Key('ota-reverter'),
              label: 'Reverter frota',
              icon: Icons.undo,
              variant: BrutButtonVariant.danger,
              expand: true,
              loading: enviando,
              onPressed: enviando ? null : onReverter,
            ),
          ],
        ],
      ),
    );
  }
}

class _LinhaVersao extends StatelessWidget {
  const _LinhaVersao({
    required this.versao,
    required this.emCampo,
    required this.onImplantar,
  });

  final VersaoFirmware versao;
  final bool emCampo;
  final VoidCallback? onImplantar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BrutSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(versao.versao,
                        style: BrutType.mono(16, weight: FontWeight.w700)),
                    if (emCampo) ...[
                      const SizedBox(width: BrutSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        color: BrutColors.ink,
                        child: Text('EM CAMPO',
                            style: BrutType.mono(9,
                                weight: FontWeight.w700,
                                color: BrutColors.paper,
                                letterSpacing: 0.8)),
                      ),
                    ],
                  ],
                ),
                if (versao.descricao.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(versao.descricao,
                      style: BrutType.sans(12, color: BrutColors.inkMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: BrutSpacing.sm),
          BrutButton(
            key: Key('ota-implantar-${versao.versao}'),
            label: 'Implantar',
            variant: BrutButtonVariant.secondary,
            onPressed: onImplantar,
          ),
        ],
      ),
    );
  }
}
