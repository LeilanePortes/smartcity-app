import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartcity_app/app.dart';
import 'package:smartcity_app/core/realtime/realtime_client.dart';
import 'package:smartcity_app/core/realtime/realtime_providers.dart';
import 'package:smartcity_app/shared/data/smartcity_api.dart';

import 'support/fake_smartcity_api.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  Future<void> montarApp(WidgetTester tester) async {
    final realtime =
        RealtimeClient(baseUrl: 'http://fake', namespace: '/tempo-real');
    addTearDown(realtime.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          smartcityApiProvider.overrideWithValue(FakeSmartcityApi()),
          realtimeClientProvider.overrideWithValue(realtime),
        ],
        child: const SmartcityApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('mapa → bottom sheet → detalhe → volta ao mapa', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await montarApp(tester);

    // Começa no mapa, com o contador de postes.
    expect(find.text('POSTES'), findsOneWidget);

    // Abre o bottom sheet tocando no ponto do P-001, que o fake coloca no
    // centro do mapa (os pontos são desenhados por um único painter).
    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ver detalhe do poste'), findsOneWidget);

    // Vai para o detalhe.
    await tester.tap(find.text('Ver detalhe do poste'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('AGENDAR MANUTENÇÃO'), findsOneWidget);
    expect(find.text('Histórico de consumo'.toUpperCase()), findsOneWidget);

    // "Ver no mapa" volta para a aba do mapa.
    await tester.tap(find.text('VER NO MAPA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('POSTES'), findsOneWidget);
  });

  testWidgets('navegação Mapa / KPIs / Arquitetura → design system / Dispositivos',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await montarApp(tester);

    await tester.tap(find.text('KPIs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('MAIOR CONSUMO'), findsOneWidget);
    expect(find.text('POSTES POR STATUS'), findsOneWidget);

    // Toque no item do ranking abre o detalhe do poste.
    await tester.tap(find.text('P-002').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Rua Anhanguera, 112'), findsWidgets);

    // Volta (o detalhe traz o próprio botão de voltar, sem AppBar).
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // A galeria do design system saiu da barra: abre pelo AppBar da Arquitetura.
    expect(find.text('Design'), findsNothing);
    expect(find.byKey(const Key('abrir-design-system')), findsNothing);
    await tester.tap(find.text('Arquitetura'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('abrir-design-system')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Design system'), findsOneWidget);
    expect(find.text('SELETOR DE PERÍODO'), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    // A transição de volta da página dura mais que 400 ms.
    await tester.pump(const Duration(seconds: 1));

    // Aba Dispositivos: lista do catálogo.
    await tester.tap(find.text('Dispositivos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('3 DE 3 DISPOSITIVOS'), findsOneWidget);
    expect(find.text('p-001'), findsOneWidget);
    // Sai da aba para o timer da Arquitetura não ficar pendente.
    await tester.tap(find.text('Mapa'));
    await tester.pump();
  });

  testWidgets('barra de navegação cabe em 412 px (4 abas)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await montarApp(tester);

    for (final aba in ['Mapa', 'KPIs', 'Arquitetura', 'Dispositivos']) {
      expect(find.text(aba), findsOneWidget);
    }
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    // Sem overflow de layout (o teste falharia com a exceção de RenderFlex).
    expect(tester.takeException(), isNull);
  });
}
