import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../arquitetura_providers.dart';
import 'ota_providers.dart';
import 'widgets/canario_controle.dart';
import 'widgets/decisoes_falhas.dart';
import 'widgets/implantacao_atual.dart';
import 'widgets/implantar_versao.dart';
import 'widgets/versoes_em_campo.dart';

/// Fase 8 · Seção "OTA · Grupo canário" da aba Arquitetura (`GET /ota`).
///
/// Consulta só com a aba visível: a cada [kIntervaloOtaAtivo] com implantação
/// em andamento, senão a cada [kIntervaloOtaOcioso]. A próxima consulta é
/// agendada depois de cada resposta, então o ritmo acompanha o status.
class OtaSecao extends ConsumerStatefulWidget {
  const OtaSecao({super.key});

  @override
  ConsumerState<OtaSecao> createState() => _OtaSecaoState();
}

class _OtaSecaoState extends ConsumerState<OtaSecao> {
  Timer? _timer;
  bool _visivel = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<bool>(
      arquiteturaVisivelProvider,
      (anterior, visivel) {
        _visivel = visivel;
        if (!visivel) {
          _timer?.cancel();
          _timer = null;
        } else if (anterior == false) {
          // Voltou para a aba: busca na hora; a resposta agenda a próxima.
          ref.invalidate(otaProvider);
        }
      },
      fireImmediately: true,
    );
    ref.listenManual<AsyncValue<EstadoOta>>(otaProvider, (_, atual) {
      if (!atual.isLoading) _agendar(atual.value);
    });
  }

  void _agendar(EstadoOta? estado) {
    _timer?.cancel();
    _timer = null;
    if (!_visivel) return;
    _timer = Timer(intervaloOta(estado), () => ref.invalidate(otaProvider));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _implantar(VersaoFirmware versao, CriteriosOta criterios) async {
    final ok = await _confirmar(
      titulo: 'Implantar ${versao.versao}?',
      texto: [
        if (versao.descricao.isNotEmpty) versao.descricao,
        'Começa pelo grupo canário (${criterios.ondas.first}% da frota) e avança '
            'pelas ondas ${criterios.ondas.map((o) => '$o%').join(' → ')}, '
            'observando ${criterios.janelaS} s em cada uma. A nuvem reverte se o '
            'canário consumir mais de '
            '${Fmt.decimal(criterios.limiarRazaoConsumo, casas: 2)}× o grupo de '
            'controle.',
      ],
      confirmar: 'Confirmar implantação',
      perigo: false,
    );
    if (ok != true) return;
    await _executar(
      () => ref.read(otaProvider.notifier).iniciar(versao.versao),
      sucesso: 'Implantação da ${versao.versao} iniciada pelo grupo canário.',
    );
  }

  Future<void> _reverter(ImplantacaoOta? imp) async {
    final ok = await _confirmar(
      titulo: 'Reverter a frota?',
      texto: [
        if (imp != null)
          'Para a implantação da ${imp.versao} e reenvia a ${imp.versaoAnterior} '
              'a todos os postes que instalaram a versão nova.',
      ],
      confirmar: 'Confirmar reversão',
      perigo: true,
    );
    if (ok != true) return;
    await _executar(
      () => ref.read(otaProvider.notifier).reverter(),
      sucesso: 'Reversão da frota enviada.',
    );
  }

  /// Roda a ação e mostra o resultado; 400/409 aparecem com a mensagem da API.
  Future<void> _executar(
    Future<EstadoOta> Function() acao, {
    required String sucesso,
  }) async {
    setState(() => _enviando = true);
    String mensagem;
    try {
      await acao();
      mensagem = sucesso;
    } on ApiException catch (e) {
      mensagem = e.message;
    } catch (_) {
      mensagem = 'Falha inesperada ao falar com a API.';
    }
    if (!mounted) return;
    setState(() => _enviando = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<bool?> _confirmar({
    required String titulo,
    required List<String> texto,
    required String confirmar,
    required bool perigo,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrutColors.surface,
        title: Text(titulo, style: BrutType.mono(18, weight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final t in texto) ...[
              Text(t, style: BrutType.sans(13, height: 1.4)),
              const SizedBox(height: BrutSpacing.sm),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          BrutButton(
            label: 'Cancelar',
            variant: BrutButtonVariant.secondary,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          BrutButton(
            label: confirmar,
            variant: perigo ? BrutButtonVariant.danger : BrutButtonVariant.primary,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(otaProvider);
    final dados = async.value;

    final List<Widget> conteudo;
    if (dados == null) {
      conteudo = [
        BrutCard(
          padding: const EdgeInsets.all(BrutSpacing.md),
          child: async.hasError
              ? BrutError(
                  error: async.error!,
                  onRetry: () => ref.invalidate(otaProvider),
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: BrutSpacing.xl),
                  child: BrutLoading(),
                ),
        ),
      ];
    } else {
      final imp = dados.implantacao;
      conteudo = [
        VersoesEmCampo(estado: dados),
        const SizedBox(height: BrutSpacing.md),
        ImplantarVersao(
          estado: dados,
          enviando: _enviando,
          onImplantar: (v) => _implantar(v, dados.criterios),
          onReverter: () => _reverter(imp),
        ),
        const SizedBox(height: BrutSpacing.md),
        ImplantacaoAtual(implantacao: imp),
        if (imp != null) ...[
          const SizedBox(height: BrutSpacing.md),
          CanarioControle(metricas: imp.metricas, criterios: dados.criterios),
          const SizedBox(height: BrutSpacing.md),
          DecisoesFalhas(implantacao: imp, janelaS: dados.criterios.janelaS),
        ],
        if (async.hasError) ...[
          const SizedBox(height: BrutSpacing.sm),
          Text(
            'Falha ao atualizar a OTA — mostrando os últimos dados.',
            style: BrutType.sans(11, color: BrutColors.destaque),
          ),
        ],
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          'OTA · Grupo canário',
          trailing: dados == null
              ? null
              : Text(
                  'consulta a cada ${intervaloOta(dados).inSeconds} s',
                  style: BrutType.sans(11, color: BrutColors.inkMuted),
                ),
        ),
        const SizedBox(height: BrutSpacing.md),
        ...conteudo,
      ],
    );
  }
}
