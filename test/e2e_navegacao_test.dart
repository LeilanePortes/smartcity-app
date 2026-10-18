import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartcity_app/app.dart';
import 'package:smartcity_app/core/realtime/realtime_client.dart';
import 'package:smartcity_app/core/realtime/realtime_providers.dart';
import 'package:smartcity_app/features/mapa/widgets/poste_marker.dart';
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

    // Abre o bottom sheet do primeiro poste tocando no marcador.
    final marcador = find.byType(PosteMarker).first;
    await tester.tap(marcador, warnIfMissed: false);
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

  testWidgets('navegação entre abas Mapa / KPIs / Design', (tester) async {
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

    // Volta (o detalhe traz o próprio botão de voltar, sem AppBar) e vai para
    // a galeria do design system.
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Design'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('SELETOR DE PERÍODO'), findsOneWidget);
  });
}
