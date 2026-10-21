import 'package:flutter_test/flutter_test.dart';
import 'package:smartcity_app/shared/models/models.dart';

void main() {
  test('Pagina.fromJson lê o envelope completo', () {
    final p = Pagina.fromJson({
      'itens': [
        {'id': 'e1', 'tipo': 'VEICULO_DETECTADO', 'sentido': 'AFASTANDO',
         'luminosidadeResultante': 100, 'timestamp': '2026-10-20T21:33:07.618Z'},
        {'id': 'e2', 'tipo': 'RETORNO_AO_PISO', 'sentido': null,
         'luminosidadeResultante': 50, 'timestamp': '2026-10-20T21:33:27.619Z'},
      ],
      'pagina': 1,
      'tamanho': 2,
      'total': 106,
      'totalPaginas': 53,
    }, EventoSensor.fromJson);

    expect(p.itens, hasLength(2));
    expect(p.itens.first.tipo, TipoEventoSensor.veiculoDetectado);
    expect(p.itens.last.sentido, isNull);
    expect(p.pagina, 1);
    expect(p.tamanho, 2);
    expect(p.total, 106);
    expect(p.totalPaginas, 53);
    expect(p.temProxima, isTrue);
  });

  test('campos ausentes: uma página só com o que veio', () {
    final p = Pagina.fromJson(
      {
        'itens': [
          {'id': 'x'},
          {'id': 'y'},
        ],
      },
      (j) => j['id'] as String,
    );

    expect(p.itens, ['x', 'y']);
    expect(p.pagina, 1);
    expect(p.tamanho, 2);
    expect(p.total, 2);
    expect(p.totalPaginas, 1);
    expect(p.temProxima, isFalse);

    final vazia = Pagina.fromJson(const {}, (j) => j);
    expect(vazia.itens, isEmpty);
    expect(vazia.total, 0);
  });

  test('última página não tem próxima', () {
    final p = Pagina.fromJson(
      {'itens': const [], 'pagina': 5, 'tamanho': 50, 'total': 248, 'totalPaginas': 5},
      (j) => j,
    );
    expect(p.temProxima, isFalse);
  });

  test('RankingConsumo lê o ranking de "itens" com posição absoluta', () {
    final r = RankingConsumo.fromJson({
      'periodo': 'semana',
      'inicio': '2026-10-13T00:00:00.000Z',
      'fim': '2026-10-20T00:00:00.000Z',
      'itens': [
        {'posicao': 6, 'posteId': 'u6', 'codigo': 'P-027', 'endereco': 'Rua 38, 158',
         'bairro': 'Centro', 'consumoKwh': 22.73, 'custoReais': 13.19},
        {'posicao': 7, 'posteId': 'u7', 'codigo': 'P-138', 'endereco': 'Rua Dez, 228',
         'bairro': 'Setor Norte', 'consumoKwh': 22.48, 'custoReais': 13.04},
      ],
      'pagina': 2,
      'tamanho': 5,
      'total': 248,
      'totalPaginas': 50,
    });

    expect(r.periodo, PeriodoKpi.semana);
    expect(r.itens.map((i) => i.posicao), [6, 7]);
    expect(r.itens.first.codigo, 'P-027');
    expect(r.pagina.pagina, 2);
    expect(r.pagina.total, 248);
  });

  test('Ordenacao monta o valor de "ordenar"', () {
    expect(const Ordenacao(CampoOrdemPostes.codigo).wire, 'codigo');
    expect(
      const Ordenacao(CampoOrdemPostes.consumoInstantaneoKw, decrescente: true).wire,
      '-consumoInstantaneoKw',
    );
    expect(const Ordenacao(CampoOrdemEventos.timestamp, decrescente: true).wire,
        '-timestamp');
    expect(const Ordenacao(CampoOrdemRanking.consumoKwh).wire, 'consumoKwh');
    // Só os campos aceitos pelo backend existem em cada enum.
    expect(CampoOrdemPostes.values.map((c) => c.wire), [
      'codigo', 'bairro', 'endereco', 'status',
      'luminosidadeAtual', 'consumoInstantaneoKw', 'ultimaLeituraEm',
    ]);
    expect(CampoOrdemEventos.values.map((c) => c.wire), ['timestamp', 'tipo']);
    expect(CampoOrdemRanking.values.map((c) => c.wire), ['consumoKwh']);
  });
}
