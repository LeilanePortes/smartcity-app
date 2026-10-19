import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../shared/models/models.dart';
import 'agrupamento_postes.dart' show gravidadeStatus;

/// A partir deste zoom cada poste é um ponto (sem bolhas): a malha inteira
/// aparece e, no zoom inicial, os pontos encostados desenham as ruas.
const double kZoomPontos = 14;

/// Diâmetro do ponto de um poste `NORMAL` por zoom; entre as âncoras o valor é
/// interpolado em linha reta (sem degraus durante o zoom).
const List<(double zoom, double diametro)> kAncorasDiametro = [
  (14, 6),
  (15, 8),
  (16, 10),
  (17, 14),
  (18, 16),
];

/// Postes fora do `NORMAL` ficam um pouco maiores para não sumirem.
const double kAcrescimoProblemaPx = 3;

/// Anel do poste selecionado: folga clara + traço de tinta.
const double kAnelFolgaPx = 2;
const double kAnelLarguraPx = 2.5;

/// Alcance do toque: pelo menos [kRaioToqueMinPx] (≈ meia ponta de dedo) ou
/// meio diâmetro + [kFolgaToquePx], o que for maior.
const double kRaioToqueMinPx = 22;
const double kFolgaToquePx = 8;

/// Vantagem, em px, de um poste fora do `NORMAL` na disputa pelo toque.
const double kBonusProblemaPx = 6;

/// Diâmetro do ponto de um poste `NORMAL` no [zoom].
double diametroBase(double zoom) {
  final primeira = kAncorasDiametro.first;
  if (zoom <= primeira.$1) return primeira.$2;
  for (var i = 1; i < kAncorasDiametro.length; i++) {
    final (z0, d0) = kAncorasDiametro[i - 1];
    final (z1, d1) = kAncorasDiametro[i];
    if (zoom <= z1) return d0 + (d1 - d0) * (zoom - z0) / (z1 - z0);
  }
  return kAncorasDiametro.last.$2;
}

/// Diâmetro do ponto de um poste com [status] no [zoom].
double diametroPonto(double zoom, StatusPoste status) =>
    diametroBase(zoom) +
    (status == StatusPoste.normal ? 0 : kAcrescimoProblemaPx);

/// Um poste pronto para desenhar: posição na tela, diâmetro e destaque.
class PontoPoste {
  const PontoPoste({
    required this.poste,
    required this.centro,
    required this.diametro,
    required this.selecionado,
  });

  final PosteResumo poste;
  final Offset centro;
  final double diametro;
  final bool selecionado;

  bool get comProblema => poste.status != StatusPoste.normal;
}

/// Ordem de desenho (de baixo para cima): normais, manutenção, consumo alto,
/// falha e, por último, o selecionado. Empates mantêm a ordem da lista.
List<PontoPoste> ordenarParaDesenho(
  List<(PosteResumo, Offset)> itens, {
  required double zoom,
  String? selecionadoId,
}) {
  int camada(PosteResumo p) =>
      p.id == selecionadoId ? 100 : gravidadeStatus(p.status);

  final indices = List<int>.generate(itens.length, (i) => i)
    ..sort((a, b) {
      final c = camada(itens[a].$1).compareTo(camada(itens[b].$1));
      return c != 0 ? c : a.compareTo(b);
    });

  return [
    for (final i in indices)
      PontoPoste(
        poste: itens[i].$1,
        centro: itens[i].$2,
        diametro: diametroPonto(zoom, itens[i].$1.status),
        selecionado: itens[i].$1.id == selecionadoId,
      ),
  ];
}

double _alcance(PontoPoste p) =>
    math.max(kRaioToqueMinPx, p.diametro / 2 + kFolgaToquePx);

/// Poste escolhido por um toque em [toque]: entre os pontos ao alcance, o de
/// menor `distância − bônus` (bônus de [kBonusProblemaPx] para fora do
/// `NORMAL`). Em empate vence o desenhado por cima. `null` = nenhum ao alcance.
PosteResumo? posteNoToque(Offset toque, List<PontoPoste> pontos) {
  PontoPoste? melhor;
  var melhorNota = double.infinity;
  for (final p in pontos) {
    final d = (p.centro - toque).distance;
    if (d > _alcance(p)) continue;
    final nota = d - (p.comProblema ? kBonusProblemaPx : 0);
    if (nota <= melhorNota) {
      melhorNota = nota;
      melhor = p;
    }
  }
  return melhor?.poste;
}

/// `true` se algum ponto está ao alcance de [posicao] (decide se a camada
/// captura o toque ou deixa passar para o mapa).
bool algumPosteAoAlcance(Offset posicao, List<PontoPoste> pontos) {
  for (final p in pontos) {
    if ((p.centro - posicao).distance <= _alcance(p)) return true;
  }
  return false;
}

/// Desenha os pontos já ordenados: círculo na cor do status com contorno claro
/// fino; o selecionado ganha anel de tinta com folga clara.
class PontosPostesPainter extends CustomPainter {
  PontosPostesPainter(this.pontos);

  final List<PontoPoste> pontos;

  static final _contorno = Paint()
    ..style = PaintingStyle.stroke
    ..color = BrutColors.surface.withValues(alpha: 0.95);

  @override
  void paint(Canvas canvas, Size size) {
    final preenchimento = Paint()..style = PaintingStyle.fill;
    for (final p in pontos) {
      final r = p.diametro / 2;
      if (p.selecionado) {
        canvas.drawCircle(
          p.centro,
          r + kAnelFolgaPx,
          Paint()..color = BrutColors.surface,
        );
        canvas.drawCircle(
          p.centro,
          r + kAnelFolgaPx + kAnelLarguraPx / 2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = kAnelLarguraPx
            ..color = BrutColors.ink,
        );
      }
      preenchimento.color = p.poste.status.color;
      canvas.drawCircle(p.centro, r, preenchimento);
      _contorno.strokeWidth = p.comProblema ? 1.5 : 1;
      canvas.drawCircle(p.centro, r, _contorno);
    }
  }

  /// Só "pega" toques perto de algum poste; o resto vai para o mapa
  /// (arrastar, zoom e o toque no vazio que limpa a seleção).
  @override
  bool? hitTest(Offset position) => algumPosteAoAlcance(position, pontos);

  @override
  bool shouldRepaint(PontosPostesPainter old) => !identical(old.pontos, pontos);
}
