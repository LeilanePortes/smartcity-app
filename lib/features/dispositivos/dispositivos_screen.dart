import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brut_colors.dart';
import '../../core/theme/brut_spacing.dart';
import '../../core/theme/brut_typography.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import 'dispositivo_detalhe_screen.dart';
import 'dispositivo_form_screen.dart';
import 'dispositivos_providers.dart';
import 'widgets/item_dispositivo.dart';

/// Fase 9 · Dispositivos do catálogo (RF-DIS-01, 02 e 06): lista paginada com
/// busca, filtro por domínio e por conexão, e acesso ao cadastro.
class DispositivosScreen extends ConsumerWidget {
  const DispositivosScreen({super.key});

  void _abrir(BuildContext context, String codigo) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DispositivoDetalheScreen(codigo: codigo),
    ));
  }

  void _novo(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const DispositivoFormScreen(),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listaDispositivosProvider);
    final lista = async.value;

    return RefreshIndicator(
      color: BrutColors.ink,
      onRefresh: () async {
        ref.invalidate(listaDispositivosProvider);
        ref.invalidate(dominiosProvider);
        try {
          await ref.read(listaDispositivosProvider.future);
        } catch (_) {}
      },
      child: ListView(
        padding: const EdgeInsets.all(BrutSpacing.md),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lista == null
                      ? 'DISPOSITIVOS'
                      : '${Fmt.inteiro(lista.itens.length)} DE '
                          '${Fmt.inteiro(lista.total)} DISPOSITIVOS',
                  key: const Key('contador-dispositivos'),
                  style: BrutType.label(11, color: BrutColors.ink),
                ),
              ),
              BrutButton(
                key: const Key('novo-dispositivo'),
                label: 'Novo',
                icon: Icons.add,
                onPressed: () => _novo(context),
              ),
            ],
          ),
          const SizedBox(height: BrutSpacing.md),
          const _BuscaDispositivos(),
          const SizedBox(height: BrutSpacing.sm),
          const _FiltroDominio(),
          const SizedBox(height: BrutSpacing.sm),
          const _FiltroConexao(),
          const SizedBox(height: BrutSpacing.md),
          if (lista == null)
            async.hasError
                ? BrutError(
                    error: async.error!,
                    onRetry: () => ref.invalidate(listaDispositivosProvider),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: BrutLoading(),
                  )
          else if (lista.itens.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: BrutEmpty(
                message: 'Nenhum dispositivo com esses filtros.',
                icon: Icons.developer_board_off,
              ),
            )
          else ...[
            for (final d in lista.itens) ...[
              ItemDispositivo(
                dispositivo: d,
                onTap: () => _abrir(context, d.codigo),
              ),
              const SizedBox(height: BrutSpacing.sm),
            ],
            if (lista.erroMais != null)
              Padding(
                padding: const EdgeInsets.only(bottom: BrutSpacing.sm),
                child: Text(
                  'Falha ao carregar mais. Tente de novo.',
                  style: BrutType.sans(12, color: BrutColors.destaque),
                ),
              ),
            if (lista.temMais)
              BrutButton(
                key: const Key('carregar-mais'),
                label: 'Carregar mais',
                icon: Icons.expand_more,
                variant: BrutButtonVariant.secondary,
                expand: true,
                loading: lista.carregandoMais,
                onPressed: () =>
                    ref.read(listaDispositivosProvider.notifier).carregarMais(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: BrutSpacing.sm),
                child: Text(
                  'Fim da lista',
                  textAlign: TextAlign.center,
                  style: BrutType.sans(11, color: BrutColors.inkMuted),
                ),
              ),
          ],
          const SizedBox(height: BrutSpacing.lg),
        ],
      ),
    );
  }
}

/// Busca por código ou nome, com espera de 400 ms (igual à busca do mapa).
class _BuscaDispositivos extends ConsumerStatefulWidget {
  const _BuscaDispositivos();

  @override
  ConsumerState<_BuscaDispositivos> createState() => _BuscaDispositivosState();
}

class _BuscaDispositivosState extends ConsumerState<_BuscaDispositivos> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(filtroDispositivosProvider.notifier).setBusca(value);
    });
  }

  void _limpar() {
    _controller.clear();
    _debounce?.cancel();
    ref.read(filtroDispositivosProvider.notifier).setBusca('');
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    const borda = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: BrutColors.lineSoft, width: 1),
    );
    return TextField(
      key: const Key('busca-dispositivos'),
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      style: BrutType.sans(14),
      decoration: InputDecoration(
        hintText: 'Buscar por código ou nome',
        prefixIcon:
            const Icon(Icons.search, color: BrutColors.inkMuted, size: 20),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: _limpar,
              ),
        isDense: true,
        border: borda,
        enabledBorder: borda,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: BrutColors.ink, width: 1.5),
        ),
      ),
    );
  }
}

class _FiltroDominio extends ConsumerWidget {
  const _FiltroDominio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selecionado = ref.watch(filtroDispositivosProvider).dominio;
    final dominios = ref.watch(dominiosProvider).value ?? const <ItemCatalogo>[];
    void ir(String? d) =>
        ref.read(filtroDispositivosProvider.notifier).setDominio(d);

    return SizedBox(
      height: 32,
      child: ListView(
        key: const Key('chips-dominio'),
        scrollDirection: Axis.horizontal,
        children: [
          ChipFiltro(
            label: 'Todos os domínios',
            ativo: selecionado == null,
            onTap: () => ir(null),
          ),
          for (final d in dominios) ...[
            const SizedBox(width: 4),
            ChipFiltro(
              label: d.nome,
              ativo: selecionado == d.slug,
              onTap: () => ir(d.slug),
            ),
          ],
        ],
      ),
    );
  }
}

class _FiltroConexao extends ConsumerWidget {
  const _FiltroConexao();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selecionado = ref.watch(filtroDispositivosProvider).conexao;
    void ir(FiltroConexao? c) =>
        ref.read(filtroDispositivosProvider.notifier).setConexao(c);

    return Row(
      children: [
        Expanded(
          child: ChipFiltro(
            label: 'Todos',
            ativo: selecionado == null,
            onTap: () => ir(null),
          ),
        ),
        for (final c in FiltroConexao.values) ...[
          const SizedBox(width: 4),
          Expanded(
            child: ChipFiltro(
              label: c.label,
              ativo: selecionado == c,
              onTap: () => ir(c),
            ),
          ),
        ],
      ],
    );
  }
}

/// Chip de filtro no estilo dos filtros do mapa.
class ChipFiltro extends StatelessWidget {
  const ChipFiltro({
    super.key,
    required this.label,
    required this.ativo,
    required this.onTap,
  });

  final String label;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: BrutSpacing.sm),
        decoration: BoxDecoration(
          color: ativo ? BrutColors.ink : BrutColors.surface,
          border: Border.all(
            color: ativo ? BrutColors.ink : BrutColors.lineSoft,
            width: ativo ? 1.5 : 1,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          softWrap: false,
          style: BrutType.mono(
            10,
            weight: FontWeight.w600,
            color: ativo ? BrutColors.paper : BrutColors.inkMuted,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
