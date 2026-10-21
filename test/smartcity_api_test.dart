import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcity_app/core/config/app_config.dart';
import 'package:smartcity_app/core/network/api_client.dart';
import 'package:smartcity_app/shared/data/smartcity_api.dart';
import 'package:smartcity_app/shared/models/models.dart';

/// Adaptador HTTP falso: grava cada requisição e responde com o JSON montado
/// por [responder] — sem rede.
class _AdaptadorFalso implements HttpClientAdapter {
  _AdaptadorFalso(this.responder);

  final Object Function(RequestOptions req) responder;
  final requisicoes = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requisicoes.add(options);
    return ResponseBody.fromString(
      jsonEncode(responder(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _poste(String codigo) => {
      'id': 'id-$codigo',
      'codigo': codigo,
      'endereco': 'Rua 10, 18',
      'bairro': 'Centro',
      'latitude': -15.920691,
      'longitude': -49.606176,
      'status': 'NORMAL',
      'luminosidadeAtual': 50,
      'consumoInstantaneoKw': 0.0528,
      'ultimaLeituraEm': '2026-10-20T21:33:07.456Z',
    };

Map<String, dynamic> _envelope(List<Object> itens,
        {int pagina = 1, int tamanho = 50, int? total, int totalPaginas = 1}) =>
    {
      'itens': itens,
      'pagina': pagina,
      'tamanho': tamanho,
      'total': total ?? itens.length,
      'totalPaginas': totalPaginas,
    };

void main() {
  late _AdaptadorFalso http;
  late SmartcityApi api;

  /// Usa o `ApiClient` padrão (com a base URL do `AppConfig`) trocando só o
  /// transporte HTTP.
  void montar(Object Function(RequestOptions req) responder) {
    http = _AdaptadorFalso(responder);
    final client = ApiClient();
    client.raw.httpClientAdapter = http;
    client.raw.interceptors.clear(); // sem o log de debug na saída do teste
    api = SmartcityApi(client);
  }

  Uri uri(int i) => http.requisicoes[i].uri;

  test('base REST em /api/v1; Socket.IO na raiz do servidor', () {
    expect(AppConfig.servidorUrl, 'http://localhost:3000');
    expect(AppConfig.apiBaseUrl, 'http://localhost:3000/api/v1');
    expect(AppConfig.realtimeUrl, 'http://localhost:3000');
    expect(AppConfig.realtimeUrl, isNot(contains('/api/v1')));
  });

  test('listarPostes pede tamanho=500 e percorre as páginas', () async {
    montar((req) {
      final pagina = int.parse(req.uri.queryParameters['pagina']!);
      return pagina == 1
          ? _envelope([_poste('P-001'), _poste('P-002')],
              pagina: 1, tamanho: 500, total: 3, totalPaginas: 2)
          : _envelope([_poste('P-003')],
              pagina: 2, tamanho: 500, total: 3, totalPaginas: 2);
    });

    final postes = await api.listarPostes(
      status: StatusPoste.normal,
      busca: 'centro',
    );

    expect(postes.map((p) => p.codigo), ['P-001', 'P-002', 'P-003']);
    expect(http.requisicoes, hasLength(2));
    expect(uri(0).toString(), startsWith('http://localhost:3000/api/v1/postes?'));
    expect(uri(0).queryParameters, {
      'status': 'NORMAL',
      'busca': 'centro',
      'pagina': '1',
      'tamanho': '500',
    });
    expect(uri(1).queryParameters['pagina'], '2');
  });

  test('listarPostes faz uma requisição só quando cabe numa página', () async {
    montar((_) => _envelope([_poste('P-001')], tamanho: 500));

    final postes = await api.listarPostes();

    expect(postes, hasLength(1));
    expect(http.requisicoes, hasLength(1));
    expect(uri(0).queryParameters, {'pagina': '1', 'tamanho': '500'});
  });

  test('eventos: envelope, tamanho=50 e nada de "limite"', () async {
    montar((_) => _envelope([
          {
            'id': 'e1',
            'tipo': 'RETORNO_AO_PISO',
            'sentido': 'APROXIMANDO',
            'luminosidadeResultante': 50,
            'timestamp': '2026-10-20T21:33:27.619Z',
          },
        ], total: 106, totalPaginas: 3));

    final p = await api.eventos('abc');

    expect(p.itens.single.id, 'e1');
    expect(p.total, 106);
    expect(uri(0).path, '/api/v1/postes/abc/eventos');
    expect(uri(0).queryParameters, {'pagina': '1', 'tamanho': '50'});
    expect(uri(0).queryParameters.containsKey('limite'), isFalse);
  });

  test('maiorConsumo: periodo + tamanho=5, ranking em "itens"', () async {
    montar((_) => {
          'periodo': 'semana',
          'inicio': '2026-10-13T00:00:00.000Z',
          'fim': '2026-10-20T00:00:00.000Z',
          ..._envelope([
            {
              'posicao': 1,
              'posteId': 'u1',
              'codigo': 'P-027',
              'endereco': 'Rua 38, 158',
              'bairro': 'Centro',
              'consumoKwh': 22.73,
              'custoReais': 13.19,
            },
          ], tamanho: 5, total: 248, totalPaginas: 50),
        });

    final r = await api.maiorConsumo(periodo: PeriodoKpi.semana);

    expect(r.itens.single.posicao, 1);
    expect(r.itens.single.codigo, 'P-027');
    expect(uri(0).path, '/api/v1/kpis/maior-consumo');
    expect(uri(0).queryParameters,
        {'periodo': 'semana', 'pagina': '1', 'tamanho': '5'});
    expect(uri(0).queryParameters.containsKey('limite'), isFalse);
  });

  test('"ordenar" só é enviado quando foi informado', () async {
    montar((req) => req.uri.path.endsWith('maior-consumo')
        ? {
            'periodo': 'mes',
            'inicio': '2026-09-20T00:00:00.000Z',
            'fim': '2026-10-20T00:00:00.000Z',
            ..._envelope(const []),
          }
        : _envelope(const []));

    // Sem ordenar: vale o padrão do backend.
    await api.paginaPostes();
    await api.eventos('abc');
    await api.maiorConsumo();
    for (var i = 0; i < 3; i++) {
      expect(uri(i).queryParameters.containsKey('ordenar'), isFalse,
          reason: uri(i).toString());
    }

    // Com ordenar: vai o campo, com "-" quando decrescente.
    await api.paginaPostes(
      ordenar: const Ordenacao(CampoOrdemPostes.consumoInstantaneoKw,
          decrescente: true),
    );
    await api.eventos(
      'abc',
      ordenar: const Ordenacao(CampoOrdemEventos.timestamp),
    );
    await api.maiorConsumo(
      ordenar: const Ordenacao(CampoOrdemRanking.consumoKwh),
    );
    expect(uri(3).queryParameters['ordenar'], '-consumoInstantaneoKw');
    expect(uri(4).queryParameters['ordenar'], 'timestamp');
    expect(uri(5).queryParameters['ordenar'], 'consumoKwh');
  });

  test('rotas sem mudança de formato também ganham o prefixo', () async {
    montar((req) => switch (req.uri.path) {
          '/api/v1/postes/abc' => {
              ..._poste('P-001'),
              'cidade': 'Itaguari',
              'uf': 'GO',
              'criadoEm': '2026-10-01T00:00:00.000Z',
              'atualizadoEm': '2026-10-01T00:00:00.000Z',
            },
          '/api/v1/arquitetura' => {'modo': 'camadas', 'nuvem': {}},
          _ => <String, dynamic>{},
        });

    await api.detalhePoste('abc');
    await api.arquitetura();
    await api.ota();
    await api.iniciarOta('2.5.0');
    await api.reverterOta();

    expect(http.requisicoes.map((r) => '${r.method} ${r.uri.path}'), [
      'GET /api/v1/postes/abc',
      'GET /api/v1/arquitetura',
      'GET /api/v1/ota',
      'POST /api/v1/ota/implantacoes',
      'POST /api/v1/ota/reverter',
    ]);
  });
}
