import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brut_colors.dart';
import '../../../core/theme/brut_typography.dart';
import '../mapa_providers.dart';

/// Campo de busca por rua ou bairro (PRD §5.1). Debounce de 400 ms antes de
/// atualizar o filtro que dispara `GET /postes?busca=`.
class BuscaField extends ConsumerStatefulWidget {
  const BuscaField({super.key});

  @override
  ConsumerState<BuscaField> createState() => _BuscaFieldState();
}

class _BuscaFieldState extends ConsumerState<BuscaField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // atualiza o botão de limpar
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(mapaFiltroProvider.notifier).setBusca(value);
    });
  }

  void _limpar() {
    _controller.clear();
    _debounce?.cancel();
    ref.read(mapaFiltroProvider.notifier).setBusca('');
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final temTexto = _controller.text.isNotEmpty;
    // Hairline tênue do design aprovado (o tema global usa traço de tinta).
    const borda = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: BrutColors.lineSoft, width: 1),
    );
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      style: BrutType.sans(14),
      decoration: InputDecoration(
        hintText: 'Buscar rua ou bairro',
        prefixIcon:
            const Icon(Icons.search, color: BrutColors.inkMuted, size: 20),
        suffixIcon: temTexto
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: _limpar,
              )
            : null,
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
