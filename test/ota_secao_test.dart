import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartcity_app/core/network/api_exception.dart';
import 'package:smartcity_app/core/theme/brut_theme.dart';
import 'package:smartcity_app/features/arquitetura/arquitetura_providers.dart';
import 'package:smartcity_app/features/arquitetura/ota/ota_providers.dart';
import 'package:smartcity_app/features/arquitetura/ota/ota_secao.dart';
import 'package:smartcity_app/shared/data/smartcity_api.dart';
import 'package:smartcity_app/shared/widgets/widgets.dart';

import 'support/fake_smartcity_api.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  Future<void> montar(
    WidgetTester tester,
    FakeSmartcityApi api, {
    bool visivel = true,
  }) async {
    await tester.binding.setSurfaceSize(const Size(430, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          smartcityApiProvider.overrideWithValue(api),
          arquiteturaVisivelProvider.overrideWithValue(visivel),
        ],
        child: MaterialApp(
          theme: BrutTheme.build(),
          home: const Scaffold(
            body: SingleChildScrollView(child: OtaSecao()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Desmonta a árvore para cancelar o timer da consulta.
  Future<void> desmontar(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  Future<void> animar(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  BrutButton botao(WidgetTester tester, String versao) =>
      tester.widget<BrutButton>(find.byKey(Key('ota-implantar-$versao')));

  testWidgets('sem implantação: versões em campo e botões do catálogo',
      (tester) async {
    final api = FakeSmartcityApi();
    await montar(tester, api);

    expect(find.text('OTA · GRUPO CANÁRIO'), findsOneWidget);
    expect(find.text(' · 246'), findsOneWidget);
    expect(find.text('desconhecida'), findsOneWidget);
    expect(find.text('EM CAMPO'), findsOneWidget);
    for (final v in ['2.4.1', '2.5.0', '3.0.0', '3.0.1']) {
      expect(botao(tester, v).onPressed, isNotNull);
    }
    expect(find.byKey(const Key('ota-reverter')), findsNothing);
    expect(find.text('Nenhuma implantação iniciada desde que a API subiu.'),
        findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('iniciar: confirma, chama a API e mostra em andamento',
      (tester) async {
    final api = FakeSmartcityApi();
    await montar(tester, api);

    await tester.tap(find.byKey(const Key('ota-implantar-2.5.0')));
    await animar(tester);
    expect(find.text('Implantar 2.5.0?'), findsOneWidget);
    expect(
      find.text('Ajustes no sensor 360° e na reconexão MQTT (estável).'),
      findsNWidgets(2), // linha do catálogo + diálogo
    );

    await tester.tap(find.text('CONFIRMAR IMPLANTAÇÃO'));
    await animar(tester);

    expect(api.ultimaVersaoIniciada, '2.5.0');
    expect(find.text('Implantação da 2.5.0 iniciada pelo grupo canário.'),
        findsOneWidget);
    expect(find.text('EM ANDAMENTO'), findsOneWidget);
    expect(find.text('2.4.1 → 2.5.0'), findsOneWidget);
    expect(find.text('5%'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Próxima avaliação às'), findsOneWidget);
    expect(find.text('Aguardando o 1º portão (janela de 120 s).'),
        findsOneWidget);
    // Com implantação em andamento: catálogo bloqueado, Reverter visível.
    expect(botao(tester, '3.0.0').onPressed, isNull);
    expect(find.byKey(const Key('ota-reverter')), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('cancelar a confirmação não chama a API', (tester) async {
    final api = FakeSmartcityApi();
    await montar(tester, api);

    await tester.tap(find.byKey(const Key('ota-implantar-3.0.0')));
    await animar(tester);
    await tester.tap(find.text('CANCELAR'));
    await animar(tester);

    expect(api.ultimaVersaoIniciada, isNull);
    expect(find.text('EM ANDAMENTO'), findsNothing);
    await desmontar(tester);
  });

  testWidgets('erro 409 mostra a mensagem da API e mantém o estado',
      (tester) async {
    final api = FakeSmartcityApi()
      ..erroIniciarOta = ApiException(
        'Já existe uma implantação em andamento.',
        statusCode: 409,
      );
    await montar(tester, api);

    await tester.tap(find.byKey(const Key('ota-implantar-3.0.1')));
    await animar(tester);
    await tester.tap(find.text('CONFIRMAR IMPLANTAÇÃO'));
    await animar(tester);

    expect(find.text('Já existe uma implantação em andamento.'),
        findsOneWidget);
    expect(find.text('EM ANDAMENTO'), findsNothing);
    expect(botao(tester, '3.0.1').onPressed, isNotNull);
    await desmontar(tester);
  });

  testWidgets('erro 400 (versão igual à atual) mostra a mensagem da API',
      (tester) async {
    final api = FakeSmartcityApi()
      ..erroIniciarOta = ApiException(
        'A versão 2.4.1 já é a versão atual da frota.',
        statusCode: 400,
      );
    await montar(tester, api);

    await tester.tap(find.byKey(const Key('ota-implantar-2.4.1')));
    await animar(tester);
    await tester.tap(find.text('CONFIRMAR IMPLANTAÇÃO'));
    await animar(tester);

    expect(find.text('A versão 2.4.1 já é a versão atual da frota.'),
        findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('reverter: confirma e mostra a implantação revertida',
      (tester) async {
    final api = FakeSmartcityApi()..otaJson = jsonOtaEmAndamento('3.0.0');
    await montar(tester, api);

    await tester.tap(find.byKey(const Key('ota-reverter')));
    await animar(tester);
    expect(find.text('Reverter a frota?'), findsOneWidget);
    await tester.tap(find.text('CONFIRMAR REVERSÃO'));
    await animar(tester);

    expect(api.chamadasReverterOta, 1);
    expect(find.text('REVERTIDA'), findsOneWidget);
    expect(find.byKey(const Key('ota-reverter')), findsNothing);
    // Canário × controle, decisões e falhas.
    expect(find.text('1,82×'), findsOneWidget);
    expect(find.text('limite 1,50×'), findsOneWidget);
    expect(find.text('Canário consome acima do limite → reverter'),
        findsOneWidget);
    expect(find.text('REVERTER'), findsOneWidget);
    expect(
      find.text('consumo do canário 1,82× o do grupo de controle (limite 1,50×)'),
      findsOneWidget,
    );
    expect(find.text('P-010'), findsOneWidget);
    expect(botao(tester, '2.5.0').onPressed, isNotNull);
    await desmontar(tester);
  });

  testWidgets('erro 409 ao reverter mostra a mensagem da API', (tester) async {
    final api = FakeSmartcityApi()
      ..otaJson = jsonOtaEmAndamento('3.0.0')
      ..erroReverterOta = ApiException(
        'Não há implantação em andamento.',
        statusCode: 409,
      );
    await montar(tester, api);

    await tester.tap(find.byKey(const Key('ota-reverter')));
    await animar(tester);
    await tester.tap(find.text('CONFIRMAR REVERSÃO'));
    await animar(tester);

    expect(find.text('Não há implantação em andamento.'), findsOneWidget);
    expect(find.text('EM ANDAMENTO'), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('controle null: sem grupo de controle na onda de 100%',
      (tester) async {
    final json = jsonOtaRevertida();
    (json['implantacao'] as Map<String, dynamic>)['metricas'] = {
      'canario': {
        'aparelhos': 241,
        'reportaram': 230,
        'consumoNormalizadoMedio': 0.1001,
        'consumoAltoPct': 0,
      },
      'controle': null,
      'referenciaConsumo': null,
      'razaoConsumo': null,
    };
    final api = FakeSmartcityApi()..otaJson = json;
    await montar(tester, api);

    expect(find.text('Sem grupo de controle na onda de 100%.'), findsOneWidget);
    expect(find.text('Razão de consumo indisponível'), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('modo interno bloqueia as ações e explica', (tester) async {
    final api = FakeSmartcityApi()
      ..otaJson = (jsonOtaSemImplantacao()..['modo'] = 'interno');
    await montar(tester, api);

    expect(
      find.text(
          'OTA só funciona no modo camadas — a API está no modo de reserva.'),
      findsOneWidget,
    );
    expect(botao(tester, '2.5.0').onPressed, isNull);
    await desmontar(tester);
  });

  testWidgets('consulta a cada 5 s em andamento e a cada 15 s parada',
      (tester) async {
    final api = FakeSmartcityApi()..otaJson = jsonOtaEmAndamento('2.5.0');
    await montar(tester, api);
    expect(api.chamadasOta, 1);

    await tester.pump(kIntervaloOtaAtivo);
    await tester.pump();
    expect(api.chamadasOta, 2);

    // A implantação termina: o ritmo cai para 15 s.
    api.otaJson = jsonOtaRevertida();
    await tester.pump(kIntervaloOtaAtivo);
    await tester.pump();
    expect(api.chamadasOta, 3);

    await tester.pump(kIntervaloOtaAtivo);
    await tester.pump();
    expect(api.chamadasOta, 3);

    await tester.pump(kIntervaloOtaOcioso - kIntervaloOtaAtivo);
    await tester.pump();
    expect(api.chamadasOta, 4);
    await desmontar(tester);
  });

  testWidgets('fora da aba não consulta', (tester) async {
    final api = FakeSmartcityApi()..otaJson = jsonOtaEmAndamento('2.5.0');
    await montar(tester, api, visivel: false);
    expect(api.chamadasOta, 1);

    await tester.pump(kIntervaloOtaOcioso * 2);
    await tester.pump();
    expect(api.chamadasOta, 1);
    await desmontar(tester);
  });
}
