import 'arquitetura.dart';
import 'json.dart';

/// Status de uma implantação OTA (`implantacao.status`).
enum StatusImplantacao {
  emAndamento('EM_ANDAMENTO', 'Em andamento'),
  concluida('CONCLUIDA', 'Concluída'),
  revertida('REVERTIDA', 'Revertida'),
  desconhecido('', 'Desconhecido');

  const StatusImplantacao(this.wire, this.label);

  final String wire;
  final String label;

  static StatusImplantacao fromWire(String? value) =>
      StatusImplantacao.values.firstWhere(
        (s) => s.wire.isNotEmpty && s.wire == value,
        orElse: () => StatusImplantacao.desconhecido,
      );
}

/// Decisão tomada pela nuvem em cada portão (`decisoes[].decisao`).
enum DecisaoPortao {
  avancar('AVANCAR', 'Avançar'),
  estender('ESTENDER', 'Estender'),
  concluir('CONCLUIR', 'Concluir'),
  reverter('REVERTER', 'Reverter'),
  desconhecida('', 'Desconhecida');

  const DecisaoPortao(this.wire, this.label);

  final String wire;
  final String label;

  static DecisaoPortao fromWire(String? value) =>
      DecisaoPortao.values.firstWhere(
        (d) => d.wire.isNotEmpty && d.wire == value,
        orElse: () => DecisaoPortao.desconhecida,
      );
}

/// Resposta de `GET /ota` (e dos `POST /ota/...`, que devolvem o mesmo corpo).
class EstadoOta {
  const EstadoOta({
    required this.modo,
    required this.catalogo,
    required this.versoesEmCampo,
    required this.criterios,
    required this.implantacao,
  });

  /// OTA só funciona em `camadas`; em `interno` os POST respondem 409.
  final ModoArquitetura modo;
  final List<VersaoFirmware> catalogo;

  /// Quantos postes rodam cada versão, na ordem do JSON
  /// (`desconhecida` = sem reportar).
  final List<VersaoEmCampo> versoesEmCampo;
  final CriteriosOta criterios;

  /// `null` se nenhuma implantação foi iniciada desde que a API subiu.
  final ImplantacaoOta? implantacao;

  bool get otaDisponivel => modo == ModoArquitetura.camadas;

  bool get emAndamento =>
      implantacao?.status == StatusImplantacao.emAndamento;

  int get totalEmCampo => versoesEmCampo.fold(0, (s, v) => s + v.postes);

  /// Versão rodando no maior número de postes (ignora `desconhecida`).
  String? get versaoPredominante {
    VersaoEmCampo? maior;
    for (final v in versoesEmCampo) {
      if (v.desconhecida) continue;
      if (maior == null || v.postes > maior.postes) maior = v;
    }
    return maior?.versao;
  }

  factory EstadoOta.fromJson(Json j) {
    final campo = j['versoesEmCampo'];
    return EstadoOta(
      modo: ModoArquitetura.fromWire(j['modo'] as String?),
      catalogo: asList(j['catalogo']).map(VersaoFirmware.fromJson).toList(),
      versoesEmCampo: campo is Map
          ? [
              for (final e in campo.entries)
                VersaoEmCampo(versao: e.key.toString(), postes: asInt(e.value)),
            ]
          : const [],
      criterios: CriteriosOta.fromJson(j['criterios'] as Json? ?? const {}),
      implantacao: j['implantacao'] is Map
          ? ImplantacaoOta.fromJson(j['implantacao'] as Json)
          : null,
    );
  }
}

class VersaoFirmware {
  const VersaoFirmware({required this.versao, required this.descricao});

  final String versao;
  final String descricao;

  factory VersaoFirmware.fromJson(Json j) => VersaoFirmware(
        versao: j['versao'] as String? ?? '—',
        descricao: j['descricao'] as String? ?? '',
      );
}

class VersaoEmCampo {
  const VersaoEmCampo({required this.versao, required this.postes});

  final String versao;
  final int postes;

  bool get desconhecida => versao == 'desconhecida';
}

/// Critérios definidos antes de começar a implantação.
class CriteriosOta {
  const CriteriosOta({
    required this.ondas,
    required this.janelaS,
    required this.limiarFalhaInstalacaoPct,
    required this.limiarRazaoConsumo,
    required this.minReportePct,
    required this.maxExtensoes,
  });

  /// % acumulado da frota em cada onda.
  final List<int> ondas;

  /// Observação por onda, em segundos.
  final int janelaS;
  final double limiarFalhaInstalacaoPct;

  /// Consumo do canário ÷ controle acima disto → reverte.
  final double limiarRazaoConsumo;
  final double minReportePct;
  final int maxExtensoes;

  factory CriteriosOta.fromJson(Json j) {
    final ondas = asListaInt(j['ondas']);
    return CriteriosOta(
      ondas: ondas.isEmpty ? const [5, 25, 50, 100] : ondas,
      janelaS: asInt(j['janelaS'], fallback: 120),
      limiarFalhaInstalacaoPct:
          asDouble(j['limiarFalhaInstalacaoPct'], fallback: 5),
      limiarRazaoConsumo: asDouble(j['limiarRazaoConsumo'], fallback: 1.5),
      minReportePct: asDouble(j['minReportePct'], fallback: 60),
      maxExtensoes: asInt(j['maxExtensoes'], fallback: 2),
    );
  }
}

/// Implantação em andamento ou a última encerrada.
class ImplantacaoOta {
  const ImplantacaoOta({
    required this.versao,
    required this.versaoAnterior,
    required this.status,
    required this.iniciadaEm,
    required this.encerradaEm,
    required this.ondas,
    required this.ondaAtual,
    required this.ondaAtualPct,
    required this.proximaAvaliacaoEm,
    required this.aparelhos,
    required this.canario,
    required this.controle,
    required this.metricas,
    required this.falhas,
    required this.decisoes,
  });

  final String versao;
  final String versaoAnterior;
  final StatusImplantacao status;
  final DateTime? iniciadaEm;
  final DateTime? encerradaEm;

  /// Ex.: `[5, 25, 50, 100]`; [ondaAtual] é o índice nesta lista.
  final List<int> ondas;
  final int ondaAtual;
  final int ondaAtualPct;

  /// Próximo portão de decisão — só enquanto `EM_ANDAMENTO`.
  final DateTime? proximaAvaliacaoEm;
  final AparelhosOta aparelhos;

  /// Códigos dos postes na versão nova × amostra que segue na antiga.
  final List<String> canario;
  final List<String> controle;

  /// `null` até o primeiro portão.
  final MetricasOta? metricas;
  final List<FalhaOta> falhas;

  /// Um item por portão, em ordem.
  final List<DecisaoOta> decisoes;

  factory ImplantacaoOta.fromJson(Json j) {
    final grupos = j['grupos'] as Json? ?? const {};
    final ondas = asListaInt(j['ondas']);
    return ImplantacaoOta(
      versao: j['versao'] as String? ?? '—',
      versaoAnterior: j['versaoAnterior'] as String? ?? '—',
      status: StatusImplantacao.fromWire(j['status'] as String?),
      iniciadaEm: asDateOrNull(j['iniciadaEm']),
      encerradaEm: asDateOrNull(j['encerradaEm']),
      ondas: ondas.isEmpty ? const [5, 25, 50, 100] : ondas,
      ondaAtual: asInt(j['ondaAtual']),
      ondaAtualPct: asInt(j['ondaAtualPct']),
      proximaAvaliacaoEm: asDateOrNull(j['proximaAvaliacaoEm']),
      aparelhos: AparelhosOta.fromJson(j['aparelhos'] as Json? ?? const {}),
      canario: asListaString(grupos['canario']),
      controle: asListaString(grupos['controle']),
      metricas: j['metricas'] is Map
          ? MetricasOta.fromJson(j['metricas'] as Json)
          : null,
      falhas: asList(j['falhas']).map(FalhaOta.fromJson).toList(),
      decisoes: asList(j['decisoes']).map(DecisaoOta.fromJson).toList(),
    );
  }
}

class AparelhosOta {
  const AparelhosOta({
    required this.elegiveis,
    required this.enviados,
    required this.instalados,
    required this.falhas,
    required this.pendentes,
    required this.revertidos,
  });

  final int elegiveis;
  final int enviados;
  final int instalados;
  final int falhas;
  final int pendentes;
  final int revertidos;

  factory AparelhosOta.fromJson(Json j) => AparelhosOta(
        elegiveis: asInt(j['elegiveis']),
        enviados: asInt(j['enviados']),
        instalados: asInt(j['instalados']),
        falhas: asInt(j['falhas']),
        pendentes: asInt(j['pendentes']),
        revertidos: asInt(j['revertidos']),
      );
}

/// Métricas do último portão: canário × controle.
class MetricasOta {
  const MetricasOta({
    required this.canario,
    required this.controle,
    required this.referenciaConsumo,
    required this.razaoConsumo,
  });

  final GrupoMetricas? canario;

  /// `null` quando não há grupo de controle (onda de 100%).
  final GrupoMetricas? controle;
  final double? referenciaConsumo;

  /// Canário ÷ controle.
  final double? razaoConsumo;

  factory MetricasOta.fromJson(Json j) => MetricasOta(
        canario: j['canario'] is Map
            ? GrupoMetricas.fromJson(j['canario'] as Json)
            : null,
        controle: j['controle'] is Map
            ? GrupoMetricas.fromJson(j['controle'] as Json)
            : null,
        referenciaConsumo: asDoubleOrNull(j['referenciaConsumo']),
        razaoConsumo: asDoubleOrNull(j['razaoConsumo']),
      );
}

class GrupoMetricas {
  const GrupoMetricas({
    required this.aparelhos,
    required this.reportaram,
    required this.consumoNormalizadoMedio,
    required this.consumoAltoPct,
  });

  final int aparelhos;
  final int reportaram;

  /// kW a 100% de luminosidade (independe de pico/piso).
  final double? consumoNormalizadoMedio;
  final double? consumoAltoPct;

  factory GrupoMetricas.fromJson(Json j) => GrupoMetricas(
        aparelhos: asInt(j['aparelhos']),
        reportaram: asInt(j['reportaram']),
        consumoNormalizadoMedio: asDoubleOrNull(j['consumoNormalizadoMedio']),
        consumoAltoPct: asDoubleOrNull(j['consumoAltoPct']),
      );
}

class FalhaOta {
  const FalhaOta({required this.codigo, required this.motivo});

  final String codigo;
  final String motivo;

  factory FalhaOta.fromJson(Json j) => FalhaOta(
        codigo: j['codigo'] as String? ?? '—',
        motivo: j['motivo'] as String? ?? '',
      );
}

class DecisaoOta {
  const DecisaoOta({
    required this.em,
    required this.ondaPct,
    required this.decisao,
    required this.motivo,
    required this.razaoConsumo,
  });

  final DateTime? em;
  final int ondaPct;
  final DecisaoPortao decisao;
  final String motivo;
  final double? razaoConsumo;

  factory DecisaoOta.fromJson(Json j) => DecisaoOta(
        em: asDateOrNull(j['em']),
        ondaPct: asInt(j['ondaPct']),
        decisao: DecisaoPortao.fromWire(j['decisao'] as String?),
        motivo: j['motivo'] as String? ?? '',
        razaoConsumo: asDoubleOrNull(j['razaoConsumo']),
      );
}
