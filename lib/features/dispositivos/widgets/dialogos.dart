import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_spacing.dart';
import '../../../core/theme/brut_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

/// Confirmação antes de uma ação (emitir / revogar credencial).
Future<bool> confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String confirmar,
  bool perigo = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: BrutColors.surface,
      title: Text(titulo, style: BrutType.mono(18, weight: FontWeight.w700)),
      content: Text(texto, style: BrutType.sans(13, height: 1.4)),
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
  return ok ?? false;
}

/// Mostra o token recém-emitido **uma única vez**, com botão de copiar. Não
/// fecha tocando fora: só pelo "Já guardei".
Future<void> mostrarToken(
  BuildContext context,
  CredencialEmitida credencial, {
  required String titulo,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TokenDialog(credencial: credencial, titulo: titulo),
  );
}

class TokenDialog extends StatefulWidget {
  const TokenDialog({super.key, required this.credencial, required this.titulo});

  final CredencialEmitida credencial;
  final String titulo;

  @override
  State<TokenDialog> createState() => _TokenDialogState();
}

class _TokenDialogState extends State<TokenDialog> {
  bool _copiado = false;

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: widget.credencial.token));
    if (mounted) setState(() => _copiado = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.credencial;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: BrutColors.surface,
        title: Text(widget.titulo,
            style: BrutType.mono(18, weight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(BrutSpacing.sm),
              decoration: BoxDecoration(
                color: BrutColors.statusFalhaSoft,
                border: Border.all(color: BrutColors.destaque, width: BrutStroke.regular),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 18, color: BrutColors.destaque),
                  const SizedBox(width: BrutSpacing.sm),
                  Expanded(
                    child: Text(c.aviso,
                        style: BrutType.sans(12, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BrutSpacing.md),
            Text('TOKEN', style: BrutType.label(10)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(BrutSpacing.sm),
              decoration: BoxDecoration(
                color: BrutColors.paper,
                border: Border.all(color: BrutColors.line, width: 1),
              ),
              child: SelectableText(
                c.token,
                key: const Key('token-credencial'),
                style: BrutType.mono(13, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: BrutSpacing.sm),
            Text(
              'Prefixo ${c.prefixo}'
              '${c.emitidaEm == null ? '' : ' · emitido ${Fmt.dataHora(c.emitidaEm!)}'}'
              '${(c.anterioresRevogadas ?? 0) > 0 ? ' · ${c.anterioresRevogadas} anterior(es) revogada(s)' : ''}',
              style: BrutType.sans(11, color: BrutColors.inkMuted),
            ),
          ],
        ),
        actions: [
          BrutButton(
            key: const Key('copiar-token'),
            label: _copiado ? 'Copiado' : 'Copiar',
            icon: _copiado ? Icons.check : Icons.copy,
            variant: BrutButtonVariant.secondary,
            onPressed: _copiar,
          ),
          BrutButton(
            label: 'Já guardei',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
