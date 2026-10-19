import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartcity_app/core/network/api_client.dart';
import 'package:smartcity_app/features/mapa/mapa_geo.dart';
import 'package:smartcity_app/shared/data/smartcity_api.dart';
import 'package:smartcity_app/shared/models/models.dart';

/// API mockada em memória para os testes de widget / navegação.
class FakeSmartcityApi extends SmartcityApi {
  FakeSmartcityApi() : super(ApiClient(dio: Dio()));

  final Map<String, StatusPoste> _statusOverride = {};

  /// ~200 m em latitude (1° ≈ 111 km).
  static const double _passoLat = 0.0018;

  /// Postes calculados a partir do centro do mapa, ~200 m entre si (≈ 50 px no
  /// zoom inicial), para aparecerem na tela ao abrir o mapa mesmo que o centro
  /// mude de novo. Coordenadas fixas antigas ficaram fora da tela quando o
  /// centro foi para as coordenadas reais de Itaguari.
  static final List<PosteResumo> _postes = [
    _resumo('a1', 'P-001', 'Avenida Goiás, 100', 'Centro',
        _centro.latitude, _centro.longitude, StatusPoste.normal),
    _resumo('a2', 'P-002', 'Rua Anhanguera, 112', 'Setor Oeste',
        _centro.latitude + _passoLat, _centro.longitude,
        StatusPoste.consumoAlto),
    _resumo('a3', 'P-003', 'Rua Itaguari, 136', 'Centro',
        _centro.latitude - _passoLat, _centro.longitude,
        StatusPoste.falhaOffline, consumo: 0, offline: true),
  ];

  static const LatLng _centro = MapaGeo.centroItaguari;

  static PosteResumo _resumo(
    String id,
    String codigo,
    String endereco,
    String bairro,
    double lat,
    double lng,
    StatusPoste status, {
    double consumo = 0.06,
    bool offline = false,
  }) =>
      PosteResumo(
        id: id,
        codigo: codigo,
        endereco: endereco,
        bairro: bairro,
        latitude: lat,
        longitude: lng,
        status: status,
        luminosidadeAtual: status == StatusPoste.manutencao ? 0 : 50,
        consumoInstantaneoKw: consumo,
        ultimaLeituraEm:
            offline ? DateTime.utc(2026, 9, 10, 14) : DateTime.utc(2026, 9, 10, 16),
      );

  @override
  Future<List<PosteResumo>> listarPostes({
    StatusPoste? status,
    String? busca,
    CancelToken? cancelToken,
  }) async {
    Iterable<PosteResumo> r = _postes.map(_comOverride);
    if (status != null) r = r.where((p) => p.status == status);
    if (busca != null && busca.trim().isNotEmpty) {
      final q = busca.toLowerCase();
      r = r.where((p) =>
          p.endereco.toLowerCase().contains(q) ||
          p.bairro.toLowerCase().contains(q));
    }
    return r.toList();
  }

  PosteResumo _comOverride(PosteResumo p) {
    final s = _statusOverride[p.id];
    return s == null ? p : p.copyWith(status: s);
  }

  @override
  Future<Poste> detalhePoste(String id, {CancelToken? cancelToken}) async {
    final r = _postes.firstWhere((p) => p.id == id);
    final status = _statusOverride[id] ?? r.status;
    return Poste(
      id: r.id,
      codigo: r.codigo,
      endereco: r.endereco,
      bairro: r.bairro,
      latitude: r.latitude,
      longitude: r.longitude,
      status: status,
      luminosidadeAtual: status == StatusPoste.manutencao ? 0 : r.luminosidadeAtual,
      consumoInstantaneoKw: r.consumoInstantaneoKw,
      ultimaLeituraEm: r.ultimaLeituraEm,
      cidade: 'Itaguari',
      uf: 'GO',
      criadoEm: DateTime.utc(2026, 9, 1),
      atualizadoEm: DateTime.utc(2026, 9, 10),
      chamadoAberto: status == StatusPoste.falhaOffline,
    );
  }

  @override
  Future<TelemetriaHistorico> telemetria(
    String id, {
    PeriodoTelemetria periodo = PeriodoTelemetria.hoje,
    CancelToken? cancelToken,
  }) async {
    return TelemetriaHistorico(
      posteId: id,
      periodo: periodo,
      inicio: DateTime.utc(2026, 9, 10, 3),
      fim: DateTime.utc(2026, 9, 10, 16),
      resumo: const ResumoTelemetria(
        consumoTotalKwh: 1.55,
        custoTotalReais: 0.9,
        mediaKw: 0.11,
        picoKw: 0.19,
        economiaPct: 40.7,
      ),
      serie: [
        BucketTelemetria(
          inicio: DateTime.utc(2026, 9, 10, 3),
          consumoKwh: 0.12,
          mediaKw: 0.12,
          picoKw: 0.19,
        ),
        BucketTelemetria(
          inicio: DateTime.utc(2026, 9, 10, 4),
          consumoKwh: 0.16,
          mediaKw: 0.16,
          picoKw: 0.19,
        ),
      ],
    );
  }

  @override
  Future<List<EventoSensor>> eventos(
    String id, {
    int limite = 50,
    CancelToken? cancelToken,
  }) async {
    return [
      EventoSensor(
        id: 'e1',
        tipo: TipoEventoSensor.retornoAoPiso,
        sentido: SentidoVeiculo.aproximando,
        luminosidadeResultante: 50,
        timestamp: DateTime.utc(2026, 9, 10, 15, 40),
      ),
    ];
  }

  @override
  Future<Poste> alterarStatus(
    String id,
    StatusPoste status, {
    CancelToken? cancelToken,
  }) async {
    _statusOverride[id] = status;
    return detalhePoste(id);
  }

  @override
  Future<KpisResumo> kpis({
    PeriodoKpi periodo = PeriodoKpi.mes,
    CancelToken? cancelToken,
  }) async {
    final base = DateTime.utc(2026, 8, 11);
    return KpisResumo(
      periodo: periodo,
      geradoEm: DateTime.utc(2026, 9, 10),
      tarifa: const Tarifa(
          classe: 'B4a', descricao: 'Iluminação pública', valorKwh: 0.58),
      atual: JanelaKpi(
          inicio: base,
          fim: DateTime.utc(2026, 9, 10),
          consumoKwh: 10695.6,
          custoReais: 6203.46),
      anterior: JanelaKpi(
          inicio: DateTime.utc(2026, 7, 12),
          fim: base,
          consumoKwh: 11309,
          custoReais: 6559.26),
      variacaoConsumoPct: -5.4,
      variacaoCustoPct: -5.4,
      parcialHoje: JanelaKpi(
          inicio: DateTime.utc(2026, 9, 10),
          fim: DateTime.utc(2026, 9, 10, 16),
          consumoKwh: 234.4,
          custoReais: 135.99),
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
          posteId: 'a2',
          codigo: 'P-002',
          endereco: 'Rua Anhanguera, 112',
          bairro: 'Setor Oeste',
          consumoKwh: 22.75,
          custoReais: 13.19,
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

  /// Resposta de `GET /arquitetura` devolvida pelo fake (troque nos testes).
  Map<String, dynamic> arquiteturaJson = jsonArquiteturaCamadas();

  /// Se não nulo, `arquitetura()` lança este erro.
  Object? erroArquitetura;

  int chamadasArquitetura = 0;

  @override
  Future<EstadoArquitetura> arquitetura({CancelToken? cancelToken}) async {
    chamadasArquitetura++;
    if (erroArquitetura != null) throw erroArquitetura!;
    return EstadoArquitetura.fromJson(arquiteturaJson);
  }

  /// Corpo devolvido por `GET /ota` (e pelos POST, depois de aplicados).
  Map<String, dynamic> otaJson = jsonOtaSemImplantacao();

  /// Se não nulos, os POST lançam estes erros e o estado não muda.
  Object? erroIniciarOta;
  Object? erroReverterOta;

  int chamadasOta = 0;
  int chamadasReverterOta = 0;
  String? ultimaVersaoIniciada;

  @override
  Future<EstadoOta> ota({CancelToken? cancelToken}) async {
    chamadasOta++;
    return EstadoOta.fromJson(otaJson);
  }

  @override
  Future<EstadoOta> iniciarOta(String versao, {CancelToken? cancelToken}) async {
    if (erroIniciarOta != null) throw erroIniciarOta!;
    ultimaVersaoIniciada = versao;
    otaJson = jsonOtaEmAndamento(versao);
    return EstadoOta.fromJson(otaJson);
  }

  @override
  Future<EstadoOta> reverterOta({CancelToken? cancelToken}) async {
    if (erroReverterOta != null) throw erroReverterOta!;
    chamadasReverterOta++;
    otaJson = jsonOtaRevertida();
    return EstadoOta.fromJson(otaJson);
  }
}

List<Map<String, dynamic>> _catalogoOta() => [
      {'versao': '2.4.1', 'descricao': 'Versão atualmente em campo (estável).'},
      {
        'versao': '2.5.0',
        'descricao': 'Ajustes no sensor 360° e na reconexão MQTT (estável).',
      },
      {
        'versao': '3.0.0',
        'descricao': 'Novo agrupamento de leituras — DEFEITO: consumo sobe ~80%.',
      },
      {
        'versao': '3.0.1',
        'descricao': 'Build corrompido — DEFEITO: falha no autoteste.',
      },
    ];

Map<String, dynamic> _criteriosOta() => {
      'ondas': [5, 25, 50, 100],
      'janelaS': 120,
      'limiarFalhaInstalacaoPct': 5,
      'limiarRazaoConsumo': 1.5,
      'minReportePct': 60,
      'maxExtensoes': 2,
    };

/// `GET /ota` sem nenhuma implantação (resposta real com a API recém-subida).
Map<String, dynamic> jsonOtaSemImplantacao() => {
      'modo': 'camadas',
      'catalogo': _catalogoOta(),
      'versoesEmCampo': {'2.4.1': 246, 'desconhecida': 2},
      'criterios': _criteriosOta(),
      'implantacao': null,
    };

/// Implantação recém-iniciada: canário na 1ª onda, antes do 1º portão.
Map<String, dynamic> jsonOtaEmAndamento(String versao) => {
      ...jsonOtaSemImplantacao(),
      'versoesEmCampo': {'2.4.1': 233, versao: 13, 'desconhecida': 2},
      'implantacao': {
        'versao': versao,
        'versaoAnterior': '2.4.1',
        'status': 'EM_ANDAMENTO',
        'iniciadaEm': '2026-10-18T18:43:21.000Z',
        'encerradaEm': null,
        'ondas': [5, 25, 50, 100],
        'ondaAtual': 0,
        'ondaAtualPct': 5,
        'proximaAvaliacaoEm': '2026-10-18T18:45:21.000Z',
        'aparelhos': {
          'elegiveis': 241,
          'enviados': 13,
          'instalados': 11,
          'falhas': 0,
          'pendentes': 2,
          'revertidos': 0,
        },
        'grupos': {
          'canario': ['P-012', 'P-087', 'P-140'],
          'controle': ['P-069', 'P-175', 'P-153'],
        },
        'metricas': null,
        'falhas': <Map<String, dynamic>>[],
        'decisoes': <Map<String, dynamic>>[],
      },
    };

/// Exemplo da documentação: 3.0.0 revertida no 1º portão por consumo.
Map<String, dynamic> jsonOtaRevertida() => {
      ...jsonOtaSemImplantacao(),
      'versoesEmCampo': {'2.4.1': 231, '3.0.0': 13, 'desconhecida': 4},
      'implantacao': {
        'versao': '3.0.0',
        'versaoAnterior': '2.4.1',
        'status': 'REVERTIDA',
        'iniciadaEm': '2026-10-18T18:43:21.000Z',
        'encerradaEm': '2026-10-18T18:45:26.000Z',
        'ondas': [5, 25, 50, 100],
        'ondaAtual': 0,
        'ondaAtualPct': 5,
        'proximaAvaliacaoEm': null,
        'aparelhos': {
          'elegiveis': 241,
          'enviados': 13,
          'instalados': 13,
          'falhas': 0,
          'pendentes': 0,
          'revertidos': 13,
        },
        'grupos': {
          'canario': ['P-012', 'P-087', 'P-140'],
          'controle': ['P-069', 'P-175', 'P-153'],
        },
        'metricas': {
          'canario': {
            'aparelhos': 13,
            'reportaram': 13,
            'consumoNormalizadoMedio': 0.1814,
            'consumoAltoPct': 100,
          },
          'controle': {
            'aparelhos': 13,
            'reportaram': 13,
            'consumoNormalizadoMedio': 0.0999,
            'consumoAltoPct': 0,
          },
          'referenciaConsumo': 0.0999,
          'razaoConsumo': 1.82,
        },
        'falhas': [
          {'codigo': 'P-010', 'motivo': 'sem resposta do aparelho'},
        ],
        'decisoes': [
          {
            'em': '2026-10-18T18:45:26.000Z',
            'ondaPct': 5,
            'decisao': 'REVERTER',
            'motivo':
                'consumo do canário 1,82× o do grupo de controle (limite 1,50×)',
            'razaoConsumo': 1.82,
          },
        ],
      },
    };

/// Payload no formato real de `GET /arquitetura` (modo camadas). O alerta
/// aponta para o poste `a2` (P-002) do fake, para o toque abrir o detalhe.
Map<String, dynamic> jsonArquiteturaCamadas() => {
      'modo': 'camadas',
      'nuvem': {'brokerConectado': true},
      'edge': {'online': true},
      'fog': {
        'online': true,
        'gateways': [
          {'bairro': 'Centro', 'postes': 46, 'online': 46},
          {'bairro': 'Setor Oeste', 'postes': 21, 'online': 20},
        ],
        'buffer': 0,
        'atualizadoEm': '2026-10-18T18:11:06.722Z',
      },
      'trafego': {
        'janelaS': 60,
        'entrada': {'msgs': 1586, 'bytes': 237231},
        'saida': {'msgs': 137, 'bytes': 98834},
        'reducaoMsgsPct': 91,
        'reducaoBytesPct': 58,
        'postes': {'total': 248, 'online': 243},
        'em': '2026-10-18T18:11:06.722Z',
      },
      'alertas': [
        {
          'posteId': 'a2',
          'codigo': 'P-002',
          'bairro': 'Setor Oeste',
          'statusAnterior': 'NORMAL',
          'status': 'CONSUMO_ALTO',
          'motivo': 'consumo 2,10× a mediana do bairro',
          'em': '2026-10-18T18:11:26.712Z',
        },
      ],
      'geradoEm': '2026-10-18T18:11:46.729Z',
    };

/// Modo de reserva: edge, fog e tráfego nulos, sem alertas.
Map<String, dynamic> jsonArquiteturaInterno() => {
      'modo': 'interno',
      'nuvem': {'brokerConectado': false},
      'edge': null,
      'fog': null,
      'trafego': null,
      'alertas': <Map<String, dynamic>>[],
      'geradoEm': '2026-10-18T18:11:46.729Z',
    };
