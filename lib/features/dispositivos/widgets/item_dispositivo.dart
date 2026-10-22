import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'selo_conexao.dart';

/// Linha da lista de dispositivos: código, nome, local, selo de conexão,
/// domínio e firmware.
class ItemDispositivo extends StatelessWidget {
  const ItemDispositivo({super.key, required this.dispositivo, this.onTap});

  final Dispositivo dispositivo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final d = dispositivo;
    return BrutCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: BrutSpacing.md,
        vertical: BrutSpacing.sm,
      ),
      accent: d.conexao.online ? BrutColors.statusNormal : BrutColors.statusFalha,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        d.codigo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BrutType.mono(14, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: BrutSpacing.sm),
                    SeloConexao(online: d.conexao.online, compacto: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  d.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrutType.sans(13),
                ),
                Text(
                  d.area == null ? d.site.nome : '${d.site.nome} · ${d.area!.nome}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrutType.sans(11, color: BrutColors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: BrutSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: BrutColors.lineMedium, width: 1),
                ),
                child: Text(
                  d.dominio.nome,
                  style: BrutType.mono(9,
                      weight: FontWeight.w600, color: BrutColors.ink),
                ),
              ),
              const SizedBox(height: 4),
              Text('fw ${d.firmware}',
                  style: BrutType.mono(10, color: BrutColors.inkMuted)),
            ],
          ),
          if (onTap != null) ...[
            const SizedBox(width: BrutSpacing.xs),
            const Icon(Icons.chevron_right, size: 20, color: BrutColors.ink),
          ],
        ],
      ),
    );
  }
}
