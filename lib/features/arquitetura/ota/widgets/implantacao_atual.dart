import 'package:flutter/material.dart';

import '../../../../core/theme/brut_colors.dart';
import '../../../../core/theme/brut_spacing.dart';
import '../../../../core/theme/brut_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../widgets/card_titulo.dart';
import 'ota_estilo.dart';

/// Implantação em andamento (ou a última): versões, status, linha do tempo das
/// ondas, contadores de aparelhos e horários.
class ImplantacaoAtual extends StatelessWidget {
  const ImplantacaoAtual({super.key, required this.implantacao});

  final ImplantacaoOta? implantacao;

  @override
  Widget build(BuildContext context) {
    final imp = implantacao;
    if (imp == null) {
      return BrutCard(
        padding: const EdgeInsets.all(BrutSpacing.md),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardTitulo('Implantação atual'),
            BrutEmpty(
              message: 'Nenhuma implantação iniciada desde que a API subiu.',
              icon: Icons.system_update_alt,
            ),
          ],
        ),
      );
    }

    final (cor, fundo) = OtaEstilo.status(imp.status);
    final a = imp.aparelhos;

    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardTitulo('Implantação atual'),
          const SizedBox(height: BrutSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${imp.versaoAnterior} → ${imp.versao}',
                    style: BrutType.mono(22, weight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: BrutSpacing.sm),
              SeloOta(texto: imp.status.label, cor: cor, fundo: fundo),
            ],
          ),
          const SizedBox(height: BrutSpacing.md),
          _LinhaDoTempo(implantacao: imp),
          const SizedBox(height: BrutSpacing.md),
          Row(
            children: [
              _Contador('Elegíveis', a.elegiveis),
              _Contador('Enviados', a.enviados),
              _Contador('Instalados', a.instalados),
            ],
          ),
          const SizedBox(height: BrutSpacing.sm),
          Row(
            children: [
              _Contador('Falhas', a.falhas, alerta: a.falhas > 0),
              _Contador('Pendentes', a.pendentes),
              _Contador('Revertidos', a.revertidos, alerta: a.revertidos > 0),
            ],
          ),
          const SizedBox(height: BrutSpacing.md),
          const Divider(height: 1, thickness: 1, color: BrutColors.lineSoft),
          const SizedBox(height: BrutSpacing.sm),
          if (imp.iniciadaEm != null)
            _Horario('Iniciada às', imp.iniciadaEm!),
          if (imp.status == StatusImplantacao.emAndamento &&
              imp.proximaAvaliacaoEm != null)
            _Horario('Próxima avaliação às', imp.proximaAvaliacaoEm!,
                destaque: true),
          if (imp.encerradaEm != null)
            _Horario('Encerrada às', imp.encerradaEm!),
          const SizedBox(height: BrutSpacing.xs),
          Text(
            'Canário: ${imp.canario.length} postes · '
            'Controle: ${imp.controle.length} postes',
            style: BrutType.sans(12, color: BrutColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Ondas 5% → 25% → 50% → 100%: passadas preenchidas, a atual com borda na cor
/// do status, as futuras só com contorno.
class _LinhaDoTempo extends StatelessWidget {
  const _LinhaDoTempo({required this.implantacao});

  final ImplantacaoOta implantacao;

  @override
  Widget build(BuildContext context) {
    final imp = implantacao;
    final (cor, fundo) = OtaEstilo.status(imp.status);
    final concluida = imp.status == StatusImplantacao.concluida;

    return Row(
      children: [
        for (var i = 0; i < imp.ondas.length; i++) ...[
          if (i > 0)
            Icon(Icons.arrow_right_alt,
                size: 18,
                color: i <= imp.ondaAtual ? BrutColors.ink : BrutColors.inkFaint),
          Expanded(
            child: _Onda(
              pct: imp.ondas[i],
              passada: i < imp.ondaAtual || (concluida && i <= imp.ondaAtual),
              atual: i == imp.ondaAtual && !concluida,
              cor: cor,
              fundo: fundo,
            ),
          ),
        ],
      ],
    );
  }
}

class _Onda extends StatelessWidget {
  const _Onda({
    required this.pct,
    required this.passada,
    required this.atual,
    required this.cor,
    required this.fundo,
  });

  final int pct;
  final bool passada;
  final bool atual;
  final Color cor;
  final Color fundo;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Border borda;
    if (atual) {
      bg = fundo;
      fg = BrutColors.ink;
      borda = Border.all(color: cor, width: BrutStroke.bold);
    } else if (passada) {
      bg = BrutColors.ink;
      fg = BrutColors.paper;
      borda = Border.all(color: BrutColors.ink, width: BrutStroke.regular);
    } else {
      bg = BrutColors.surface;
      fg = BrutColors.inkFaint;
      borda = Border.all(color: BrutColors.lineMedium, width: 1);
    }
    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, border: borda),
      child: Text(
        '$pct%',
        style: BrutType.mono(13,
            weight: atual ? FontWeight.w800 : FontWeight.w600, color: fg),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador(this.rotulo, this.valor, {this.alerta = false});

  final String rotulo;
  final int valor;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo.toUpperCase(), style: BrutType.label(9)),
          const SizedBox(height: 2),
          Text(
            Fmt.inteiro(valor),
            style: BrutType.mono(18,
                weight: FontWeight.w700,
                color: alerta ? BrutColors.destaque : BrutColors.ink),
          ),
        ],
      ),
    );
  }
}

class _Horario extends StatelessWidget {
  const _Horario(this.rotulo, this.quando, {this.destaque = false});

  final String rotulo;
  final DateTime quando;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(rotulo, style: BrutType.sans(12, color: BrutColors.inkMuted)),
          const SizedBox(width: BrutSpacing.xs),
          Text(
            Fmt.horaSegundos(quando),
            style: BrutType.mono(13,
                weight: FontWeight.w700,
                color: destaque ? BrutColors.statusAtencao : BrutColors.ink),
          ),
        ],
      ),
    );
  }
}
