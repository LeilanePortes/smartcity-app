import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartcity_app/core/theme/brut_theme.dart';
import 'package:smartcity_app/features/mapa/mapa_geo.dart';
import 'package:smartcity_app/features/mapa/widgets/poste_cluster_layer.dart';
import 'package:smartcity_app/features/mapa/widgets/pontos_postes.dart';
import 'package:smartcity_app/shared/models/models.dart';

const _centro = MapaGeo.centroItaguari;

/// Postes a ~11 m um do outro (≈ 3 px no zoom inicial), como na rede real.
/// O primeiro fica exatamente no centro do mapa.
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
  late List<String> selecionados;
  late List<(LatLng, double)> aproximacoes;

  setUp(() {
    selecionados = [];
    aproximacoes = [];
  });

  Future<void> montar(
    WidgetTester tester,
    List<PosteResumo> postes, {
    double zoom = MapaGeo.zoomInicial,
    String? selecionadoId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BrutTheme.build(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 412,
              height: 560,
              child: FlutterMap(
                options: MapOptions(initialCenter: _centro, initialZoom: zoom),
                children: [
                  PosteClusterLayer(
                    postes: postes,
                    selecionadoId: selecionadoId,
                    onSelecionar: selecionados.add,
                    onAproximar: (c, z) => aproximacoes.add((c, z)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  List<PontoPoste> pontosDesenhados(WidgetTester tester) =>
      (tester
                  .widget<CustomPaint>(
                      find.byKey(const Key('mapa-pontos-postes')).first)
                  .painter!
              as PontosPostesPainter)
          .pontos;

  Offset centroDoMapa(WidgetTester tester) =>
      tester.getCenter(find.byType(FlutterMap));

  testWidgets('zoom inicial: todos os postes como pontos, sem bolhas',
      (tester) async {
    await montar(tester, _densos(List.filled(5, StatusPoste.normal)));

    expect(find.byType(PosteClusterBolha), findsNothing);
    final pontos = pontosDesenhados(tester);
    expect(pontos, hasLength(5));
    expect(pontos.first.diametro, closeTo(diametroBase(MapaGeo.zoomInicial), 1e-9));
  });

  testWidgets('fora do NORMAL por cima e maiores; selecionado por último',
      (tester) async {
    await montar(
      tester,
      _densos([
        StatusPoste.falhaOffline,
        StatusPoste.normal,
        StatusPoste.consumoAlto,
        StatusPoste.normal,
      ]),
      selecionadoId: 'p1',
    );

    final pontos = pontosDesenhados(tester);
    expect(pontos.map((p) => p.poste.id), ['p3', 'p2', 'p0', 'p1']);
    expect(pontos.last.selecionado, isTrue);
    expect(pontos[1].diametro, greaterThan(pontos[0].diametro));
  });

  testWidgets('toque no poste seleciona o mais próximo', (tester) async {
    await montar(tester, _densos(List.filled(3, StatusPoste.normal)));

    await tester.tapAt(centroDoMapa(tester));
    expect(selecionados, ['p0']);
  });

  testWidgets('pontos sobrepostos: o toque prioriza o poste com problema',
      (tester) async {
    // p0 (normal) no centro; p1 (falha) a ~3 px.
    await montar(
        tester, _densos([StatusPoste.normal, StatusPoste.falhaOffline]));

    await tester.tapAt(centroDoMapa(tester));
    expect(selecionados, ['p1']);
  });

  testWidgets('toque longe dos postes não seleciona nada', (tester) async {
    await montar(tester, _densos(List.filled(3, StatusPoste.normal)));

    await tester.tapAt(centroDoMapa(tester) + const Offset(150, 150));
    // O toque passa para o próprio mapa, que espera 250 ms por um duplo toque.
    await tester.pump(const Duration(milliseconds: 300));
    expect(selecionados, isEmpty);
  });

  testWidgets('abaixo do zoom 14: bolha circular com selo de problema',
      (tester) async {
    await montar(
      tester,
      _densos([
        StatusPoste.normal,
        StatusPoste.consumoAlto,
        StatusPoste.normal,
        StatusPoste.falhaOffline,
        StatusPoste.normal,
      ]),
      zoom: 13.5,
    );

    final bolha =
        tester.widget<PosteClusterBolha>(find.byType(PosteClusterBolha));
    expect(bolha.quantidade, 5);
    expect(bolha.piorStatus, StatusPoste.falhaOffline);
    expect(bolha.comProblema, 2);
    final selo = find.byKey(const Key('bolha-selo-problema'));
    expect(find.descendant(of: selo, matching: find.text('2')), findsOneWidget);

    await tester.tap(find.byType(PosteClusterBolha));
    expect(aproximacoes, hasLength(1));
    expect(aproximacoes.single.$2, closeTo(13.5, 0.001));
    expect(aproximacoes.single.$1.latitude,
        closeTo(_centro.latitude + 0.0002, 1e-9));
  });

  testWidgets('abaixo do zoom 14: o selecionado fica fora da bolha',
      (tester) async {
    await montar(
      tester,
      _densos(List.filled(5, StatusPoste.normal)),
      zoom: 13.5,
      selecionadoId: 'p2',
    );

    expect(find.text('4'), findsOneWidget);
    final camadas = find.byKey(const Key('mapa-pontos-postes'));
    final selecionado = (tester.widget<CustomPaint>(camadas.last).painter!
            as PontosPostesPainter)
        .pontos;
    expect(selecionado.single.poste.id, 'p2');
    expect(selecionado.single.selecionado, isTrue);
  });
}
