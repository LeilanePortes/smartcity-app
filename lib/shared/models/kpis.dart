import 'enums.dart';
import 'json.dart';

/// Resposta de `GET /kpis` — consumo, custo e variação da rede no período.
class KpisResumo {
  const KpisResumo({
    required this.periodo,
    required this.geradoEm,
    required this.tarifa,
    required this.atual,
    required this.anterior,
    required this.variacaoConsumoPct,
    required this.variacaoCustoPct,
    required this.parcialHoje,
    required this.serie,
  });

  final PeriodoKpi periodo;
  final DateTime geradoEm;
  final Tarifa tarifa;
  final JanelaKpi atual;
  final JanelaKpi anterior;

  /// `null` quando não há base anterior (anterior == 0).
  final double? variacaoConsumoPct;
  final double? variacaoCustoPct;

  final JanelaKpi parcialHoje;
  final SerieComparativa serie;

  factory KpisResumo.fromJson(Json j) {
    final variacao = j['variacao'] as Json? ?? const {};
    return KpisResumo(
      periodo: PeriodoKpi.values.firstWhere(
        (p) => p.wire == (j['periodo'] as String? ?? 'mes'),
        orElse: () => PeriodoKpi.mes,
      ),
      geradoEm: asDate(j['geradoEm']),
      tarifa: Tarifa.fromJson(j['tarifa'] as Json),
      atual: JanelaKpi.fromJson(j['atual'] as Json),
      anterior: JanelaKpi.fromJson(j['anterior'] as Json),
      variacaoConsumoPct: asDoubleOrNull(variacao['consumoPct']),
      variacaoCustoPct: asDoubleOrNull(variacao['custoPct']),
      parcialHoje: JanelaKpi.fromJson(j['parcialHoje'] as Json),
      serie: SerieComparativa.fromJson(j['serie'] as Json),
    );
  }
}

class Tarifa {
  const Tarifa({
    required this.classe,
    required this.descricao,
    required this.valorKwh,
  });

  final String classe;
  final String descricao;
  final double valorKwh;

  factory Tarifa.fromJson(Json j) => Tarifa(
        classe: j['classe'] as String? ?? 'B4a',
        descricao: j['descricao'] as String? ?? 'Iluminação pública',
        valorKwh: asDouble(j['valorKwh'], fallback: 0.58),
      );
}

class JanelaKpi {
  const JanelaKpi({
    required this.inicio,
    required this.fim,
    required this.consumoKwh,
    required this.custoReais,
  });

  final DateTime inicio;
  final DateTime fim;
  final double consumoKwh;
  final double custoReais;

  factory JanelaKpi.fromJson(Json j) => JanelaKpi(
        inicio: asDate(j['inicio']),
        fim: asDate(j['fim']),
        consumoKwh: asDouble(j['consumoKwh']),
        custoReais: asDouble(j['custoReais']),
      );
}

/// `serie` de `GET /kpis`. `atual` e `anterior` alinhados por índice.
class SerieComparativa {
  const SerieComparativa({
    required this.granularidade,
    required this.atual,
    required this.anterior,
  });

  /// "hora" | "dia" | "mes"
  final String granularidade;
  final List<PontoSerie> atual;
  final List<PontoSerie> anterior;

  factory SerieComparativa.fromJson(Json j) => SerieComparativa(
        granularidade: j['granularidade'] as String? ?? 'dia',
        atual: asList(j['atual']).map(PontoSerie.fromJson).toList(),
        anterior: asList(j['anterior']).map(PontoSerie.fromJson).toList(),
      );
}

class PontoSerie {
  const PontoSerie({required this.inicio, required this.consumoKwh});

  final DateTime inicio;
  final double consumoKwh;

  factory PontoSerie.fromJson(Json j) => PontoSerie(
        inicio: asDate(j['inicio']),
        consumoKwh: asDouble(j['consumoKwh']),
      );
}

/// Resposta de `GET /kpis/maior-consumo` — ranking de consumo.
class RankingConsumo {
  const RankingConsumo({
    required this.periodo,
    required this.inicio,
    required this.fim,
    required this.itens,
  });

  final PeriodoKpi periodo;
  final DateTime inicio;
  final DateTime fim;
  final List<ItemRanking> itens;

  factory RankingConsumo.fromJson(Json j) => RankingConsumo(
        periodo: PeriodoKpi.values.firstWhere(
          (p) => p.wire == (j['periodo'] as String? ?? 'mes'),
          orElse: () => PeriodoKpi.mes,
        ),
        inicio: asDate(j['inicio']),
        fim: asDate(j['fim']),
        itens: asList(j['ranking']).map(ItemRanking.fromJson).toList(),
      );
}

class ItemRanking {
  const ItemRanking({
    required this.posicao,
    required this.posteId,
    required this.codigo,
    required this.endereco,
    required this.bairro,
    required this.consumoKwh,
    required this.custoReais,
    this.status,
  });

  final int posicao;
  final String posteId;
  final String codigo;
  final String endereco;
  final String bairro;
  final double consumoKwh;
  final double custoReais;

  /// Status do poste, quando a API o inclui no ranking (`null` = não informado).
  final StatusPoste? status;

  factory ItemRanking.fromJson(Json j) => ItemRanking(
        posicao: asInt(j['posicao']),
        posteId: j['posteId'] as String,
        codigo: j['codigo'] as String,
        endereco: j['endereco'] as String,
        bairro: j['bairro'] as String,
        consumoKwh: asDouble(j['consumoKwh']),
        custoReais: asDouble(j['custoReais']),
        status: j['status'] == null
            ? null
            : StatusPoste.fromWire(j['status'] as String),
      );
}

/// Resposta de `GET /kpis/postes-por-status` — barra empilhada do dashboard.
class PostesPorStatus {
  const PostesPorStatus({required this.total, required this.contagens});

  final int total;

  /// Sempre as 4 categorias, mesmo com quantidade 0.
  final List<ContagemStatus> contagens;

  int quantidadeDe(StatusPoste s) => contagens
      .firstWhere(
        (c) => c.status == s,
        orElse: () => ContagemStatus(status: s, quantidade: 0),
      )
      .quantidade;

  factory PostesPorStatus.fromJson(Json j) => PostesPorStatus(
        total: asInt(j['total']),
        contagens:
            asList(j['porStatus']).map(ContagemStatus.fromJson).toList(),
      );
}

class ContagemStatus {
  const ContagemStatus({required this.status, required this.quantidade});

  final StatusPoste status;
  final int quantidade;

  factory ContagemStatus.fromJson(Json j) => ContagemStatus(
        status: StatusPoste.fromWire(j['status'] as String),
        quantidade: asInt(j['quantidade']),
      );
}
