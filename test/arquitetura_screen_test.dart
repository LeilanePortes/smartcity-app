import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartcity_app/app.dart';
import 'package:smartcity_app/core/network/api_exception.dart';
import 'package:smartcity_app/core/realtime/realtime_client.dart';
import 'package:smartcity_app/core/realtime/realtime_providers.dart';
import 'package:smartcity_app/core/theme/brut_theme.dart';
import 'package:smartcity_app/core/utils/formatters.dart';
import 'package:smartcity_app/features/arquitetura/arquitetura_providers.dart';
import 'package:smartcity_app/features/arquitetura/arquitetura_screen.dart';
import 'package:smartcity_app/shared/data/smartcity_api.dart';

import 'support/fake_smartcity_api.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  /// Monta só a tela. `visivel` simula a aba selecionada.
  Future<void> montarTela(
    WidgetTester tester,
    FakeSmartcityApi api, {
    bool visivel = true,
  }) async {
    await tester.binding.setSurfaceSize(const Size(430, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final realtime =
        RealtimeClient(baseUrl: 'http://fake', namespace: '/tempo-real');
    addTearDown(realtime.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          smartcityApiProvider.overrideWithValue(api),
          realtimeClientProvider.overrideWithValue(realtime),
          arquiteturaVisivelProvider.overrideWithValue(visivel),
        ],
        child: MaterialApp(
          theme: BrutTheme.build(),
          home: const Scaffold(body: ArquiteturaScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Desmonta a árvore para cancelar o timer da consulta periódica.
  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('mostra camadas, redução de banda, gateways e alertas',
      (tester) async {
    final api = FakeSmartcityApi();
    await montarTela(tester, api);

    // Três camadas e os selos (nuvem separa API de broker).
    expect(find.text('EDGE'), findsOneWidget);
    expect(find.text('FOG'), findsOneWidget);
    expect(find.text('NUVEM'), findsOneWidget);
    expect(find.text('API:'), findsOneWidget);
    expect(find.text('BROKER MQTT:'), findsOneWidget);
    expect(find.text('FORA DO AR'), findsNothing);

    // Redução de banda com o horário da janela.
    expect(find.text('91'), findsOneWidget);
    expect(find.text('58'), findsOneWidget);
    expect(find.text('menos mensagens'), findsOneWidget);
    final fimJanela = Fmt.horaSegundos(DateTime.utc(2026, 10, 18, 18, 11, 6));
    expect(find.text('JANELA ENCERRADA ÀS $fimJanela'), findsOneWidget);
    expect(find.text('231,7 KB'), findsOneWidget);
    expect(find.text('96,5 KB'), findsOneWidget);

    // Gateways e buffer.
    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('20/21'), findsOneWidget);
    expect(find.text('em dia — nada esperando a nuvem'), findsOneWidget);

    // Alerta.
    expect(find.text('P-002'), findsOneWidget);
    expect(find.text('consumo 2,10× a mediana do bairro'), findsOneWidget);

    expect(find.textContaining('MODO DE RESERVA'), findsNothing);
    await desmontar(tester);
  });

  testWidgets('broker da nuvem fora do ar não derruba a API', (tester) async {
    final api = FakeSmartcityApi()
      ..arquiteturaJson = (jsonArquiteturaCamadas()
        ..['nuvem'] = {'brokerConectado': false}
        ..['fog'] = {
          ...(jsonArquiteturaCamadas()['fog'] as Map<String, dynamic>),
          'buffer': 340,
        });
    await montarTela(tester, api);

    // Só o broker aparece fora do ar; a API continua no ar.
    expect(find.text('FORA DO AR'), findsOneWidget);
    expect(find.text('NO AR'), findsNWidgets(3)); // postes, gateways, API
    expect(find.text('340 mensagens aguardando a nuvem'), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('modo interno mostra o aviso de reserva', (tester) async {
    final api = FakeSmartcityApi()..arquiteturaJson = jsonArquiteturaInterno();
    await montarTela(tester, api);

    expect(find.text('MODO DE RESERVA · SIMULADOR EMBUTIDO'), findsOneWidget);
    expect(find.text('Indisponível no modo de reserva.'), findsNWidgets(2));
    expect(find.text('Sem alertas do fog no modo de reserva.'), findsOneWidget);
    expect(find.text('SEM DADOS'), findsNWidgets(2)); // postes e gateways
    await desmontar(tester);
  });

  testWidgets('erro sem dados mostra BrutError e tenta de novo',
      (tester) async {
    final api = FakeSmartcityApi()
      ..erroArquitetura = ApiException('Não foi possível falar com a API.');
    await montarTela(tester, api);

    expect(find.text('Não foi possível falar com a API.'), findsOneWidget);

    api.erroArquitetura = null;
    await tester.tap(find.text('TENTAR DE NOVO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('EDGE'), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('toque no alerta abre o detalhe do poste', (tester) async {
    final api = FakeSmartcityApi();
    await montarTela(tester, api);

    await tester.tap(find.text('P-002'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Rua Anhanguera, 112'), findsWidgets);
    await desmontar(tester);
  });

  testWidgets('consulta a cada 12 s enquanto visível', (tester) async {
    final api = FakeSmartcityApi();
    await montarTela(tester, api);
    expect(api.chamadasArquitetura, 1);

    await tester.pump(kIntervaloArquitetura);
    await tester.pump();
    expect(api.chamadasArquitetura, 2);

    await tester.pump(kIntervaloArquitetura);
    await tester.pump();
    expect(api.chamadasArquitetura, 3);
    await desmontar(tester);
  });

  testWidgets('não consulta periodicamente fora da aba', (tester) async {
    final api = FakeSmartcityApi();
    await montarTela(tester, api, visivel: false);
    expect(api.chamadasArquitetura, 1);

    await tester.pump(kIntervaloArquitetura * 3);
    await tester.pump();
    expect(api.chamadasArquitetura, 1);
    await desmontar(tester);
  });

  testWidgets('aba Arquitetura no app: entra, consulta e para ao sair',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeSmartcityApi();
    final realtime =
        RealtimeClient(baseUrl: 'http://fake', namespace: '/tempo-real');
    addTearDown(realtime.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          smartcityApiProvider.overrideWithValue(api),
          realtimeClientProvider.overrideWithValue(realtime),
        ],
        child: const SmartcityApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final antes = api.chamadasArquitetura;

    await tester.tap(find.text('Arquitetura'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('NUVEM'), findsOneWidget);
    expect(api.chamadasArquitetura, antes + 1);

    await tester.pump(kIntervaloArquitetura);
    await tester.pump();
    expect(api.chamadasArquitetura, antes + 2);

    // Sai da aba: a consulta periódica para.
    await tester.tap(find.text('KPIs'));
    await tester.pump();
    await tester.pump(kIntervaloArquitetura * 3);
    expect(api.chamadasArquitetura, antes + 2);
    await desmontar(tester);
  });
}
