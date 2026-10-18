import 'package:dio/dio.dart';
import 'package:smartcity_app/core/network/api_client.dart';
import 'package:smartcity_app/shared/data/smartcity_api.dart';
import 'package:smartcity_app/shared/models/models.dart';

/// API mockada em memória para os testes de widget / navegação.
class FakeSmartcityApi extends SmartcityApi {
  FakeSmartcityApi() : super(ApiClient(dio: Dio()));

  final Map<String, StatusPoste> _statusOverride = {};

  static final List<PosteResumo> _postes = [
    _resumo('a1', 'P-001', 'Avenida Goiás, 100', 'Centro', -15.9535, -49.5928,
        StatusPoste.normal),
    _resumo('a2', 'P-002', 'Rua Anhanguera, 112', 'Setor Oeste', -15.9532,
        -49.5930, StatusPoste.consumoAlto),
    _resumo('a3', 'P-003', 'Rua Itaguari, 136', 'Centro', -15.9538, -49.5925,
        StatusPoste.falhaOffline, consumo: 0, offline: true),
  ];

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
}

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
