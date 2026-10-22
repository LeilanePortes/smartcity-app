import 'json.dart';

/// Referência a um item do catálogo dentro de um dispositivo
/// (`inquilino`, `dominio`, `perfil`, `site`, `area`): `{ id, slug, nome }`.
class RefCatalogo {
  const RefCatalogo({required this.id, required this.slug, required this.nome});

  final String id;
  final String slug;
  final String nome;

  static RefCatalogo? fromJsonOrNull(dynamic v) =>
      v is Map ? RefCatalogo.fromJson(v.cast<String, dynamic>()) : null;

  factory RefCatalogo.fromJson(Json j) => RefCatalogo(
        id: j['id'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        nome: j['nome'] as String? ?? j['slug'] as String? ?? '—',
      );

  static const vazio = RefCatalogo(id: '', slug: '', nome: '—');
}

/// Item das listagens do catálogo (`GET /catalogo/dominios`,
/// `/catalogo/perfis`, `/sites`, `/sites/:ref/areas`) — usado nos seletores.
class ItemCatalogo {
  const ItemCatalogo({
    required this.id,
    required this.slug,
    required this.nome,
    this.descricao,
    this.tipo,
    this.dispositivos,
  });

  final String id;
  final String slug;
  final String nome;
  final String? descricao;

  /// Locais e áreas: `bairro`, `rua`… (livre).
  final String? tipo;

  /// Quantos dispositivos usam o item (contagem da API).
  final int? dispositivos;

  factory ItemCatalogo.fromJson(Json j) => ItemCatalogo(
        id: j['id'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        nome: j['nome'] as String? ?? j['slug'] as String? ?? '—',
        descricao: j['descricao'] as String?,
        tipo: j['tipo'] as String?,
        dispositivos: j['dispositivos'] == null ? null : asInt(j['dispositivos']),
      );
}

/// `conexao` do dispositivo (RF-DIS-06): online = última mensagem há no máximo
/// `limiteOfflineS` (3 × o intervalo do perfil).
class ConexaoDispositivo {
  const ConexaoDispositivo({
    required this.online,
    required this.ultimaMensagemEm,
    required this.limiteOfflineS,
  });

  final bool online;
  final DateTime? ultimaMensagemEm;
  final int limiteOfflineS;

  factory ConexaoDispositivo.fromJson(Json j) => ConexaoDispositivo(
        online: (j['online'] as bool?) ?? false,
        ultimaMensagemEm: asDateOrNull(j['ultimaMensagemEm']),
        limiteOfflineS: asInt(j['limiteOfflineS']),
      );
}

/// Estado da credencial no cadastro — nunca traz o token.
class CredencialResumo {
  const CredencialResumo({required this.ativa, this.prefixo, this.emitidaEm});

  final bool ativa;
  final String? prefixo;
  final DateTime? emitidaEm;

  factory CredencialResumo.fromJson(Json j) => CredencialResumo(
        ativa: (j['ativa'] as bool?) ?? false,
        prefixo: j['prefixo'] as String?,
        emitidaEm: asDateOrNull(j['emitidaEm']),
      );
}

/// `Dispositivo` do catálogo (RF-DIS-01).
class Dispositivo {
  const Dispositivo({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.inquilino,
    required this.dominio,
    required this.perfil,
    required this.site,
    required this.area,
    required this.fabricante,
    required this.modelo,
    required this.firmware,
    required this.latitude,
    required this.longitude,
    required this.posteId,
    required this.conexao,
    required this.credencial,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  final String id;

  /// Único no inquilino e imutável (é o `{dispositivo}` do tópico MQTT).
  final String codigo;
  final String nome;
  final RefCatalogo inquilino;
  final RefCatalogo dominio;
  final RefCatalogo perfil;
  final RefCatalogo site;
  final RefCatalogo? area;
  final String fabricante;
  final String? modelo;
  final String firmware;

  /// De `geo` (GeoJSON `Point`, `[lon, lat]`); `null` sem geo.
  final double? latitude;
  final double? longitude;

  /// Poste ligado (só nos dispositivos de iluminação).
  final String? posteId;
  final ConexaoDispositivo conexao;
  final CredencialResumo credencial;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  bool get temGeo => latitude != null && longitude != null;

  factory Dispositivo.fromJson(Json j) {
    double? lat;
    double? lon;
    final geo = j['geo'];
    if (geo is Map && geo['coordinates'] is List) {
      final c = geo['coordinates'] as List;
      if (c.length >= 2) {
        lon = asDoubleOrNull(c[0]);
        lat = asDoubleOrNull(c[1]);
      }
    }
    return Dispositivo(
      id: j['id'] as String? ?? '',
      codigo: j['codigo'] as String? ?? '—',
      nome: j['nome'] as String? ?? '',
      inquilino: RefCatalogo.fromJsonOrNull(j['inquilino']) ?? RefCatalogo.vazio,
      dominio: RefCatalogo.fromJsonOrNull(j['dominio']) ?? RefCatalogo.vazio,
      perfil: RefCatalogo.fromJsonOrNull(j['perfil']) ?? RefCatalogo.vazio,
      site: RefCatalogo.fromJsonOrNull(j['site']) ?? RefCatalogo.vazio,
      area: RefCatalogo.fromJsonOrNull(j['area']),
      fabricante: j['fabricante'] as String? ?? '',
      modelo: j['modelo'] as String?,
      firmware: j['firmware'] as String? ?? '',
      latitude: lat,
      longitude: lon,
      posteId: j['posteId'] as String?,
      conexao: ConexaoDispositivo.fromJson(
          (j['conexao'] as Map?)?.cast<String, dynamic>() ?? const {}),
      credencial: CredencialResumo.fromJson(
          (j['credencial'] as Map?)?.cast<String, dynamic>() ?? const {}),
      criadoEm: asDateOrNull(j['criadoEm']),
      atualizadoEm: asDateOrNull(j['atualizadoEm']),
    );
  }
}

/// Token recém-emitido (RF-DIS-02). **Só existe na resposta** do cadastro ou da
/// emissão — o app mostra uma vez e não guarda.
class CredencialEmitida {
  const CredencialEmitida({
    required this.token,
    required this.prefixo,
    required this.emitidaEm,
    required this.aviso,
    this.anterioresRevogadas,
  });

  final String token;
  final String prefixo;
  final DateTime? emitidaEm;
  final String aviso;

  /// Só na emissão (`POST /dispositivos/:ref/credenciais`).
  final int? anterioresRevogadas;

  static const avisoPadrao =
      'Guarde este token agora: ele não é mostrado de novo.';

  /// Aceita o objeto `credencial` do cadastro e o corpo plano da emissão.
  factory CredencialEmitida.fromJson(Json j) => CredencialEmitida(
        token: j['token'] as String? ?? '',
        prefixo: j['prefixo'] as String? ?? '',
        emitidaEm: asDateOrNull(j['emitidaEm']),
        aviso: j['aviso'] as String? ?? avisoPadrao,
        anterioresRevogadas: j['anterioresRevogadas'] == null
            ? null
            : asInt(j['anterioresRevogadas']),
      );
}

/// Resposta `201` de `POST /dispositivos`: `{ dispositivo, credencial }`.
class CadastroDispositivo {
  const CadastroDispositivo({required this.dispositivo, required this.credencial});

  final Dispositivo dispositivo;
  final CredencialEmitida credencial;

  factory CadastroDispositivo.fromJson(Json j) => CadastroDispositivo(
        dispositivo: Dispositivo.fromJson(
            (j['dispositivo'] as Map?)?.cast<String, dynamic>() ?? const {}),
        credencial: CredencialEmitida.fromJson(
            (j['credencial'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}

/// Dados do formulário de cadastro/edição. Referências por `slug`.
class DadosDispositivo {
  const DadosDispositivo({
    required this.codigo,
    required this.nome,
    required this.dominio,
    required this.perfil,
    required this.site,
    required this.area,
    required this.fabricante,
    required this.modelo,
    required this.firmware,
    required this.latitude,
    required this.longitude,
  });

  final String codigo;
  final String nome;
  final String dominio;
  final String perfil;
  final String site;

  /// `null` = sem área.
  final String? area;
  final String fabricante;
  final String? modelo;
  final String firmware;
  final double? latitude;
  final double? longitude;

  static bool _vazio(String? s) => s == null || s.trim().isEmpty;

  /// Corpo de `POST /dispositivos`: opcionais vazios ficam de fora.
  Json paraCriar() => {
        'codigo': codigo.trim(),
        ..._comuns(),
        if (!_vazio(area)) 'area': area,
      };

  /// Corpo de `PATCH /dispositivos/:ref`: sem `codigo` (imutável) e com
  /// `"area": null` quando a área foi removida.
  Json paraEditar() => {
        ..._comuns(),
        'area': _vazio(area) ? null : area,
      };

  Json _comuns() => {
        'nome': nome.trim(),
        'dominio': dominio,
        'perfil': perfil,
        'site': site,
        'fabricante': fabricante.trim(),
        if (!_vazio(modelo)) 'modelo': modelo!.trim(),
        'firmware': firmware.trim(),
        'latitude': ?latitude,
        'longitude': ?longitude,
      };
}
