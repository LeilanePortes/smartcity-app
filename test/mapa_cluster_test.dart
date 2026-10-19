import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartcity_app/core/theme/brut_theme.dart';
import 'package:smartcity_app/features/mapa/mapa_geo.dart';
import 'package:smartcity_app/features/mapa/widgets/poste_cluster_layer.dart';
import 'package:smartcity_app/features/mapa/widgets/poste_marker.dart';
import 'package:smartcity_app/shared/models/models.dart';

const _centro = MapaGeo.centroItaguari;

/// Postes a ~10 m um do outro (≈ 2–3 px no zoom inicial), como na rede real.
List<PosteResumo> _densos(List<StatusPoste> status) => [
      for (var i = 0; i < status.length; i++)
        PosteResumo(
          id: 'p$i',
          codigo: 'P-${i + 1}',
          endereco: 'Rua X, $i',
          bairro: 'Centro',
          latitude: _centro.latitude + i * 0.0001,
          longitude: _centro.longitude,
          status: status[i],
          luminosidadeAtual: 50,
          consumoInstantaneoKw: 0.05,
          ultimaLeituraEm: null,
        ),
    ];

void main() {
  Future<void> montar(
    WidgetTester tester,
    List<PosteResumo> postes, {
    double zoom = MapaGeo.zoomInicial,
    String? selecionadoId,
    void Function(LatLng, double)? onAproximar,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BrutTheme.build(),
        home: Scaffold(
          body: SizedBox(
            width: 412,
            height: 560,
            child: FlutterMap(
              options: MapOptions(initialCenter: _centro, initialZoom: zoom),
              children: [
                PosteClusterLayer(
                  postes: postes,
                  selecionadoId: selecionadoId,
                  onSelecionar: (_) {},
                  onAproximar: onAproximar ?? (_, _) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('zoom inicial: postes densos viram uma bolha, sem marcadores',
      (tester) async {
    await montar(tester, _densos(List.filled(5, StatusPoste.normal)));

    expect(find.byType(PosteClusterBolha), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.byType(PosteMarker), findsNothing);
    // Só normais: sem selo de problema.
    expect(find.byKey(const Key('bolha-selo-problema')), findsNothing);
  });

  testWidgets('bolha com problema mostra borda e selo do pior status',
      (tester) async {
    await montar(tester, _densos([
      StatusPoste.normal,
      StatusPoste.consumoAlto,
      StatusPoste.normal,
      StatusPoste.falhaOffline,
      StatusPoste.normal,
    ]));

    final bolha =
        tester.widget<PosteClusterBolha>(find.byType(PosteClusterBolha));
    expect(bolha.quantidade, 5);
    expect(bolha.piorStatus, StatusPoste.falhaOffline);
    expect(bolha.comProblema, 2);

    final selo = find.byKey(const Key('bolha-selo-problema'));
    expect(selo, findsOneWidget);
    expect(find.descendant(of: selo, matching: find.text('2')), findsOneWidget);
    expect(
      (tester.widget<Container>(selo).decoration! as BoxDecoration).color,
      StatusPoste.falhaOffline.color,
    );
  });

  testWidgets('poste selecionado fica fora da bolha', (tester) async {
    await montar(
      tester,
      _densos(List.filled(5, StatusPoste.normal)),
      selecionadoId: 'p2',
    );

    expect(find.byType(PosteMarker), findsOneWidget);
    expect(tester.widget<PosteMarker>(find.byType(PosteMarker)).selecionado,
        isTrue);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('zoom máximo: sempre marcadores individuais', (tester) async {
    await montar(
      tester,
      _densos(List.filled(5, StatusPoste.normal)),
      zoom: MapaGeo.zoomMax,
    );

    expect(find.byType(PosteClusterBolha), findsNothing);
    expect(find.byType(PosteMarker), findsNWidgets(5));
  });

  testWidgets('toque na bolha pede para aproximar no centro do grupo',
      (tester) async {
    LatLng? centro;
    double? zoomAtual;
    await montar(
      tester,
      _densos(List.filled(3, StatusPoste.normal)),
      onAproximar: (c, z) {
        centro = c;
        zoomAtual = z;
      },
    );

    await tester.tap(find.byType(PosteClusterBolha));
    expect(zoomAtual, closeTo(MapaGeo.zoomInicial, 0.001));
    expect(centro!.latitude, closeTo(_centro.latitude + 0.0001, 1e-9));
    expect(centro!.longitude, closeTo(_centro.longitude, 1e-9));
  });
}
