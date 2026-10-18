import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../shared/models/models.dart';
import '../mapa_geo.dart';

/// Fonte única do gradiente do heatmap de luminosidade.
///
/// Escala de luminosidade do PRD §5.1: azul-escuro no piso de 50% → amarelo no
/// pico de 100%. Alimenta tanto os borrões da camada [LuminosityHeatmapLayer]
/// quanto o widget [HeatmapLegenda] — os dois nunca devem divergir entre si.
abstract final class HeatmapGradiente {
  static const double _lumPiso = 50;

  /// Fração 0–1 da escala para uma luminosidade [lum] (0–100).
  static double _t(double lum) =>
      ((lum - _lumPiso) / (100 - _lumPiso)).clamp(0.0, 1.0);

  /// Cor cheia do borrão para uma luminosidade [lum]. A camada aplica a
  /// opacidade e o [BlendMode.plus] que fazem os borrões se acumularem.
  static Color corPara(double lum) =>
      Color.lerp(BrutColors.lumBaixa, BrutColors.lumAlta, _t(lum))!;

  /// Faixa 50% → 100% para a legenda (mesma escala da camada).
  static const LinearGradient legenda = LinearGradient(
    colors: [BrutColors.lumBaixa, BrutColors.lumMedia, BrutColors.lumAlta],
  );
}

/// Camada de heatmap de luminosidade (PRD §5.1) desenhada por cima do mapa.
///
/// Overlay customizado (sem plugin): projeta cada poste para pixels da tela via
/// a [MapCamera] e pinta um borrão radial cuja cor varia de ~50% (piso, azul
/// escuro) a 100% (pico, amarelo). Os borrões acumulam com [BlendMode.plus].
class LuminosityHeatmapLayer extends StatelessWidget {
  const LuminosityHeatmapLayer({super.key, required this.postes});

  final List<PosteResumo> postes;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _HeatPainter(camera: camera, postes: postes),
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter({required this.camera, required this.postes});

  final MapCamera camera;
  final List<PosteResumo> postes;

  @override
  void paint(Canvas canvas, Size size) {
    // Raio do borrão cresce com o zoom (aprox. dobra a cada nível).
    final exp = (camera.zoom.round() - 13).clamp(0, 6);
    final raio = (14.0 * (1 << exp)).clamp(28.0, 180.0).toDouble();
    final margem = raio * 2;
    final rect = Offset.zero & size;

    canvas.saveLayer(rect, Paint());
    for (final p in postes) {
      // Postes sem luz acesa (manutenção) não contribuem.
      if (p.luminosidadeAtual <= 0) continue;

      final o = camera.latLngToScreenOffset(p.posicao);
      if (o.dx < -margem ||
          o.dy < -margem ||
          o.dx > size.width + margem ||
          o.dy > size.height + margem) {
        continue;
      }

      final cor = HeatmapGradiente.corPara(p.luminosidadeAtual);
      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [cor.withValues(alpha: 0.42), cor.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: o, radius: raio));
      canvas.drawCircle(o, raio, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.camera.center != camera.center ||
      old.camera.zoom != camera.zoom ||
      old.camera.rotation != camera.rotation ||
      !identical(old.postes, postes);
}

/// Legenda 50% → 100% para acompanhar o heatmap. Usa a mesma [HeatmapGradiente]
/// da camada, então nunca desalinha da rampa desenhada no mapa.
class HeatmapLegenda extends StatelessWidget {
  const HeatmapLegenda({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: BrutColors.surface,
        border: Border.all(color: BrutColors.line, width: BrutStroke.regular),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LUMINOSIDADE', style: BrutType.label(9)),
          const SizedBox(height: 6),
          Container(
            width: 84,
            height: 8,
            decoration: BoxDecoration(
              border: Border.all(color: BrutColors.line, width: 1),
              gradient: HeatmapGradiente.legenda,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 84,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('50%', style: BrutType.mono(9, color: BrutColors.inkMuted)),
                Text('100%',
                    style: BrutType.mono(9, color: BrutColors.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
