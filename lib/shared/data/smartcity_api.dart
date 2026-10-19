import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_providers.dart';
import '../models/models.dart';

/// Fachada de acesso à API de Iluminação Pública Inteligente.
/// Um método por endpoint documentado em `API.md`.
class SmartcityApi {
  SmartcityApi(this._client);

  final ApiClient _client;

  /// `GET /postes` — lista para o mapa. Filtros opcionais por status e busca
  /// (rua ou bairro, sem distinção de acento/caixa).
  Future<List<PosteResumo>> listarPostes({
    StatusPoste? status,
    String? busca,
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/postes',
      query: {'status': status?.wire, 'busca': busca},
      cancelToken: cancelToken,
    );
    return (data['postes'] as List)
        .cast<Map<String, dynamic>>()
        .map(PosteResumo.fromJson)
        .toList();
  }

  /// `GET /postes/:id` — detalhe do poste.
  Future<Poste> detalhePoste(String id, {CancelToken? cancelToken}) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/postes/$id',
      cancelToken: cancelToken,
    );
    return Poste.fromJson(data);
  }

  /// `GET /postes/:id/telemetria` — histórico de consumo agregado.
  Future<TelemetriaHistorico> telemetria(
    String id, {
    PeriodoTelemetria periodo = PeriodoTelemetria.hoje,
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/postes/$id/telemetria',
      query: {'periodo': periodo.wire},
      cancelToken: cancelToken,
    );
    return TelemetriaHistorico.fromJson(data);
  }

  /// `GET /postes/:id/eventos` — log do sensor 360°, mais recentes primeiro.
  Future<List<EventoSensor>> eventos(
    String id, {
    int limite = 50,
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<List<dynamic>>(
      '/postes/$id/eventos',
      query: {'limite': limite},
      cancelToken: cancelToken,
    );
    return data.cast<Map<String, dynamic>>().map(EventoSensor.fromJson).toList();
  }

  /// `PATCH /postes/:id/status` — atribuição manual (técnico).
  /// Só aceita `MANUTENCAO` ou `NORMAL`.
  Future<Poste> alterarStatus(
    String id,
    StatusPoste status, {
    CancelToken? cancelToken,
  }) async {
    assert(
      status == StatusPoste.manutencao || status == StatusPoste.normal,
      'PATCH /postes/:id/status só aceita MANUTENCAO ou NORMAL',
    );
    final data = await _client.patch<Map<String, dynamic>>(
      '/postes/$id/status',
      body: {'status': status.wire},
      cancelToken: cancelToken,
    );
    return Poste.fromJson(data);
  }

  /// `GET /kpis` — consumo, custo e variação da rede no período.
  Future<KpisResumo> kpis({
    PeriodoKpi periodo = PeriodoKpi.mes,
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/kpis',
      query: {'periodo': periodo.wire},
      cancelToken: cancelToken,
    );
    return KpisResumo.fromJson(data);
  }

  /// `GET /kpis/maior-consumo` — ranking dos postes de maior consumo.
  Future<RankingConsumo> maiorConsumo({
    PeriodoKpi periodo = PeriodoKpi.mes,
    int limite = 5,
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/kpis/maior-consumo',
      query: {'periodo': periodo.wire, 'limite': limite},
      cancelToken: cancelToken,
    );
    return RankingConsumo.fromJson(data);
  }

  /// `GET /kpis/postes-por-status` — contagem por status (barra empilhada).
  Future<PostesPorStatus> postesPorStatus({CancelToken? cancelToken}) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/kpis/postes-por-status',
      cancelToken: cancelToken,
    );
    return PostesPorStatus.fromJson(data);
  }

  /// `GET /arquitetura` — estado das camadas edge · fog · nuvem.
  Future<EstadoArquitetura> arquitetura({CancelToken? cancelToken}) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/arquitetura',
      cancelToken: cancelToken,
    );
    return EstadoArquitetura.fromJson(data);
  }

  /// `GET /ota` — catálogo, versões em campo e implantação atual (ou a última).
  Future<EstadoOta> ota({CancelToken? cancelToken}) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/ota',
      cancelToken: cancelToken,
    );
    return EstadoOta.fromJson(data);
  }

  /// `POST /ota/implantacoes` — inicia a implantação de [versao] pelo canário.
  /// `400` versão inválida ou igual à atual · `409` já em andamento / modo interno.
  Future<EstadoOta> iniciarOta(String versao, {CancelToken? cancelToken}) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/ota/implantacoes',
      body: {'versao': versao},
      cancelToken: cancelToken,
    );
    return EstadoOta.fromJson(data);
  }

  /// `POST /ota/reverter` — reverte a implantação em andamento.
  /// `409` se não houver implantação em andamento.
  Future<EstadoOta> reverterOta({CancelToken? cancelToken}) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/ota/reverter',
      cancelToken: cancelToken,
    );
    return EstadoOta.fromJson(data);
  }
}

/// Provider da fachada da API.
final smartcityApiProvider = Provider<SmartcityApi>(
  (ref) => SmartcityApi(ref.watch(apiClientProvider)),
);
