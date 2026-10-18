import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/realtime/realtime_providers.dart';
import '../../core/theme/brut_colors.dart';
import '../../core/theme/brut_spacing.dart';
import '../../core/theme/brut_typography.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../detalhe_poste/detalhe_poste_screen.dart';
import 'mapa_geo.dart';
import 'mapa_providers.dart';
import 'widgets/busca_field.dart';
import 'widgets/filtro_status_bar.dart';
import 'widgets/luminosity_heatmap_layer.dart';
import 'widgets/poste_bottom_sheet.dart';
import 'widgets/poste_cluster_layer.dart';

/// Fase 2 · Tela Mapa da cidade.
class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  final _mapController = MapController();

  /// Poste que ainda não foi centralizado porque a lista não tinha chegado
  /// quando a seleção veio de outra tela (detalhe / ranking de KPIs).
  String? _centralizarPendente;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _abrirDetalhe(String posteId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalhePosteScreen(posteId: posteId),
      ),
    );
  }

  /// Move o mapa até o poste. Se ainda não está na lista, guarda para depois.
  void _centralizarNoPoste(String id, List<PosteResumo> postes) {
    for (final p in postes) {
      if (p.id == id) {
        final zoom = _mapController.camera.zoom;
        _mapController.move(p.posicao, zoom < 16 ? 16 : zoom);
        _centralizarPendente = null;
        return;
      }
    }
    _centralizarPendente = id;
  }

  void _ajustarZoom(double delta) {
    final camera = _mapController.camera;
    final novo = (camera.zoom + delta).clamp(MapaGeo.zoomMin, MapaGeo.zoomMax);
    _mapController.move(camera.center, novo);
  }

  /// Toque numa bolha de cluster: aproxima o mapa no centro do grupo até
  /// separar os marcadores individuais.
  void _aproximarCluster(LatLng centro, double zoomAtual) {
    final novo = (zoomAtual + 2).clamp(MapaGeo.zoomMin, MapaGeo.zoomMax);
    _mapController.move(centro, novo);
  }

  @override
  Widget build(BuildContext context) {
    final postesAsync = ref.watch(postesMapaProvider);
    final selecionadoId = ref.watch(posteSelecionadoProvider);
    final heatmapOn = ref.watch(heatmapVisivelProvider);
    final aoVivo = ref.watch(mapaAoVivoProvider);

    final restPostes = postesAsync.value ?? const <PosteResumo>[];
    // Marcadores refletem o estado ao vivo quando disponível (fase 5).
    final postes = aoVivo.isEmpty
        ? restPostes
        : [for (final p in restPostes) aoVivo[p.id] ?? p];
    PosteResumo? selecionado;
    if (selecionadoId != null) {
      for (final p in postes) {
        if (p.id == selecionadoId) {
          selecionado = p;
          break;
        }
      }
    }

    // Sincroniza seleção (mapa ⇄ detalhe ⇄ KPIs): quando a seleção muda por
    // outra tela, centraliza o mapa no poste.
    ref.listen(posteSelecionadoProvider, (anterior, atual) {
      if (atual != null && atual != anterior) {
        _centralizarNoPoste(atual, postes);
      }
    });
    // Tenta resolver uma centralização pendente assim que a lista chega.
    if (_centralizarPendente != null && postes.isNotEmpty) {
      final pendente = _centralizarPendente!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _centralizarNoPoste(pendente, postes);
      });
    }

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: _PainelTopo(
            total: postes.length,
            carregando: postesAsync.isLoading,
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: MapaGeo.centroItaguari,
                  initialZoom: MapaGeo.zoomInicial,
                  minZoom: MapaGeo.zoomMin,
                  maxZoom: MapaGeo.zoomMax,
                  onTap: (_, _) =>
                      ref.read(posteSelecionadoProvider.notifier).limpar(),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapaGeo.tileUrl,
                    subdomains: MapaGeo.tileSubdominios,
                    userAgentPackageName: MapaGeo.tileUserAgent,
                    tileProvider: NetworkTileProvider(),
                  ),
                  if (heatmapOn)
                    RepaintBoundary(
                      child: LuminosityHeatmapLayer(postes: postes),
                    ),
                  PosteClusterLayer(
                    postes: postes,
                    selecionadoId: selecionadoId,
                    onSelecionar: (id) => ref
                        .read(posteSelecionadoProvider.notifier)
                        .selecionar(id),
                    onAproximar: _aproximarCluster,
                  ),
                ],
              ),

              // Controles do mapa (zoom + heatmap), canto superior direito.
              Positioned(
                right: BrutSpacing.md,
                top: BrutSpacing.md,
                child: _ControlesMapa(
                  heatmapOn: heatmapOn,
                  onZoomIn: () => _ajustarZoom(1),
                  onZoomOut: () => _ajustarZoom(-1),
                  onToggleHeatmap: () =>
                      ref.read(heatmapVisivelProvider.notifier).alternar(),
                ),
              ),

              // Legenda do heatmap, canto inferior esquerdo.
              if (heatmapOn)
                const Positioned(
                  left: BrutSpacing.md,
                  bottom: BrutSpacing.md,
                  child: HeatmapLegenda(),
                ),

              const Positioned(right: 0, bottom: 0, child: _AtribuicaoOsm()),

              // Erro de carga (quando não há dados anteriores para mostrar).
              if (postesAsync.hasError && postes.isEmpty)
                Positioned.fill(
                  child: ColoredBox(
                    color: BrutColors.paper,
                    child: BrutError(
                      error: postesAsync.error!,
                      onRetry: () => ref.invalidate(postesMapaProvider),
                    ),
                  ),
                ),

              // Bottom sheet do poste selecionado.
              if (selecionado case final sel?)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: PosteBottomSheet(
                    poste: sel,
                    onFechar: () =>
                        ref.read(posteSelecionadoProvider.notifier).limpar(),
                    onVerDetalhe: () => _abrirDetalhe(sel.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Painel branco fixo no topo: identificação da rede, contador, busca e filtros.
class _PainelTopo extends ConsumerWidget {
  const _PainelTopo({required this.total, required this.carregando});

  final int total;
  final bool carregando;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtroAtivo = ref.watch(mapaFiltroProvider).ativo;
    final conectado = ref.watch(aoVivoProvider);
    final contador =
        filtroAtivo ? '$total / $kTotalPostesRede' : '$total';

    return Container(
      decoration: const BoxDecoration(
        color: BrutColors.surface,
        border: Border(
          bottom: BorderSide(color: BrutColors.line, width: BrutStroke.regular),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        BrutSpacing.md,
        BrutSpacing.md,
        BrutSpacing.md,
        BrutSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REDE DE ILUMINAÇÃO', style: BrutType.label(10)),
                    const SizedBox(height: 2),
                    Text(
                      'Itaguari · GO',
                      style: BrutType.sans(19, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (carregando) ...[
                        const SizedBox(
                          width: 11,
                          height: 11,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BrutColors.ink,
                          ),
                        ),
                        const SizedBox(width: BrutSpacing.sm),
                      ],
                      Text(
                        contador,
                        style: BrutType.mono(22, weight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Text('POSTES', style: BrutType.label(9)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LiveIndicator(active: conectado),
                ],
              ),
            ],
          ),
          const SizedBox(height: BrutSpacing.md),
          const BuscaField(),
          const SizedBox(height: BrutSpacing.sm),
          const FiltroStatusBar(),
        ],
      ),
    );
  }
}

/// Coluna de controles sobre o mapa: zoom + / − e alternância do heatmap.
class _ControlesMapa extends StatelessWidget {
  const _ControlesMapa({
    required this.heatmapOn,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleHeatmap,
  });

  final bool heatmapOn;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleHeatmap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: BrutColors.surface,
            border: Border.all(color: BrutColors.line, width: BrutStroke.regular),
          ),
          child: Column(
            children: [
              _BotaoControle(icon: Icons.add, onTap: onZoomIn),
              const _DivisorControle(),
              _BotaoControle(icon: Icons.remove, onTap: onZoomOut),
            ],
          ),
        ),
        const SizedBox(height: BrutSpacing.sm),
        _BotaoControle(
          icon: Icons.blur_on,
          ativo: heatmapOn,
          onTap: onToggleHeatmap,
          comBorda: true,
        ),
      ],
    );
  }
}

class _DivisorControle extends StatelessWidget {
  const _DivisorControle();

  @override
  Widget build(BuildContext context) =>
      Container(width: 38, height: BrutStroke.regular, color: BrutColors.line);
}

class _BotaoControle extends StatelessWidget {
  const _BotaoControle({
    required this.icon,
    required this.onTap,
    this.ativo = false,
    this.comBorda = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool ativo;
  final bool comBorda;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ativo ? BrutColors.ink : BrutColors.surface,
          border: comBorda
              ? Border.all(color: BrutColors.line, width: BrutStroke.regular)
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: ativo ? BrutColors.paper : BrutColors.ink,
        ),
      ),
    );
  }
}

class _AtribuicaoOsm extends StatelessWidget {
  const _AtribuicaoOsm();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BrutColors.surface.withValues(alpha: 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        MapaGeo.atribuicao,
        style: BrutType.sans(9, color: BrutColors.inkMuted),
      ),
    );
  }
}
