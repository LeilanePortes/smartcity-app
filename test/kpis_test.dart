import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartcity_app/core/network/api_client.dart';
import 'package:smartcity_app/core/theme/brut_theme.dart';
import 'package:smartcity_app/features/kpis/kpis_screen.dart';
import 'package:smartcity_app/shared/data/smartcity_api.dart';
import 'package:smartcity_app/shared/models/models.dart';

class _FakeApi extends SmartcityApi {
  _FakeApi() : super(ApiClient(dio: Dio()));

  PeriodoKpi? ultimoPeriodo;

  @override
  Future<KpisResumo> kpis({
    PeriodoKpi periodo = PeriodoKpi.mes,
    CancelToken? cancelToken,
  }) async {
    ultimoPeriodo = periodo;
    final base = DateTime.utc(2026, 8, 11);
    return KpisResumo(
      periodo: periodo,
      geradoEm: DateTime.utc(2026, 9, 10),
      tarifa: const Tarifa(
        classe: 'B4a',
        descricao: 'Iluminação pública',
        valorKwh: 0.58,
      ),
      atual: JanelaKpi(
        inicio: base,
        fim: DateTime.utc(2026, 9, 10),
        consumoKwh: 10695.6,
        custoReais: 6203.46,
      ),
      anterior: JanelaKpi(
        inicio: DateTime.utc(2026, 7, 12),
        fim: base,
        consumoKwh: 11309.0,
        custoReais: 6559.26,
      ),
      variacaoConsumoPct: -5.4,
      variacaoCustoPct: -5.4,
      parcialHoje: JanelaKpi(
        inicio: DateTime.utc(2026, 9, 10),
        fim: DateTime.utc(2026, 9, 10, 16),
        consumoKwh: 234.4,
        custoReais: 135.99,
      ),
      serie: SerieComparativa(
        granularidade: 'dia',
        atual: [
          PontoSerie(inicio: base, consumoKwh: 375.9),
          PontoSerie(
              inicio: base.add(const Duration(days: 1)), consumoKwh: 356.1),
        ],
        anterior: [
          PontoSerie(inicio: DateTime.utc(2026, 7, 12), consumoKwh: 372.4),
          PontoSerie(inicio: DateTime.utc(2026, 7, 13), consumoKwh: 383.8),
        ],
      ),
    );
  }

  @override
  Future<RankingConsumo> maiorConsumo({
    PeriodoKpi periodo = PeriodoKpi.mes,
    int limite = 5,
    CancelToken? cancelToken,
  }) async {
    return RankingConsumo(
      periodo: periodo,
      inicio: DateTime.utc(2026, 9, 3),
      fim: DateTime.utc(2026, 9, 10),
      itens: [
        ItemRanking(
          posicao: 1,
          posteId: 'p1',
          codigo: 'P-034',
          endereco: 'Rua Coronel Ribeiro, 100',
          bairro: 'Centro',
          consumoKwh: 22.75,
          custoReais: 13.19,
        ),
        ItemRanking(
          posicao: 2,
          posteId: 'p2',
          codigo: 'P-062',
          endereco: 'Rua do Cerrado, 136',
          bairro: 'Setor Leste',
          consumoKwh: 22.28,
          custoReais: 12.92,
        ),
      ],
    );
  }

  @override
  Future<PostesPorStatus> postesPorStatus({CancelToken? cancelToken}) async {
    return const PostesPorStatus(
      total: 248,
      contagens: [
        ContagemStatus(status: StatusPoste.normal, quantidade: 231),
        ContagemStatus(status: StatusPoste.consumoAlto, quantidade: 9),
        ContagemStatus(status: StatusPoste.falhaOffline, quantidade: 5),
        ContagemStatus(status: StatusPoste.manutencao, quantidade: 3),
      ],
    );
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('dashboard renderiza totais, ranking e distribuição',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [smartcityApiProvider.overrideWithValue(_FakeApi())],
        child: MaterialApp(
          theme: BrutTheme.build(),
          home: const Scaffold(body: KpisScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('MAIOR CONSUMO'), findsOneWidget);
    expect(find.text('P-034'), findsOneWidget);
    expect(find.textContaining('B4a'), findsOneWidget);
    expect(find.text('POSTES POR STATUS'), findsOneWidget);
    expect(find.text('231'), findsOneWidget);
    expect(find.textContaining('−5,4%'), findsWidgets);
  });

  testWidgets('trocar período dispara nova consulta', (tester) async {
    final api = _FakeApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [smartcityApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          theme: BrutTheme.build(),
          home: const Scaffold(body: KpisScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(api.ultimoPeriodo, PeriodoKpi.mes);

    await tester.tap(find.text('ANO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(api.ultimoPeriodo, PeriodoKpi.ano);
  });
}
