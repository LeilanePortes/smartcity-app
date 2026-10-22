import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartcity_app/core/theme/brut_theme.dart';
import 'package:smartcity_app/features/dispositivos/dispositivo_detalhe_screen.dart';
import 'package:smartcity_app/features/dispositivos/dispositivos_providers.dart';
import 'package:smartcity_app/features/dispositivos/dispositivos_screen.dart';
import 'package:smartcity_app/shared/data/smartcity_api.dart';
import 'package:smartcity_app/shared/widgets/widgets.dart';

import 'support/fake_smartcity_api.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  Future<void> montar(WidgetTester tester, FakeSmartcityApi api, Widget tela) async {
    await tester.binding.setSurfaceSize(const Size(412, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [smartcityApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          theme: BrutTheme.build(),
          home: Scaffold(body: tela),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> esperar(WidgetTester tester, [int ms = 400]) async {
    await tester.pump();
    await tester.pump(Duration(milliseconds: ms));
  }

  /// Listas montam só o que está perto da tela: rola até [f] se preciso.
  Future<void> tocar(WidgetTester tester, Finder f, {Finder? rolavel}) async {
    if (f.evaluate().isEmpty) {
      await tester.scrollUntilVisible(f, 150,
          scrollable: rolavel ?? find.byType(Scrollable).first);
    }
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await esperar(tester);
  }

  Future<void> escolher(WidgetTester tester, String campo, String opcao) async {
    await tocar(tester, find.byKey(Key(campo)));
    await tester.tap(find.text(opcao).last);
    await esperar(tester);
  }

  Finder chip(String label) => find.widgetWithText(ChipFiltro, label);

  /// Lista horizontal dos chips de domínio.
  final chipsDominio = find.descendant(
    of: find.byKey(const Key('chips-dominio')),
    matching: find.byType(Scrollable),
  );

  /// Volta ao topo da lista e confere o contador.
  Future<void> contador(WidgetTester tester, String texto) async {
    final f = find.text(texto);
    if (f.evaluate().isEmpty) {
      await tester.scrollUntilVisible(f, -300,
          scrollable: find.byType(Scrollable).first);
    }
    expect(f, findsOneWidget);
  }

  group('lista', () {
    testWidgets('mostra itens com selo online/offline e domínio', (tester) async {
      await montar(tester, FakeSmartcityApi(), const DispositivosScreen());

      expect(find.text('3 DE 3 DISPOSITIVOS'), findsOneWidget);
      expect(find.text('p-001'), findsOneWidget);
      expect(find.text('p-002'), findsOneWidget);
      // Selos dos itens + o chip de mesmo nome no filtro de conexão.
      expect(find.text('ONLINE'), findsNWidgets(2 + 1));
      expect(find.text('OFFLINE'), findsNWidgets(1 + 1));
      expect(find.text('Iluminação pública'), findsNWidgets(3));
      expect(find.text('Fim da lista'), findsOneWidget);
    });

    testWidgets('busca repassa o texto para a API', (tester) async {
      final api = FakeSmartcityApi();
      await montar(tester, api, const DispositivosScreen());

      await tester.enterText(find.byKey(const Key('busca-dispositivos')), 'p-002');
      await esperar(tester, 500);

      expect(api.chamadasDispositivos.last['busca'], 'p-002');
      expect(find.text('1 DE 1 DISPOSITIVOS'), findsOneWidget);
      expect(find.text('p-001'), findsNothing);
    });

    testWidgets('filtros de conexão e de domínio', (tester) async {
      final api = FakeSmartcityApi();
      await montar(tester, api, const DispositivosScreen());

      await tocar(tester, chip('OFFLINE'));
      expect(api.chamadasDispositivos.last['conexao'], 'offline');
      expect(find.text('1 DE 1 DISPOSITIVOS'), findsOneWidget);
      expect(find.text('p-002'), findsOneWidget);

      await tocar(tester, chip('TODOS'));
      await tocar(tester, chip('ENERGIA'), rolavel: chipsDominio);
      expect(api.chamadasDispositivos.last['dominio'], 'energia');
      expect(api.chamadasDispositivos.last['conexao'], isNull);
      expect(find.text('Nenhum dispositivo com esses filtros.'), findsOneWidget);
    });

    testWidgets('"Carregar mais" junta as páginas', (tester) async {
      final api = FakeSmartcityApi()
        ..dispositivosJson = [
          for (var i = 1; i <= 45; i++)
            jsonDispositivo('p-${i.toString().padLeft(3, '0')}'),
        ];
      await montar(tester, api, const DispositivosScreen());

      await contador(tester, '20 DE 45 DISPOSITIVOS');
      await tocar(tester, find.byKey(const Key('carregar-mais')));
      expect(api.chamadasDispositivos.last['pagina'], 2);
      await contador(tester, '40 DE 45 DISPOSITIVOS');

      await tocar(tester, find.byKey(const Key('carregar-mais')));
      expect(api.chamadasDispositivos.last['pagina'], 3);
      // Na última página o botão some e aparece o fim da lista.
      await tester.scrollUntilVisible(find.text('Fim da lista'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const Key('carregar-mais')), findsNothing);
      await contador(tester, '45 DE 45 DISPOSITIVOS');
      expect(api.chamadasDispositivos.map((c) => c['tamanho']).toSet(),
          {kTamanhoPaginaDispositivos});
    });
  });

  group('formulário', () {
    Future<void> abrirNovo(WidgetTester tester, FakeSmartcityApi api) async {
      await montar(tester, api, const DispositivosScreen());
      await tocar(tester, find.byKey(const Key('novo-dispositivo')));
      expect(find.text('Novo dispositivo'), findsOneWidget);
    }

    Future<void> preencher(WidgetTester tester, String codigo) async {
      await tester.enterText(find.byKey(const Key('campo-codigo')), codigo);
      await tester.enterText(find.byKey(const Key('campo-nome')), 'Teste do app');
      await escolher(tester, 'campo-dominio', 'Iluminação pública');
      await escolher(tester, 'campo-perfil', 'Luminária LED com sensor 360°');
      await escolher(tester, 'campo-site', 'Centro');
      await escolher(tester, 'campo-area', 'Avenida Goiás');
      await tester.enterText(find.byKey(const Key('campo-fabricante')), 'Equipe');
      await tester.enterText(find.byKey(const Key('campo-firmware')), '1.0.0');
    }

    testWidgets('valida obrigatórios e o formato do código', (tester) async {
      final api = FakeSmartcityApi();
      await abrirNovo(tester, api);

      await tester.enterText(find.byKey(const Key('campo-codigo')), 'Teste App');
      await tester.enterText(find.byKey(const Key('campo-latitude')), '-95');
      await tocar(tester, find.byKey(const Key('salvar-dispositivo')));

      expect(find.text('Só letras minúsculas, números, ".", "-" e "_"'),
          findsOneWidget);
      expect(find.text('Obrigatório'), findsWidgets);
      expect(find.text('Entre -90.0 e 90.0'), findsOneWidget);
      expect(api.ultimoCadastro, isNull);
    });

    testWidgets('409 da API aparece no formulário', (tester) async {
      final api = FakeSmartcityApi();
      await abrirNovo(tester, api);
      await preencher(tester, 'p-001'); // já existe no fake

      await tocar(tester, find.byKey(const Key('salvar-dispositivo')));

      expect(find.byKey(const Key('erro-api')), findsOneWidget);
      expect(find.text('Já existe o dispositivo "p-001". (409)'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('cadastro mostra o token uma vez, copia e abre o detalhe',
        (tester) async {
      String? copiado;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiado = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      final api = FakeSmartcityApi();
      await abrirNovo(tester, api);
      await preencher(tester, 'teste-app');

      await tocar(tester, find.byKey(const Key('salvar-dispositivo')));

      expect(api.ultimoCadastro!.paraCriar()['codigo'], 'teste-app');
      expect(api.ultimoCadastro!.paraCriar()['area'], 'avenida-goias');
      expect(find.text('teste-app cadastrado'), findsOneWidget);
      expect(find.byKey(const Key('token-credencial')), findsOneWidget);
      expect(find.textContaining('não é mostrado de novo'), findsOneWidget);

      await tocar(tester, find.byKey(const Key('copiar-token')));
      expect(copiado, jsonCredencial()['token']);
      expect(find.text('COPIADO'), findsOneWidget);

      await tocar(tester, find.text('JÁ GUARDEI'));
      await esperar(tester, 1000);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(DispositivoDetalheScreen), findsOneWidget);
      expect(find.text('Teste do app'), findsOneWidget);
    });
  });

  group('detalhe', () {
    testWidgets('mostra atributos, conexão e credencial', (tester) async {
      await montar(tester, FakeSmartcityApi(),
          const DispositivoDetalheScreen(codigo: 'p-003'));

      expect(find.text('Luminária P-003'), findsOneWidget);
      expect(find.text('Luminária LED com sensor 360°'), findsOneWidget);
      expect(find.text('Prefeitura de Itaguari'), findsOneWidget);
      expect(find.text('LUM-LED-100W'), findsOneWidget);
      expect(find.text('180 s sem mensagens'), findsOneWidget);
      expect(find.text('Ativa'), findsOneWidget);
      expect(find.text('1a2b3c4d5e6f'), findsOneWidget);
    });

    testWidgets('revogar pede confirmação e chama a API', (tester) async {
      final api = FakeSmartcityApi();
      await montar(tester, api, const DispositivoDetalheScreen(codigo: 'p-003'));

      await tocar(tester, find.byKey(const Key('revogar-credencial')));
      expect(find.text('Revogar credencial?'), findsOneWidget);
      await tocar(tester, find.text('CANCELAR'));
      expect(api.revogacoes, 0);

      await tocar(tester, find.byKey(const Key('revogar-credencial')));
      await tocar(tester, find.text('REVOGAR'));
      expect(api.revogacoes, 1);
      expect(find.text('Credencial de p-003 revogada.'), findsOneWidget);
      expect(find.byKey(const Key('sem-credencial')), findsOneWidget);
    });

    testWidgets('sem credencial ativa, revogar fica desabilitado', (tester) async {
      await montar(tester, FakeSmartcityApi(),
          const DispositivoDetalheScreen(codigo: 'p-001'));

      expect(find.byKey(const Key('sem-credencial')), findsOneWidget);
      final botao =
          tester.widget<BrutButton>(find.byKey(const Key('revogar-credencial')));
      expect(botao.onPressed, isNull);
    });

    testWidgets('emitir mostra o token novo uma vez', (tester) async {
      final api = FakeSmartcityApi();
      await montar(tester, api, const DispositivoDetalheScreen(codigo: 'p-001'));

      await tocar(tester, find.byKey(const Key('emitir-credencial')));
      expect(find.text('Emitir nova credencial?'), findsOneWidget);
      await tocar(tester, find.text('EMITIR'));

      expect(api.emissoes, 1);
      expect(find.text('Nova credencial de p-001'), findsOneWidget);
      expect(find.byKey(const Key('token-credencial')), findsOneWidget);
      expect(find.textContaining('1 anterior(es) revogada(s)'), findsOneWidget);

      await tocar(tester, find.text('JÁ GUARDEI'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Ativa'), findsOneWidget);
    });

    testWidgets('editar envia PATCH sem o código', (tester) async {
      final api = FakeSmartcityApi();
      await montar(tester, api, const DispositivoDetalheScreen(codigo: 'p-001'));

      await tocar(tester, find.byKey(const Key('editar-dispositivo')));
      await esperar(tester, 600);
      expect(find.text('Editar p-001'), findsOneWidget);
      final codigo = tester.widget<TextField>(find.descendant(
          of: find.byKey(const Key('campo-codigo')),
          matching: find.byType(TextField)));
      expect(codigo.enabled, isFalse);

      await tester.enterText(find.byKey(const Key('campo-nome')), 'Luminária renomeada');
      await tocar(tester, find.byKey(const Key('salvar-dispositivo')));
      await esperar(tester, 1000);

      expect(api.ultimaEdicao!.paraEditar().containsKey('codigo'), isFalse);
      expect(api.ultimaEdicao!.paraEditar()['nome'], 'Luminária renomeada');
      expect(find.text('p-001 atualizado.'), findsOneWidget);
      expect(find.text('Luminária renomeada'), findsOneWidget);
    });
  });
}
