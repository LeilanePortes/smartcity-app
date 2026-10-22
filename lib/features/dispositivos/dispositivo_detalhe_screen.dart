import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brut_colors.dart';
import '../../core/theme/brut_spacing.dart';
import '../../core/theme/brut_typography.dart';
import '../../core/utils/formatters.dart';
import '../../shared/data/smartcity_api.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import 'dispositivo_form_screen.dart';
import 'dispositivos_providers.dart';
import 'widgets/dialogos.dart';
import 'widgets/selo_conexao.dart';

/// Detalhe do dispositivo: atributos do cadastro, conexão e credencial, com
/// edição, emissão e revogação de credencial.
class DispositivoDetalheScreen extends ConsumerStatefulWidget {
  const DispositivoDetalheScreen({super.key, required this.codigo});

  /// `id` ou `codigo` (a API aceita os dois).
  final String codigo;

  @override
  ConsumerState<DispositivoDetalheScreen> createState() =>
      _DispositivoDetalheScreenState();
}

class _DispositivoDetalheScreenState
    extends ConsumerState<DispositivoDetalheScreen> {
  bool _enviando = false;

  void _recarregar() {
    ref.invalidate(dispositivoProvider(widget.codigo));
    ref.invalidate(listaDispositivosProvider);
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _editar(Dispositivo d) async {
    final salvo = await Navigator.of(context).push<Dispositivo>(
      MaterialPageRoute(builder: (_) => DispositivoFormScreen(editando: d)),
    );
    if (salvo != null && mounted) {
      _recarregar();
      _avisar('${salvo.codigo} atualizado.');
    }
  }

  Future<void> _emitir(Dispositivo d) async {
    final ok = await confirmarAcao(
      context,
      titulo: 'Emitir nova credencial?',
      texto: d.credencial.ativa
          ? 'Um token novo será gerado e o atual (prefixo '
              '${d.credencial.prefixo ?? '—'}) deixa de valer na hora.'
          : 'Um token novo será gerado para ${d.codigo}.',
      confirmar: 'Emitir',
    );
    if (!ok || !mounted) return;
    setState(() => _enviando = true);
    try {
      final c = await ref.read(smartcityApiProvider).emitirCredencial(d.codigo);
      if (!mounted) return;
      await mostrarToken(context, c, titulo: 'Nova credencial de ${d.codigo}');
      _recarregar();
    } on ApiException catch (e) {
      if (mounted) _avisar(e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _revogar(Dispositivo d) async {
    final ok = await confirmarAcao(
      context,
      titulo: 'Revogar credencial?',
      texto: 'O token de ${d.codigo} (prefixo ${d.credencial.prefixo ?? '—'}) '
          'deixa de valer na hora: o dispositivo não consegue mais se '
          'autenticar até receber uma credencial nova.',
      confirmar: 'Revogar',
      perigo: true,
    );
    if (!ok || !mounted) return;
    setState(() => _enviando = true);
    try {
      await ref.read(smartcityApiProvider).revogarCredencial(d.codigo);
      if (!mounted) return;
      _avisar('Credencial de ${d.codigo} revogada.');
      _recarregar();
    } on ApiException catch (e) {
      if (mounted) _avisar(e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dispositivoProvider(widget.codigo));
    final d = async.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(d?.codigo ?? widget.codigo,
            style: BrutType.mono(18, weight: FontWeight.w700)),
        actions: [
          if (d != null)
            IconButton(
              key: const Key('editar-dispositivo'),
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _enviando ? null : () => _editar(d),
            ),
        ],
      ),
      body: d == null
          ? (async.hasError
              ? BrutError(
                  error: async.error!,
                  onRetry: () =>
                      ref.invalidate(dispositivoProvider(widget.codigo)),
                )
              : const BrutLoading())
          : RefreshIndicator(
              color: BrutColors.ink,
              onRefresh: () async {
                ref.invalidate(dispositivoProvider(widget.codigo));
                try {
                  await ref.read(dispositivoProvider(widget.codigo).future);
                } catch (_) {}
              },
              child: ListView(
                padding: const EdgeInsets.all(BrutSpacing.md),
                children: [
                  _Cabecalho(d: d),
                  const SizedBox(height: BrutSpacing.md),
                  _Atributos(d: d),
                  const SizedBox(height: BrutSpacing.md),
                  _Conexao(conexao: d.conexao),
                  const SizedBox(height: BrutSpacing.md),
                  _Credencial(
                    credencial: d.credencial,
                    enviando: _enviando,
                    onEmitir: () => _emitir(d),
                    onRevogar: () => _revogar(d),
                  ),
                  const SizedBox(height: BrutSpacing.lg),
                ],
              ),
            ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
        texto.toUpperCase(),
        style: BrutType.mono(10,
            weight: FontWeight.w600,
            color: BrutColors.inkFaint,
            letterSpacing: 1.2),
      );
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.d});

  final Dispositivo d;

  @override
  Widget build(BuildContext context) {
    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(d.codigo,
                    style: BrutType.mono(24, weight: FontWeight.w700)),
              ),
              SeloConexao(online: d.conexao.online),
            ],
          ),
          const SizedBox(height: 4),
          Text(d.nome, style: BrutType.sans(15)),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.rotulo, this.valor, {this.mono = false});

  final String rotulo;
  final String valor;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(rotulo.toUpperCase(), style: BrutType.label(10)),
          ),
          Expanded(
            child: Text(
              valor,
              style: mono
                  ? BrutType.mono(13, weight: FontWeight.w600)
                  : BrutType.sans(13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Atributos extends StatelessWidget {
  const _Atributos({required this.d});

  final Dispositivo d;

  @override
  Widget build(BuildContext context) {
    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Titulo('Cadastro'),
          const SizedBox(height: BrutSpacing.sm),
          _Linha('Perfil', d.perfil.nome),
          _Linha('Domínio', d.dominio.nome),
          _Linha('Local', d.site.nome),
          _Linha('Área', d.area?.nome ?? 'Sem área'),
          _Linha('Fabricante', d.fabricante),
          _Linha('Modelo', d.modelo ?? '—'),
          _Linha('Firmware', d.firmware, mono: true),
          _Linha('Inquilino', d.inquilino.nome),
          _Linha(
            'Coordenadas',
            d.temGeo ? Fmt.coordenadas(d.latitude!, d.longitude!) : '—',
            mono: true,
          ),
          if (d.posteId != null) _Linha('Poste ligado', 'Sim (iluminação)'),
        ],
      ),
    );
  }
}

class _Conexao extends StatelessWidget {
  const _Conexao({required this.conexao});

  final ConexaoDispositivo conexao;

  @override
  Widget build(BuildContext context) {
    final ultima = conexao.ultimaMensagemEm;
    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Titulo('Conexão'),
          const SizedBox(height: BrutSpacing.sm),
          _Linha('Estado', conexao.online ? 'Online' : 'Offline'),
          _Linha(
            'Última mensagem',
            ultima == null
                ? 'Nunca enviou'
                : '${Fmt.dataHora(ultima)} (${Fmt.desde(ultima)})',
          ),
          _Linha('Limite offline', '${conexao.limiteOfflineS} s sem mensagens',
              mono: true),
        ],
      ),
    );
  }
}

class _Credencial extends StatelessWidget {
  const _Credencial({
    required this.credencial,
    required this.enviando,
    required this.onEmitir,
    required this.onRevogar,
  });

  final CredencialResumo credencial;
  final bool enviando;
  final VoidCallback onEmitir;
  final VoidCallback onRevogar;

  @override
  Widget build(BuildContext context) {
    final c = credencial;
    return BrutCard(
      padding: const EdgeInsets.all(BrutSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Titulo('Credencial'),
          const SizedBox(height: BrutSpacing.sm),
          if (c.ativa) ...[
            _Linha('Estado', 'Ativa'),
            _Linha('Prefixo', c.prefixo ?? '—', mono: true),
            _Linha('Emitida em',
                c.emitidaEm == null ? '—' : Fmt.dataHora(c.emitidaEm!)),
          ] else
            Text(
              'Sem credencial ativa: o dispositivo não consegue se autenticar.',
              key: const Key('sem-credencial'),
              style: BrutType.sans(12, color: BrutColors.inkMuted),
            ),
          const SizedBox(height: BrutSpacing.sm),
          Text(
            'O token nunca é exibido aqui — só uma vez, logo depois de emitido.',
            style: BrutType.sans(11, color: BrutColors.inkFaint),
          ),
          const SizedBox(height: BrutSpacing.md),
          BrutButton(
            key: const Key('emitir-credencial'),
            label: 'Emitir nova credencial',
            icon: Icons.key,
            expand: true,
            loading: enviando,
            onPressed: enviando ? null : onEmitir,
          ),
          const SizedBox(height: BrutSpacing.sm),
          BrutButton(
            key: const Key('revogar-credencial'),
            label: 'Revogar credencial',
            icon: Icons.block,
            variant: BrutButtonVariant.danger,
            expand: true,
            onPressed: (enviando || !c.ativa) ? null : onRevogar,
          ),
        ],
      ),
    );
  }
}
