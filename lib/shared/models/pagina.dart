import 'json.dart';

/// Envelope das listagens da API v1 (RF-APP-07):
/// `{ itens, pagina, tamanho, total, totalPaginas }`.
class Pagina<T> {
  const Pagina({
    required this.itens,
    required this.pagina,
    required this.tamanho,
    required this.total,
    required this.totalPaginas,
  });

  final List<T> itens;

  /// Página atual (1-based).
  final int pagina;

  /// Itens por página pedidos.
  final int tamanho;

  /// Total de itens em todas as páginas.
  final int total;
  final int totalPaginas;

  bool get temProxima => pagina < totalPaginas;

  /// Campos ausentes caem em valores coerentes com a lista recebida
  /// (uma página só, com tudo o que veio).
  factory Pagina.fromJson(Json j, T Function(Json) item) {
    final itens = asList(j['itens']).map(item).toList();
    final pagina = asInt(j['pagina'], fallback: 1);
    return Pagina(
      itens: itens,
      pagina: pagina,
      tamanho: asInt(j['tamanho'], fallback: itens.length),
      total: asInt(j['total'], fallback: itens.length),
      totalPaginas: asInt(j['totalPaginas'], fallback: pagina),
    );
  }
}

/// Campo aceito pelo `ordenar` de uma listagem (valor cru da API).
abstract interface class CampoOrdenacao {
  String get wire;
}

/// `ordenar` de `GET /postes` (padrão do backend: `codigo`).
enum CampoOrdemPostes implements CampoOrdenacao {
  codigo('codigo'),
  bairro('bairro'),
  endereco('endereco'),
  status('status'),
  luminosidadeAtual('luminosidadeAtual'),
  consumoInstantaneoKw('consumoInstantaneoKw'),
  ultimaLeituraEm('ultimaLeituraEm');

  const CampoOrdemPostes(this.wire);

  @override
  final String wire;
}

/// `ordenar` de `GET /postes/:id/eventos` (padrão do backend: `-timestamp`).
enum CampoOrdemEventos implements CampoOrdenacao {
  timestamp('timestamp'),
  tipo('tipo');

  const CampoOrdemEventos(this.wire);

  @override
  final String wire;
}

/// `ordenar` de `GET /kpis/maior-consumo` (padrão do backend: `-consumoKwh`).
enum CampoOrdemRanking implements CampoOrdenacao {
  consumoKwh('consumoKwh');

  const CampoOrdemRanking(this.wire);

  @override
  final String wire;
}

/// `ordenar` de `GET /dispositivos` (padrão do backend: `codigo`).
enum CampoOrdemDispositivos implements CampoOrdenacao {
  codigo('codigo'),
  nome('nome'),
  firmware('firmware'),
  criadoEm('criadoEm'),
  ultimaMensagemEm('ultimaMensagemEm');

  const CampoOrdemDispositivos(this.wire);

  @override
  final String wire;
}

/// Filtro `conexao` de `GET /dispositivos`.
enum FiltroConexao {
  online('online', 'Online'),
  offline('offline', 'Offline');

  const FiltroConexao(this.wire, this.label);

  final String wire;
  final String label;
}

/// Valor do parâmetro `ordenar`: o campo, com `-` na frente se decrescente.
/// Só os campos do enum de cada endpoint compilam — evita o `400` da API.
class Ordenacao<C extends CampoOrdenacao> {
  const Ordenacao(this.campo, {this.decrescente = false});

  final C campo;
  final bool decrescente;

  String get wire => '${decrescente ? '-' : ''}${campo.wire}';
}
