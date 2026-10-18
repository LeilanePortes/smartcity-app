import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../shared/models/models.dart';
import '../mapa_geo.dart';
import 'poste_marker.dart';

/// Camada de marcadores com agrupamento (cluster) em zoom afastado.
///
/// A partir de [_semClusterZoom] cada poste é um [PosteMarker] individual — cor
/// por status, toque abrindo o bottom sheet, exatamente como antes. Abaixo
/// desse zoom, postes cujas posições de tela caem dentro de [_raioPx] viram
/// uma única bolha com a contagem; tocar a bolha aproxima o mapa até separá-los.
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

  /// Raio, em pixels de tela, dentro do qual os postes são agrupados.
  static const double _raioPx = 44;

  /// A partir deste zoom não há agrupamento — sempre marcadores individuais.
  /// Abaixo do zoom inicial (15.2), de forma que a visão padrão continua
  /// mostrando os postes um a um e o cluster só aparece ao afastar.
  static const double _semClusterZoom = 14.5;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final agrupar = camera.zoom < _semClusterZoom;
    final limite = camera.size;
    const margem = 64.0;

    // Projeta cada poste para a tela e descarta o que está claramente fora.
    final visiveis = <(PosteResumo, Offset)>[];
    for (final p in postes) {
      final o = camera.latLngToScreenOffset(p.posicao);
      if (o.dx < -margem ||
          o.dy < -margem ||
          o.dx > limite.width + margem ||
          o.dy > limite.height + margem) {
        continue;
      }
      visiveis.add((p, o));
    }

    final filhos = <Widget>[];

    if (!agrupar) {
      for (final (p, o) in visiveis) {
        filhos.add(_posicionado(o, PosteMarker.tamanho, _marcador(p)));
      }
    } else {
      final usado = List<bool>.filled(visiveis.length, false);
      for (var i = 0; i < visiveis.length; i++) {
        if (usado[i]) continue;
        usado[i] = true;
        final grupo = <int>[i];
        for (var j = i + 1; j < visiveis.length; j++) {
          if (usado[j]) continue;
          if ((visiveis[j].$2 - visiveis[i].$2).distance <= _raioPx) {
            usado[j] = true;
            grupo.add(j);
          }
        }

        if (grupo.length == 1) {
          final (p, o) = visiveis[i];
          filhos.add(_posicionado(o, PosteMarker.tamanho, _marcador(p)));
          continue;
        }

        var somaLat = 0.0;
        var somaLng = 0.0;
        var centroTela = Offset.zero;
        for (final k in grupo) {
          somaLat += visiveis[k].$1.latitude;
          somaLng += visiveis[k].$1.longitude;
          centroTela += visiveis[k].$2;
        }
        final n = grupo.length;
        final centroLatLng = LatLng(somaLat / n, somaLng / n);
        filhos.add(_posicionado(
          centroTela / n.toDouble(),
          _ClusterBolha.tamanho,
          _ClusterBolha(
            quantidade: n,
            onTap: () => onAproximar(centroLatLng, camera.zoom),
          ),
        ));
      }
    }

    return Stack(clipBehavior: Clip.none, children: filhos);
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
/// idioma visual do [PosteMarker].
class _ClusterBolha extends StatelessWidget {
  const _ClusterBolha({required this.quantidade, required this.onTap});

  final int quantidade;
  final VoidCallback onTap;

  static const double tamanho = 38;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BrutColors.ink,
          border: Border.all(color: BrutColors.paper, width: BrutStroke.regular),
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
    );
  }
}
