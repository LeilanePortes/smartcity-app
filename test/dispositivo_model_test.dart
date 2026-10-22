import 'package:flutter_test/flutter_test.dart';
import 'package:smartcity_app/shared/models/models.dart';

import 'support/fake_smartcity_api.dart';

DadosDispositivo _dados({String? area = 'avenida-goias', String modelo = 'MQ-3F'}) =>
    DadosDispositivo(
      codigo: ' medidor-centro ',
      nome: ' Medidor do quadro — Centro ',
      dominio: 'energia',
      perfil: 'luminaria-led',
      site: 'centro',
      area: area,
      fabricante: 'Medidores Genéricos Ltda.',
      modelo: modelo,
      firmware: '1.0.0',
      latitude: -15.920801,
      longitude: -49.606172,
    );

void main() {
  test('Dispositivo.fromJson lê o formato real (GeoJSON vira lat/lon)', () {
    final d = Dispositivo.fromJson(jsonDispositivo('p-001', credencialAtiva: true));

    expect(d.codigo, 'p-001');
    expect(d.nome, 'Luminária P-001');
    expect(d.inquilino.slug, 'itaguari');
    expect(d.dominio.nome, 'Iluminação pública');
    expect(d.perfil.slug, 'luminaria-led');
    expect(d.site.nome, 'Centro');
    expect(d.area!.slug, 'rua-10');
    expect(d.fabricante, 'Simulador SmartCity (edge)');
    expect(d.modelo, 'LUM-LED-100W');
    expect(d.firmware, '2.4.1');
    // GeoJSON é [lon, lat].
    expect(d.latitude, -15.920691);
    expect(d.longitude, -49.606176);
    expect(d.temGeo, isTrue);
    expect(d.posteId, 'poste-p-001');
    expect(d.conexao.online, isTrue);
    expect(d.conexao.limiteOfflineS, 180);
    expect(d.conexao.ultimaMensagemEm, DateTime.utc(2026, 10, 21, 19, 52, 11, 263));
    expect(d.credencial.ativa, isTrue);
    expect(d.credencial.prefixo, '1a2b3c4d5e6f');
    expect(d.criadoEm, isNotNull);
  });

  test('área, geo, modelo e posteId nulos; credencial inativa', () {
    final d = Dispositivo.fromJson({
      ...jsonDispositivo('medidor-centro', online: false),
      'area': null,
      'geo': null,
      'modelo': null,
      'posteId': null,
      'conexao': {'online': false, 'ultimaMensagemEm': null, 'limiteOfflineS': 900},
    });

    expect(d.area, isNull);
    expect(d.latitude, isNull);
    expect(d.temGeo, isFalse);
    expect(d.modelo, isNull);
    expect(d.posteId, isNull);
    expect(d.conexao.online, isFalse);
    expect(d.conexao.ultimaMensagemEm, isNull);
    expect(d.credencial.ativa, isFalse);
    expect(d.credencial.prefixo, isNull);
  });

  test('CadastroDispositivo lê { dispositivo, credencial } com o token', () {
    final c = CadastroDispositivo.fromJson({
      'dispositivo': jsonDispositivo('medidor-centro'),
      'credencial': jsonCredencial(),
    });

    expect(c.dispositivo.codigo, 'medidor-centro');
    expect(c.credencial.token, startsWith('dsp_b93557b21ba7_'));
    expect(c.credencial.prefixo, 'b93557b21ba7');
    expect(c.credencial.aviso, contains('não é mostrado de novo'));
    expect(c.credencial.anterioresRevogadas, isNull);
  });

  test('CredencialEmitida lê o corpo plano da emissão', () {
    final c = CredencialEmitida.fromJson({
      'dispositivo': jsonDispositivo('p-001'),
      ...jsonCredencial(),
      'anterioresRevogadas': 1,
    });
    expect(c.token, isNotEmpty);
    expect(c.anterioresRevogadas, 1);

    // Sem aviso na resposta: usa o padrão.
    final semAviso = CredencialEmitida.fromJson({'token': 'dsp_x', 'prefixo': 'x'});
    expect(semAviso.aviso, CredencialEmitida.avisoPadrao);
  });

  test('ItemCatalogo lê domínios, locais e áreas', () {
    final i = ItemCatalogo.fromJson({
      'id': '8550b724',
      'slug': 'centro',
      'nome': 'Centro',
      'tipo': 'bairro',
      'areas': 12,
      'dispositivos': 53,
    });
    expect(i.slug, 'centro');
    expect(i.tipo, 'bairro');
    expect(i.dispositivos, 53);
    expect(ItemCatalogo.fromJson(const {'slug': 'energia'}).nome, 'energia');
  });

  group('DadosDispositivo', () {
    test('paraCriar: com código, apara textos e inclui os opcionais', () {
      expect(_dados().paraCriar(), {
        'codigo': 'medidor-centro',
        'nome': 'Medidor do quadro — Centro',
        'dominio': 'energia',
        'perfil': 'luminaria-led',
        'site': 'centro',
        'fabricante': 'Medidores Genéricos Ltda.',
        'modelo': 'MQ-3F',
        'firmware': '1.0.0',
        'latitude': -15.920801,
        'longitude': -49.606172,
        'area': 'avenida-goias',
      });
    });

    test('paraCriar: opcionais vazios ficam de fora', () {
      final j = DadosDispositivo(
        codigo: 'x',
        nome: 'X',
        dominio: 'energia',
        perfil: 'p',
        site: 'centro',
        area: null,
        fabricante: 'F',
        modelo: '  ',
        firmware: '1.0.0',
        latitude: null,
        longitude: null,
      ).paraCriar();
      expect(j.containsKey('area'), isFalse);
      expect(j.containsKey('modelo'), isFalse);
      expect(j.containsKey('latitude'), isFalse);
      expect(j.containsKey('longitude'), isFalse);
    });

    test('paraEditar: sem código e com "area": null ao remover a área', () {
      final j = _dados(area: null).paraEditar();
      expect(j.containsKey('codigo'), isFalse);
      expect(j.containsKey('area'), isTrue);
      expect(j['area'], isNull);
      expect(_dados().paraEditar()['area'], 'avenida-goias');
    });
  });

  test('ordenar e conexão de dispositivos usam os valores aceitos pela API', () {
    expect(CampoOrdemDispositivos.values.map((c) => c.wire),
        ['codigo', 'nome', 'firmware', 'criadoEm', 'ultimaMensagemEm']);
    expect(FiltroConexao.values.map((c) => c.wire), ['online', 'offline']);
  });
}
