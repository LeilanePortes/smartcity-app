import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brut_colors.dart';
import '../../core/theme/brut_spacing.dart';
import '../../core/theme/brut_typography.dart';
import '../../shared/data/smartcity_api.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import 'dispositivo_detalhe_screen.dart';
import 'dispositivos_providers.dart';
import 'widgets/dialogos.dart';

/// Formato do código aceito pela API: letras minúsculas, números, `.`, `-`, `_`.
final RegExp kFormatoCodigo = RegExp(r'^[a-z0-9._-]+$');

/// Cadastro (`POST /dispositivos`) e edição (`PATCH /dispositivos/:ref`).
/// Com [editando], o código fica travado (é imutável na API).
class DispositivoFormScreen extends ConsumerStatefulWidget {
  const DispositivoFormScreen({super.key, this.editando});

  final Dispositivo? editando;

  @override
  ConsumerState<DispositivoFormScreen> createState() =>
      _DispositivoFormScreenState();
}

class _DispositivoFormScreenState extends ConsumerState<DispositivoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _nome;
  late final TextEditingController _fabricante;
  late final TextEditingController _modelo;
  late final TextEditingController _firmware;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;

  String? _dominio;
  String? _perfil;
  String? _site;
  String? _area;

  bool _enviando = false;

  /// Mensagem da API (400/409) mostrada acima do botão de salvar.
  String? _erroApi;

  bool get _editando => widget.editando != null;

  @override
  void initState() {
    super.initState();
    final d = widget.editando;
    _codigo = TextEditingController(text: d?.codigo ?? '');
    _nome = TextEditingController(text: d?.nome ?? '');
    _fabricante = TextEditingController(text: d?.fabricante ?? '');
    _modelo = TextEditingController(text: d?.modelo ?? '');
    _firmware = TextEditingController(text: d?.firmware ?? '');
    _latitude = TextEditingController(text: d?.latitude?.toString() ?? '');
    _longitude = TextEditingController(text: d?.longitude?.toString() ?? '');
    _dominio = d?.dominio.slug;
    _perfil = d?.perfil.slug;
    _site = d?.site.slug;
    _area = d?.area?.slug;
  }

  @override
  void dispose() {
    for (final c in [
      _codigo, _nome, _fabricante, _modelo, _firmware, _latitude, _longitude,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static double? _numero(String s) =>
      s.trim().isEmpty ? null : double.tryParse(s.trim().replaceAll(',', '.'));

  static String? _obrigatorio(String? v, {int max = 120}) {
    if (v == null || v.trim().isEmpty) return 'Obrigatório';
    if (v.trim().length > max) return 'Até $max caracteres';
    return null;
  }

  static String? Function(String?) _coordenada(double limite) => (v) {
        if (v == null || v.trim().isEmpty) return null;
        final n = _numero(v);
        if (n == null) return 'Número inválido';
        if (n < -limite || n > limite) return 'Entre -$limite e $limite';
        return null;
      };

  DadosDispositivo _dados() => DadosDispositivo(
        codigo: _codigo.text,
        nome: _nome.text,
        dominio: _dominio!,
        perfil: _perfil!,
        site: _site!,
        area: _area,
        fabricante: _fabricante.text,
        modelo: _modelo.text,
        firmware: _firmware.text,
        latitude: _numero(_latitude.text),
        longitude: _numero(_longitude.text),
      );

  Future<void> _salvar() async {
    setState(() => _erroApi = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _enviando = true);
    final api = ref.read(smartcityApiProvider);
    try {
      if (_editando) {
        final salvo =
            await api.atualizarDispositivo(widget.editando!.codigo, _dados());
        if (mounted) Navigator.of(context).pop(salvo);
        return;
      }
      final cadastro = await api.cadastrarDispositivo(_dados());
      ref.invalidate(listaDispositivosProvider);
      if (!mounted) return;
      await mostrarToken(
        context,
        cadastro.credencial,
        titulo: '${cadastro.dispositivo.codigo} cadastrado',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) =>
            DispositivoDetalheScreen(codigo: cadastro.dispositivo.codigo),
      ));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _erroApi = e.statusCode == null
            ? e.message
            : '${e.message} (${e.statusCode})');
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editando ? 'Editar ${widget.editando!.codigo}' : 'Novo dispositivo',
          style: BrutType.sans(18, weight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BrutSpacing.md),
          children: [
            _Campo(
              chave: 'campo-codigo',
              rotulo: 'Código',
              controller: _codigo,
              enabled: !_editando,
              dica: _editando
                  ? 'O código não muda depois do cadastro (está nos tópicos MQTT).'
                  : 'Minúsculas, números, ".", "-" e "_" (ex.: medidor-centro).',
              validator: _editando
                  ? null
                  : (v) {
                      final e = _obrigatorio(v);
                      if (e != null) return e;
                      if (!kFormatoCodigo.hasMatch(v!.trim())) {
                        return 'Só letras minúsculas, números, ".", "-" e "_"';
                      }
                      return null;
                    },
            ),
            _Campo(
              chave: 'campo-nome',
              rotulo: 'Nome',
              controller: _nome,
              validator: _obrigatorio,
            ),
            _Seletor(
              chave: 'campo-dominio',
              rotulo: 'Domínio',
              opcoes: ref.watch(dominiosProvider),
              valor: _dominio,
              onChanged: (v) => setState(() => _dominio = v),
              onRetry: () => ref.invalidate(dominiosProvider),
            ),
            _Seletor(
              chave: 'campo-perfil',
              rotulo: 'Perfil',
              opcoes: ref.watch(perfisProvider),
              valor: _perfil,
              onChanged: (v) => setState(() => _perfil = v),
              onRetry: () => ref.invalidate(perfisProvider),
            ),
            _Seletor(
              chave: 'campo-site',
              rotulo: 'Local',
              opcoes: ref.watch(sitesProvider),
              valor: _site,
              // Trocar o local limpa a área (a área precisa ser do local).
              onChanged: (v) => setState(() {
                if (v != _site) _area = null;
                _site = v;
              }),
              onRetry: () => ref.invalidate(sitesProvider),
            ),
            if (_site == null)
              const _Nota('Escolha o local para ver as áreas.')
            else
              _Seletor(
                key: ValueKey('area-$_site'),
                chave: 'campo-area',
                rotulo: 'Área (opcional)',
                opcoes: ref.watch(areasProvider(_site!)),
                valor: _area,
                opcional: 'Sem área',
                onChanged: (v) => setState(() => _area = v),
                onRetry: () => ref.invalidate(areasProvider(_site!)),
              ),
            _Campo(
              chave: 'campo-fabricante',
              rotulo: 'Fabricante',
              controller: _fabricante,
              validator: _obrigatorio,
            ),
            _Campo(
              chave: 'campo-modelo',
              rotulo: 'Modelo (opcional)',
              controller: _modelo,
              validator: (v) =>
                  (v != null && v.trim().length > 120) ? 'Até 120 caracteres' : null,
            ),
            _Campo(
              chave: 'campo-firmware',
              rotulo: 'Firmware',
              controller: _firmware,
              dica: 'Ex.: 1.0.0',
              validator: (v) => _obrigatorio(v, max: 40),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Campo(
                    chave: 'campo-latitude',
                    rotulo: 'Latitude (opcional)',
                    controller: _latitude,
                    numero: true,
                    validator: _coordenada(90),
                  ),
                ),
                const SizedBox(width: BrutSpacing.sm),
                Expanded(
                  child: _Campo(
                    chave: 'campo-longitude',
                    rotulo: 'Longitude (opcional)',
                    controller: _longitude,
                    numero: true,
                    validator: _coordenada(180),
                  ),
                ),
              ],
            ),
            if (_erroApi != null) ...[
              const SizedBox(height: BrutSpacing.sm),
              Container(
                key: const Key('erro-api'),
                padding: const EdgeInsets.all(BrutSpacing.sm),
                decoration: BoxDecoration(
                  color: BrutColors.statusFalhaSoft,
                  border:
                      Border.all(color: BrutColors.destaque, width: BrutStroke.regular),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.priority_high,
                        size: 18, color: BrutColors.destaque),
                    const SizedBox(width: BrutSpacing.sm),
                    Expanded(
                      child: Text(_erroApi!,
                          style: BrutType.sans(13, weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: BrutSpacing.md),
            BrutButton(
              key: const Key('salvar-dispositivo'),
              label: _editando ? 'Salvar alterações' : 'Cadastrar',
              icon: _editando ? Icons.save_outlined : Icons.add,
              expand: true,
              loading: _enviando,
              onPressed: _enviando ? null : _salvar,
            ),
            if (!_editando) ...[
              const SizedBox(height: BrutSpacing.sm),
              const _Nota(
                  'Ao cadastrar, a API emite a credencial do dispositivo. O token '
                  'aparece uma única vez.'),
            ],
            const SizedBox(height: BrutSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _Nota extends StatelessWidget {
  const _Nota(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: BrutSpacing.md),
        child: Text(texto, style: BrutType.sans(12, color: BrutColors.inkMuted)),
      );
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.chave,
    required this.rotulo,
    required this.controller,
    this.validator,
    this.dica,
    this.enabled = true,
    this.numero = false,
  });

  final String chave;
  final String rotulo;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? dica;
  final bool enabled;
  final bool numero;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BrutSpacing.md),
      child: TextFormField(
        key: Key(chave),
        controller: controller,
        enabled: enabled,
        validator: validator,
        keyboardType: numero
            ? const TextInputType.numberWithOptions(signed: true, decimal: true)
            : TextInputType.text,
        style: BrutType.sans(14),
        decoration: InputDecoration(
          labelText: rotulo,
          helperText: dica,
          helperMaxLines: 2,
          isDense: true,
        ),
      ),
    );
  }
}

/// Seletor de um item do catálogo (por `slug`), com carregando/erro.
class _Seletor extends StatelessWidget {
  const _Seletor({
    super.key,
    required this.chave,
    required this.rotulo,
    required this.opcoes,
    required this.valor,
    required this.onChanged,
    required this.onRetry,
    this.opcional,
  });

  final String chave;
  final String rotulo;
  final AsyncValue<List<ItemCatalogo>> opcoes;
  final String? valor;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;

  /// Rótulo da opção "nenhum" (campo opcional). `null` = obrigatório.
  final String? opcional;

  @override
  Widget build(BuildContext context) {
    final itens = opcoes.value;
    if (itens == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: BrutSpacing.md),
        child: opcoes.hasError
            ? Row(
                children: [
                  Expanded(
                    child: Text('Não foi possível carregar ${rotulo.toLowerCase()}.',
                        style: BrutType.sans(12, color: BrutColors.destaque)),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
                ],
              )
            : Text('Carregando ${rotulo.toLowerCase()}…',
                style: BrutType.sans(12, color: BrutColors.inkMuted)),
      );
    }
    // Valor que não está mais nas opções (ex.: removido) não quebra o campo.
    final atual = itens.any((i) => i.slug == valor) ? valor : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: BrutSpacing.md),
      child: DropdownButtonFormField<String?>(
        key: Key(chave),
        initialValue: atual,
        isExpanded: true,
        decoration: InputDecoration(labelText: rotulo, isDense: true),
        style: BrutType.sans(14),
        items: [
          if (opcional != null)
            DropdownMenuItem<String?>(value: null, child: Text(opcional!)),
          for (final i in itens)
            DropdownMenuItem<String?>(
              value: i.slug,
              child: Text(i.nome, overflow: TextOverflow.ellipsis),
            ),
        ],
        validator: opcional != null
            ? null
            : (v) => v == null ? 'Obrigatório' : null,
        onChanged: onChanged,
      ),
    );
  }
}
