import 'enums.dart';
import 'json.dart';

/// Modo do backend em `GET /arquitetura`. `interno` é o modo de reserva
/// (simulador embutido na API): aí `edge`, `fog` e `trafego` vêm nulos.
enum ModoArquitetura {
  camadas('camadas'),
  interno('interno');

  const ModoArquitetura(this.wire);

  final String wire;

  /// Qualquer valor diferente de `interno` é tratado como `camadas`.
  static ModoArquitetura fromWire(String? value) =>
      value == ModoArquitetura.interno.wire
          ? ModoArquitetura.interno
          : ModoArquitetura.camadas;
}

/// Resposta de `GET /arquitetura` — estado das camadas edge · fog · nuvem.
class EstadoArquitetura {
  const EstadoArquitetura({
    required this.modo,
    required this.brokerConectado,
    required this.edge,
    required this.fog,
    required this.trafego,
    required this.alertas,
    required this.geradoEm,
  });

  final ModoArquitetura modo;

  /// `nuvem.brokerConectado` — só o broker MQTT da nuvem. A API em si está no
  /// ar sempre que esta resposta chega.
  final bool brokerConectado;

  /// `null` até o primeiro relatório do fog (e sempre no modo interno).
  final EdgeInfo? edge;

  /// `null` até o fog se anunciar (e sempre no modo interno).
  final FogInfo? fog;

  /// Última janela de banda. `null` no modo interno.
  final TrafegoInfo? trafego;

  /// Até 20 mudanças de status diagnosticadas pelo fog, mais recentes primeiro.
  final List<AlertaFog> alertas;

  final DateTime geradoEm;

  bool get modoInterno => modo == ModoArquitetura.interno;

  factory EstadoArquitetura.fromJson(Json j) {
    final nuvem = j['nuvem'] as Json? ?? const {};
    return EstadoArquitetura(
      modo: ModoArquitetura.fromWire(j['modo'] as String?),
      brokerConectado: (nuvem['brokerConectado'] as bool?) ?? false,
      edge: j['edge'] is Map ? EdgeInfo.fromJson(j['edge'] as Json) : null,
      fog: j['fog'] is Map ? FogInfo.fromJson(j['fog'] as Json) : null,
      trafego: j['trafego'] is Map
          ? TrafegoInfo.fromJson(j['trafego'] as Json)
          : null,
      alertas: asList(j['alertas']).map(AlertaFog.fromJson).toList(),
      geradoEm: asDateOrNull(j['geradoEm']) ?? DateTime.now().toUtc(),
    );
  }
}

/// Camada edge (os 248 postes simulados), vista pelo fog.
class EdgeInfo {
  const EdgeInfo({required this.online});

  /// `null` = o fog ainda não sabe.
  final bool? online;

  factory EdgeInfo.fromJson(Json j) => EdgeInfo(online: j['online'] as bool?);
}

/// Camada fog — um gateway por bairro.
class FogInfo {
  const FogInfo({
    required this.online,
    required this.gateways,
    required this.buffer,
    required this.atualizadoEm,
  });

  final bool? online;
  final List<GatewayFog> gateways;

  /// Mensagens guardadas no fog esperando a nuvem (0 = em dia).
  final int buffer;

  /// Último relatório do fog.
  final DateTime? atualizadoEm;

  int get totalPostes => gateways.fold(0, (s, g) => s + g.postes);
  int get totalOnline => gateways.fold(0, (s, g) => s + g.online);

  factory FogInfo.fromJson(Json j) => FogInfo(
        online: j['online'] as bool?,
        gateways: asList(j['gateways']).map(GatewayFog.fromJson).toList(),
        buffer: asInt(j['buffer']),
        atualizadoEm: asDateOrNull(j['atualizadoEm']),
      );
}

class GatewayFog {
  const GatewayFog({
    required this.bairro,
    required this.postes,
    required this.online,
  });

  final String bairro;
  final int postes;
  final int online;

  int get offline => (postes - online).clamp(0, postes);

  factory GatewayFog.fromJson(Json j) => GatewayFog(
        bairro: j['bairro'] as String? ?? '—',
        postes: asInt(j['postes']),
        online: asInt(j['online']),
      );
}

/// Tráfego da última janela: postes → fog (entrada) e fog → nuvem (saída).
class TrafegoInfo {
  const TrafegoInfo({
    required this.janelaS,
    required this.entrada,
    required this.saida,
    required this.reducaoMsgsPct,
    required this.reducaoBytesPct,
    required this.postesTotal,
    required this.postesOnline,
    required this.em,
  });

  final int janelaS;
  final FluxoTrafego entrada;
  final FluxoTrafego saida;

  /// Redução percentual (0–100) na subida. `null` quando o backend não calcula.
  final double? reducaoMsgsPct;
  final double? reducaoBytesPct;

  final int postesTotal;
  final int postesOnline;

  /// Fim da janela.
  final DateTime? em;

  factory TrafegoInfo.fromJson(Json j) {
    final postes = j['postes'] as Json? ?? const {};
    return TrafegoInfo(
      janelaS: asInt(j['janelaS'], fallback: 60),
      entrada: FluxoTrafego.fromJson(j['entrada'] as Json? ?? const {}),
      saida: FluxoTrafego.fromJson(j['saida'] as Json? ?? const {}),
      reducaoMsgsPct: asDoubleOrNull(j['reducaoMsgsPct']),
      reducaoBytesPct: asDoubleOrNull(j['reducaoBytesPct']),
      postesTotal: asInt(postes['total']),
      postesOnline: asInt(postes['online']),
      em: asDateOrNull(j['em']),
    );
  }
}

class FluxoTrafego {
  const FluxoTrafego({required this.msgs, required this.bytes});

  final int msgs;
  final int bytes;

  factory FluxoTrafego.fromJson(Json j) => FluxoTrafego(
        msgs: asInt(j['msgs']),
        bytes: asInt(j['bytes']),
      );
}

/// Mudança de status diagnosticada pelo fog.
class AlertaFog {
  const AlertaFog({
    required this.posteId,
    required this.codigo,
    required this.bairro,
    required this.statusAnterior,
    required this.status,
    required this.motivo,
    required this.em,
  });

  /// Pode vir vazio num payload incompleto — aí o alerta não abre o detalhe.
  final String posteId;
  final String codigo;
  final String bairro;
  final StatusPoste statusAnterior;
  final StatusPoste status;
  final String motivo;
  final DateTime? em;

  bool get temPoste => posteId.isNotEmpty;

  factory AlertaFog.fromJson(Json j) => AlertaFog(
        posteId: j['posteId'] as String? ?? '',
        codigo: j['codigo'] as String? ?? '—',
        bairro: j['bairro'] as String? ?? '',
        statusAnterior:
            StatusPoste.fromWire(j['statusAnterior'] as String? ?? ''),
        status: StatusPoste.fromWire(j['status'] as String? ?? ''),
        motivo: j['motivo'] as String? ?? '',
        em: asDateOrNull(j['em']),
      );
}
