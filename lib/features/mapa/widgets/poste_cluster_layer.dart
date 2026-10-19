import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../shared/models/models.dart';
import 'agrupamento_postes.dart';
import 'pontos_postes.dart';

/// Camada dos postes no mapa — um ponto de luz por poste, como nos sistemas de
/// gestão de iluminação.
///
/// A partir de [kZoomPontos] cada poste é um círculo na cor do status (ver
/// [PontosPostesPainter]); no zoom inicial os pontos se encostam e desenham as
/// ruas. Os fora do `NORMAL` são maiores e ficam por cima; o selecionado tem
/// anel e fica por cima de todos. O toque escolhe o poste mais próximo do dedo,
/// com prioridade para os com problema ([posteNoToque]).
///
/// Abaixo de [kZoomPontos] (mapa bem afastado) os postes são agrupados por
/// distância ([agruparPorDistancia]) em bolhas circulares; o toque na bolha
/// aproxima o mapa. O selecionado nunca entra em bolha.
class PosteClusterLayer extends StatelessWidget {
  const PosteClusterLayer({
    super.key,
    required this.postes,
    required this.selecionadoId,
    required this.onSelecionar,
    required this.onAproximar,
  });

  final List<PosteResumo> postes;
  final String? selecionadoId;
  final void Function(String posteId) onSelecionar;
  final void Function(LatLng centro, double zoomAtual) onAproximar;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final zoom = camera.zoom;
    final limite = camera.size;
    const margem = 64.0;

    // Projeta cada poste para a tela e descarta o que está claramente fora.
    final visiveis = <(PosteResumo, Offset)>[];
    (PosteResumo, Offset)? selecionado;
    for (final p in postes) {
      final o = camera.latLngToScreenOffset(LatLng(p.latitude, p.longitude));
      if (o.dx < -margem ||
          o.dy < -margem ||
          o.dx > limite.width + margem ||
          o.dy > limite.height + margem) {
        continue;
      }
      if (p.id == selecionadoId) {
        selecionado = (p, o);
      } else {
        visiveis.add((p, o));
      }
    }

    if (zoom >= kZoomPontos) {
      return _CamadaPontos(
        pontos: ordenarParaDesenho(
          [...visiveis, ?selecionado],
          zoom: zoom,
          selecionadoId: selecionadoId,
        ),
        onSelecionar: onSelecionar,
      );
    }

    // Mapa afastado: bolhas por distância; postes sozinhos continuam pontos.
    final individuais = <(PosteResumo, Offset)>[];
    final bolhas = <Widget>[];
    for (final g in agruparPorDistancia(
      visiveis,
      tamanhoIndividual: diametroBase(zoom),
    )) {
      if (g.individual) {
        individuais.add((g.postes.first, g.centro));
        continue;
      }
      final centroLatLng = _centroGeografico(g.postes);
      bolhas.add(Positioned(
        left: g.centro.dx - kTamanhoBolhaPx / 2,
        top: g.centro.dy - kTamanhoBolhaPx / 2,
        width: kTamanhoBolhaPx,
        height: kTamanhoBolhaPx,
        child: PosteClusterBolha(
          quantidade: g.postes.length,
          piorStatus: g.piorStatus,
          comProblema: g.comProblema,
          onTap: () => onAproximar(centroLatLng, zoom),
        ),
      ));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: _CamadaPontos(
            pontos: ordenarParaDesenho(individuais, zoom: zoom),
            onSelecionar: onSelecionar,
          ),
        ),
        ...bolhas,
        if (selecionado != null)
          Positioned.fill(
            child: _CamadaPontos(
              pontos: ordenarParaDesenho(
                [selecionado],
                zoom: zoom,
                selecionadoId: selecionadoId,
              ),
              onSelecionar: onSelecionar,
            ),
          ),
      ],
    );
  }

  static LatLng _centroGeografico(List<PosteResumo> postes) {
    var lat = 0.0;
    var lng = 0.0;
    for (final p in postes) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / postes.length, lng / postes.length);
  }
}

/// Pontos desenhados por um único painter + um único detector de toque, que só
/// captura toques ao alcance de algum poste.
class _CamadaPontos extends StatelessWidget {
  const _CamadaPontos({required this.pontos, required this.onSelecionar});

  final List<PontoPoste> pontos;
  final void Function(String posteId) onSelecionar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTapUp: (d) {
        final p = posteNoToque(d.localPosition, pontos);
        if (p != null) onSelecionar(p.id);
      },
      child: CustomPaint(
        key: const Key('mapa-pontos-postes'),
        size: Size.infinite,
        painter: PontosPostesPainter(pontos),
      ),
    );
  }
}

/// Bolha de agrupamento (mapa afastado): círculo de tinta com a contagem. Com
/// postes fora do `NORMAL`, ganha anel na cor do pior status e um selo redondo
/// com quantos estão com problema.
class PosteClusterBolha extends StatelessWidget {
  const PosteClusterBolha({
    super.key,
    required this.quantidade,
    required this.piorStatus,
    required this.comProblema,
    required this.onTap,
  });

  final int quantidade;
  final StatusPoste piorStatus;
  final int comProblema;
  final VoidCallback onTap;

  bool get temProblema => comProblema > 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrutColors.ink,
                border: Border.all(
                  color: temProblema ? piorStatus.color : BrutColors.surface,
                  width: temProblema ? BrutStroke.bold : BrutStroke.regular,
                ),
              ),
              child: Text(
                '$quantidade',
                style: BrutType.mono(
                  13,
                  weight: FontWeight.w700,
                  color: BrutColors.paper,
                ),
              ),
            ),
          ),
          if (temProblema)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                key: const Key('bolha-selo-problema'),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: BrutSpacing.xs),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: piorStatus.color,
                  border: Border.all(color: BrutColors.surface, width: 1.5),
                ),
                child: Text(
                  '$comProblema',
                  style: BrutType.mono(
                    10,
                    weight: FontWeight.w700,
                    color: BrutColors.paper,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
