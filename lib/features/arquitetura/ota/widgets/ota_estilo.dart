import 'package:flutter/material.dart';

import '../../../../core/theme/brut_colors.dart';
import '../../../../core/theme/brut_spacing.dart';
import '../../../../core/theme/brut_typography.dart';
import '../../../../shared/models/models.dart';

/// Cores da seção OTA (status da implantação, decisões e versões).
abstract final class OtaEstilo {
  static (Color cor, Color fundo) status(StatusImplantacao s) => switch (s) {
        StatusImplantacao.emAndamento =>
          (BrutColors.statusAtencao, BrutColors.statusAtencaoSoft),
        StatusImplantacao.concluida =>
          (BrutColors.statusNormal, BrutColors.statusNormalSoft),
        StatusImplantacao.revertida =>
          (BrutColors.destaque, BrutColors.statusFalhaSoft),
        StatusImplantacao.desconhecido =>
          (BrutColors.inkFaint, BrutColors.statusManutencaoSoft),
      };

  static (Color cor, Color fundo) decisao(DecisaoPortao d) => switch (d) {
        DecisaoPortao.avancar =>
          (BrutColors.statusNormal, BrutColors.statusNormalSoft),
        DecisaoPortao.estender =>
          (BrutColors.statusAtencao, BrutColors.statusAtencaoSoft),
        DecisaoPortao.concluir => (BrutColors.ink, BrutColors.statusManutencaoSoft),
        DecisaoPortao.reverter =>
          (BrutColors.destaque, BrutColors.statusFalhaSoft),
        DecisaoPortao.desconhecida =>
          (BrutColors.inkFaint, BrutColors.statusManutencaoSoft),
      };

  static const _outras = [
    BrutColors.lumBaixa,
    BrutColors.statusAtencao,
    BrutColors.statusManutencao,
    BrutColors.lumMedia,
  ];

  /// Versão nova da implantação em destaque, a predominante em tinta,
  /// `desconhecida` em cinza claro e as demais numa paleta fixa.
  static Color versao(String versao, EstadoOta estado, int indice) {
    if (versao == 'desconhecida') return BrutColors.inkFaint;
    if (versao == estado.implantacao?.versao) return BrutColors.destaque;
    if (versao == estado.versaoPredominante) return BrutColors.ink;
    return _outras[indice % _outras.length];
  }
}

/// Selo com ponto + rótulo em caixa alta, borda e fundo tênue.
class SeloOta extends StatelessWidget {
  const SeloOta({
    super.key,
    required this.texto,
    required this.cor,
    required this.fundo,
  });

  final String texto;
  final Color cor;
  final Color fundo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BrutSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        border: Border.all(color: cor, width: BrutStroke.thin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            texto.toUpperCase(),
            style: BrutType.mono(11,
                weight: FontWeight.w700, color: BrutColors.ink, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}
