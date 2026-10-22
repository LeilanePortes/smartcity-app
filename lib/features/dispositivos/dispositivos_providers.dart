import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/smartcity_api.dart';
import '../../shared/models/models.dart';

/// Itens por página na lista (o backend aceita 1–500; padrão dele é 50).
const int kTamanhoPaginaDispositivos = 20;

/// Filtro da lista: busca (código ou nome), domínio (slug) e conexão.
class FiltroDispositivos {
  const FiltroDispositivos({this.busca = '', this.dominio, this.conexao});

  final String busca;
  final String? dominio;
  final FiltroConexao? conexao;

  bool get ativo => busca.trim().isNotEmpty || dominio != null || conexao != null;

  FiltroDispositivos comBusca(String b) =>
      FiltroDispositivos(busca: b, dominio: dominio, conexao: conexao);
  FiltroDispositivos comDominio(String? d) =>
      FiltroDispositivos(busca: busca, dominio: d, conexao: conexao);
  FiltroDispositivos comConexao(FiltroConexao? c) =>
      FiltroDispositivos(busca: busca, dominio: dominio, conexao: c);

  @override
  bool operator ==(Object other) =>
      other is FiltroDispositivos &&
      other.busca == busca &&
      other.dominio == dominio &&
      other.conexao == conexao;

  @override
  int get hashCode => Object.hash(busca, dominio, conexao);
}

class FiltroDispositivosNotifier extends Notifier<FiltroDispositivos> {
  @override
  FiltroDispositivos build() => const FiltroDispositivos();

  void setBusca(String b) => state = state.comBusca(b);
  void setDominio(String? d) => state = state.comDominio(d);
  void setConexao(FiltroConexao? c) => state = state.comConexao(c);
}

final filtroDispositivosProvider =
    NotifierProvider<FiltroDispositivosNotifier, FiltroDispositivos>(
        FiltroDispositivosNotifier.new);

/// Páginas já carregadas da lista, acumuladas ("carregar mais").
class ListaDispositivos {
  const ListaDispositivos({
    required this.itens,
    required this.pagina,
    required this.total,
    required this.totalPaginas,
    this.carregandoMais = false,
    this.erroMais,
  });

  final List<Dispositivo> itens;

  /// Última página carregada.
  final int pagina;
  final int total;
  final int totalPaginas;
  final bool carregandoMais;

  /// Falha ao carregar a próxima página (os itens já carregados ficam).
  final Object? erroMais;

  bool get temMais => pagina < totalPaginas;

  ListaDispositivos copyWith({
    List<Dispositivo>? itens,
    int? pagina,
    int? total,
    int? totalPaginas,
    bool? carregandoMais,
    Object? erroMais,
  }) =>
      ListaDispositivos(
        itens: itens ?? this.itens,
        pagina: pagina ?? this.pagina,
        total: total ?? this.total,
        totalPaginas: totalPaginas ?? this.totalPaginas,
        carregandoMais: carregandoMais ?? this.carregandoMais,
        erroMais: erroMais,
      );
}

/// Lista paginada de `GET /dispositivos`, recarregada da 1ª página a cada
/// mudança de filtro.
class ListaDispositivosNotifier extends AsyncNotifier<ListaDispositivos> {
  Future<Pagina<Dispositivo>> _buscar(FiltroDispositivos f, int pagina) {
    final busca = f.busca.trim();
    return ref.read(smartcityApiProvider).dispositivos(
          dominio: f.dominio,
          conexao: f.conexao,
          busca: busca.isEmpty ? null : busca,
          pagina: pagina,
          tamanho: kTamanhoPaginaDispositivos,
        );
  }

  @override
  Future<ListaDispositivos> build() async {
    final filtro = ref.watch(filtroDispositivosProvider);
    ref.watch(smartcityApiProvider);
    final p = await _buscar(filtro, 1);
    return ListaDispositivos(
      itens: p.itens,
      pagina: p.pagina,
      total: p.total,
      totalPaginas: p.totalPaginas,
    );
  }

  /// Busca a próxima página e junta aos itens já carregados.
  Future<void> carregarMais() async {
    final atual = state.value;
    if (atual == null || atual.carregandoMais || !atual.temMais) return;
    final filtro = ref.read(filtroDispositivosProvider);
    state = AsyncData(atual.copyWith(carregandoMais: true));
    try {
      final p = await _buscar(filtro, atual.pagina + 1);
      // Filtro trocado no meio do caminho: a lista já foi recarregada.
      if (!ref.mounted || ref.read(filtroDispositivosProvider) != filtro) return;
      state = AsyncData(atual.copyWith(
        itens: [...atual.itens, ...p.itens],
        pagina: p.pagina,
        total: p.total,
        totalPaginas: p.totalPaginas,
        carregandoMais: false,
      ));
    } catch (e) {
      if (!ref.mounted || ref.read(filtroDispositivosProvider) != filtro) return;
      state = AsyncData(atual.copyWith(carregandoMais: false, erroMais: e));
    }
  }
}

final listaDispositivosProvider =
    AsyncNotifierProvider.autoDispose<ListaDispositivosNotifier, ListaDispositivos>(
        ListaDispositivosNotifier.new);

/// `GET /dispositivos/:ref` (id ou código).
final dispositivoProvider =
    FutureProvider.autoDispose.family<Dispositivo, String>((ref, codigo) {
  return ref.watch(smartcityApiProvider).dispositivo(codigo);
});

/// Catálogos dos seletores (`tamanho=500`).
final dominiosProvider =
    FutureProvider.autoDispose<List<ItemCatalogo>>((ref) async {
  return (await ref.watch(smartcityApiProvider).dominios()).itens;
});

final perfisProvider = FutureProvider.autoDispose<List<ItemCatalogo>>((ref) async {
  return (await ref.watch(smartcityApiProvider).perfis()).itens;
});

final sitesProvider = FutureProvider.autoDispose<List<ItemCatalogo>>((ref) async {
  return (await ref.watch(smartcityApiProvider).sites()).itens;
});

/// Áreas do local [site] (slug ou id).
final areasProvider = FutureProvider.autoDispose
    .family<List<ItemCatalogo>, String>((ref, site) async {
  return (await ref.watch(smartcityApiProvider).areas(site)).itens;
});
