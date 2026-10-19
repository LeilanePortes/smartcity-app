import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../shared/models/models.dart';
import '../mapa_geo.dart';
import 'agrupamento_postes.dart';
import 'poste_marker.dart';

/// Camada de marcadores com agrupamento por distância na tela.
///
/// Abaixo do zoom máximo, postes cujos marcadores ficariam a menos de
/// [kRaioAgrupamentoPx] viram uma bolha com a contagem, e bolhas que ainda se
/// encostariam são fundidas — nada fica sobreposto (ver [agruparPorDistancia]).
/// A rede real é densa (~4 px entre vizinhos no zoom inicial), então o corte
/// por zoom fica só no máximo: lá cada poste é um [PosteMarker] e o toque na
/// bolha sempre chega a ele.
///
/// Uma bolha com postes fora do `NORMAL` ganha borda e selo na cor do pior
/// status, para nenhum problema sumir dentro dela. O poste selecionado nunca é
/// agrupado e fica por cima de tudo.
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

  /// A partir deste zoom não há agrupamento — sempre marcadores individuais.
  static const double _semClusterZoom = MapaGeo.zoomMax;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    // Tolerância para o zoom que chega a 18.4999… depois de animações.
    final agrupar = camera.zoom < _semClusterZoom - 0.01;
    final limite = camera.size;
    const margem = 64.0;

    // Projeta cada poste para a tela e descarta o que está claramente fora.
    // O selecionado fica de fora do agrupamento e é desenhado por último.
    final visiveis = <(PosteResumo, Offset)>[];
    (PosteResumo, Offset)? selecionado;
    for (final p in postes) {
      final o = camera.latLngToScreenOffset(p.posicao);
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

    final filhos = <Widget>[];

    if (!agrupar) {
      for (final (p, o) in visiveis) {
        filhos.add(_posicionado(o, PosteMarker.tamanho, _marcador(p)));
      }
    } else {
      for (final g in agruparPorDistancia(visiveis)) {
        if (g.individual) {
          filhos.add(
              _posicionado(g.centro, PosteMarker.tamanho, _marcador(g.postes.first)));
          continue;
        }
        final centroLatLng = _centroGeografico(g.postes);
        filhos.add(_posicionado(
          g.centro,
          kTamanhoBolhaPx,
          PosteClusterBolha(
            quantidade: g.postes.length,
            piorStatus: g.piorStatus,
            comProblema: g.comProblema,
            onTap: () => onAproximar(centroLatLng, camera.zoom),
          ),
        ));
      }
    }

    if (selecionado case (final p, final o)) {
      filhos.add(_posicionado(o, PosteMarker.tamanho, _marcador(p)));
    }

    return Stack(clipBehavior: Clip.none, children: filhos);
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

  Widget _marcador(PosteResumo p) => PosteMarker(
        status: p.status,
        selecionado: p.id == selecionadoId,
        onTap: () => onSelecionar(p.id),
      );

  Widget _posicionado(Offset centro, double tamanho, Widget child) => Positioned(
        left: centro.dx - tamanho / 2,
        top: centro.dy - tamanho / 2,
        width: tamanho,
        height: tamanho,
        child: child,
      );
}

/// Bolha de agrupamento: quadrado de tinta com a contagem de postes, no mesmo
/// idioma visual do [PosteMarker]. Com postes fora do `NORMAL`, ganha borda na
/// cor do pior status e um selo com quantos estão com problema.
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
                color: BrutColors.ink,
                border: Border.all(
                  color: temProblema ? piorStatus.color : BrutColors.paper,
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
              top: -7,
              right: -7,
              child: Container(
                key: const Key('bolha-selo-problema'),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: BrutSpacing.xs),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: piorStatus.color,
                  border: Border.all(color: BrutColors.paper, width: 1.5),
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
