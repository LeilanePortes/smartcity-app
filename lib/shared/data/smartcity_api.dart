import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_providers.dart';
import '../models/models.dart';

/// Fachada de acesso à API de Iluminação Pública Inteligente (v1).
/// Um método por endpoint documentado em `API.md`; os caminhos são relativos a
/// `AppConfig.apiBaseUrl` (`/api/v1`).
///
/// Listagens respondem no envelope [Pagina] e aceitam `pagina`, `tamanho` e
/// `ordenar`. O `ordenar` só é enviado quando informado — sem ele vale o
/// padrão do backend.
class SmartcityApi {
  SmartcityApi(this._client);

  final ApiClient _client;

  /// Máximo aceito em `tamanho` (1–500).
  static const int tamanhoMaximo = 500;

  /// Teto de páginas em [listarPostes], por segurança contra laço infinito.
  static const int _maxPaginas = 50;

  /// `GET /postes` — uma página da lista de postes. Filtros opcionais por
  /// status e busca (rua ou bairro, sem distinção de acento/caixa).
  Future<Pagina<PosteResumo>> paginaPostes({
    StatusPoste? status,
    String? busca,
    int pagina = 1,
    int tamanho = tamanhoMaximo,
    Ordenacao<CampoOrdemPostes>? ordenar,
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/postes',
      query: {
        'status': status?.wire,
        'busca': busca,
        'pagina': pagina,
        'tamanho': tamanho,
        'ordenar': ordenar?.wire,
      },
      cancelToken: cancelToken,
    );
    return Pagina.fromJson(data, PosteResumo.fromJson);
  }

  /// Todos os postes que casam com o filtro (o mapa precisa dos 248): pede
  /// páginas de [tamanhoMaximo] e percorre até `totalPaginas`.
  Future<List<PosteResumo>> listarPostes({
    StatusPoste? status,
    String? busca,
    CancelToken? cancelToken,
  }) async {
    final postes = <PosteResumo>[];
    var pagina = 1;
    while (true) {
      final p = await paginaPostes(
        status: status,
        busca: busca,
        pagina: pagina,
        cancelToken: cancelToken,
      );
      postes.addAll(p.itens);
      if (!p.temProxima || p.itens.isEmpty || pagina >= _maxPaginas) break;
      pagina++;
    }
    return postes;
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

  /// `GET /postes/:id/eventos` — log do sensor 360°, paginado. Sem [ordenar],
  /// o backend devolve os mais recentes primeiro (`-timestamp`).
  Future<Pagina<EventoSensor>> eventos(
    String id, {
    int pagina = 1,
    int tamanho = 50,
    Ordenacao<CampoOrdemEventos>? ordenar,
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/postes/$id/eventos',
      query: {
        'pagina': pagina,
        'tamanho': tamanho,
        'ordenar': ordenar?.wire,
      },
      cancelToken: cancelToken,
    );
    return Pagina.fromJson(data, EventoSensor.fromJson);
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

  /// `GET /kpis/maior-consumo` — ranking dos postes de maior consumo,
  /// paginado. Sem [ordenar], o backend usa maiores primeiro (`-consumoKwh`).
  Future<RankingConsumo> maiorConsumo({
    PeriodoKpi periodo = PeriodoKpi.mes,
    int pagina = 1,
    int tamanho = 5,
    Ordenacao<CampoOrdemRanking>? ordenar,
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/kpis/maior-consumo',
      query: {
        'periodo': periodo.wire,
        'pagina': pagina,
        'tamanho': tamanho,
        'ordenar': ordenar?.wire,
      },
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

  // ── Catálogo (RF-CEN-01 a 03) ───────────────────────────────────────────

  Future<Pagina<ItemCatalogo>> _catalogo(
    String path,
    CancelToken? cancelToken,
  ) async {
    final data = await _client.get<Map<String, dynamic>>(
      path,
      query: {'tamanho': tamanhoMaximo},
      cancelToken: cancelToken,
    );
    return Pagina.fromJson(data, ItemCatalogo.fromJson);
  }

  /// `GET /catalogo/dominios?tamanho=500` — opções do seletor de domínio.
  Future<Pagina<ItemCatalogo>> dominios({CancelToken? cancelToken}) =>
      _catalogo('/catalogo/dominios', cancelToken);

  /// `GET /catalogo/perfis?tamanho=500` — opções do seletor de perfil.
  Future<Pagina<ItemCatalogo>> perfis({CancelToken? cancelToken}) =>
      _catalogo('/catalogo/perfis', cancelToken);

  /// `GET /sites?tamanho=500` — locais (bairros).
  Future<Pagina<ItemCatalogo>> sites({CancelToken? cancelToken}) =>
      _catalogo('/sites', cancelToken);

  /// `GET /sites/:ref/areas?tamanho=500` — áreas (ruas) do local [siteRef].
  Future<Pagina<ItemCatalogo>> areas(
    String siteRef, {
    CancelToken? cancelToken,
  }) =>
      _catalogo('/sites/${Uri.encodeComponent(siteRef)}/areas', cancelToken);

  // ── Dispositivos (RF-DIS-01, 02 e 06) ───────────────────────────────────

  /// `GET /dispositivos` — página da lista. Filtros vazios e `ordenar` não
  /// informado ficam fora da requisição (vale o padrão do backend: `codigo`).
  Future<Pagina<Dispositivo>> dispositivos({
    String? dominio,
    String? perfil,
    String? site,
    String? area,
    FiltroConexao? conexao,
    String? busca,
    int pagina = 1,
    int tamanho = 50,
    Ordenacao<CampoOrdemDispositivos>? ordenar,
    CancelToken? cancelToken,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/dispositivos',
      query: {
        'dominio': dominio,
        'perfil': perfil,
        'site': site,
        'area': area,
        'conexao': conexao?.wire,
        'busca': busca,
        'pagina': pagina,
        'tamanho': tamanho,
        'ordenar': ordenar?.wire,
      },
      cancelToken: cancelToken,
    );
    return Pagina.fromJson(data, Dispositivo.fromJson);
  }

  /// `GET /dispositivos/:ref` — [ref] é o id ou o código (ex.: `p-001`).
  Future<Dispositivo> dispositivo(String ref, {CancelToken? cancelToken}) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/dispositivos/${Uri.encodeComponent(ref)}',
      cancelToken: cancelToken,
    );
    return Dispositivo.fromJson(data);
  }

  /// `POST /dispositivos` — cadastra e emite a credencial. **O token só vem
  /// nesta resposta.** `409` código repetido · `400` campo/referência inválida.
  Future<CadastroDispositivo> cadastrarDispositivo(
    DadosDispositivo dados, {
    CancelToken? cancelToken,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/dispositivos',
      body: dados.paraCriar(),
      cancelToken: cancelToken,
    );
    return CadastroDispositivo.fromJson(data);
  }

  /// `PATCH /dispositivos/:ref` — todos os campos menos o código.
  Future<Dispositivo> atualizarDispositivo(
    String ref,
    DadosDispositivo dados, {
    CancelToken? cancelToken,
  }) async {
    final data = await _client.patch<Map<String, dynamic>>(
      '/dispositivos/${Uri.encodeComponent(ref)}',
      body: dados.paraEditar(),
      cancelToken: cancelToken,
    );
    return Dispositivo.fromJson(data);
  }

  /// `POST /dispositivos/:ref/credenciais` — emite um token novo e revoga o
  /// anterior. **O token só vem nesta resposta.**
  Future<CredencialEmitida> emitirCredencial(
    String ref, {
    CancelToken? cancelToken,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/dispositivos/${Uri.encodeComponent(ref)}/credenciais',
      cancelToken: cancelToken,
    );
    return CredencialEmitida.fromJson(data);
  }

  /// `DELETE /dispositivos/:ref/credenciais` — revoga a credencial ativa
  /// (`404` se não houver). A resposta traz só o código em `dispositivo`
  /// (`{ dispositivo, revogadas, revogadaEm }`), então o detalhe é relido para
  /// devolver o dispositivo atualizado.
  Future<Dispositivo> revogarCredencial(
    String ref, {
    CancelToken? cancelToken,
  }) async {
    final data = await _client.delete<Map<String, dynamic>>(
      '/dispositivos/${Uri.encodeComponent(ref)}/credenciais',
      cancelToken: cancelToken,
    );
    final d = data['dispositivo'];
    return d is Map
        ? Dispositivo.fromJson(d.cast<String, dynamic>())
        : dispositivo(ref, cancelToken: cancelToken);
  }
}

/// Provider da fachada da API.
final smartcityApiProvider = Provider<SmartcityApi>(
  (ref) => SmartcityApi(ref.watch(apiClientProvider)),
);
