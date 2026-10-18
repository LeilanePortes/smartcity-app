import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartcity_app/core/utils/formatters.dart';
import 'package:smartcity_app/shared/models/models.dart';

import 'support/fake_smartcity_api.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('EstadoArquitetura.fromJson lê o modo camadas completo', () {
    final e = EstadoArquitetura.fromJson(jsonArquiteturaCamadas());

    expect(e.modo, ModoArquitetura.camadas);
    expect(e.modoInterno, isFalse);
    expect(e.brokerConectado, isTrue);
    expect(e.edge!.online, isTrue);
    expect(e.geradoEm, DateTime.utc(2026, 10, 18, 18, 11, 46, 729));

    final fog = e.fog!;
    expect(fog.online, isTrue);
    expect(fog.buffer, 0);
    expect(fog.gateways, hasLength(2));
    expect(fog.gateways[1].bairro, 'Setor Oeste');
    expect(fog.gateways[1].offline, 1);
    expect(fog.totalPostes, 67);
    expect(fog.totalOnline, 66);
    expect(fog.atualizadoEm, DateTime.utc(2026, 10, 18, 18, 11, 6, 722));

    final t = e.trafego!;
    expect(t.janelaS, 60);
    expect(t.entrada.msgs, 1586);
    expect(t.entrada.bytes, 237231);
    expect(t.saida.msgs, 137);
    expect(t.saida.bytes, 98834);
    expect(t.reducaoMsgsPct, 91);
    expect(t.reducaoBytesPct, 58);
    expect(t.postesTotal, 248);
    expect(t.postesOnline, 243);
    expect(t.em, isNotNull);

    final a = e.alertas.single;
    expect(a.posteId, 'a2');
    expect(a.codigo, 'P-002');
    expect(a.statusAnterior, StatusPoste.normal);
    expect(a.status, StatusPoste.consumoAlto);
    expect(a.motivo, contains('mediana'));
    expect(a.temPoste, isTrue);
  });

  test('modo interno: edge, fog e tráfego nulos e alertas vazios', () {
    final e = EstadoArquitetura.fromJson(jsonArquiteturaInterno());

    expect(e.modo, ModoArquitetura.interno);
    expect(e.modoInterno, isTrue);
    expect(e.brokerConectado, isFalse);
    expect(e.edge, isNull);
    expect(e.fog, isNull);
    expect(e.trafego, isNull);
    expect(e.alertas, isEmpty);
  });

  test('campos que podem ser null não quebram o parsing', () {
    final e = EstadoArquitetura.fromJson({
      'modo': 'camadas',
      // `nuvem` ausente → broker tratado como desconectado.
      'edge': {'online': null},
      'fog': {
        'online': true,
        'gateways': [
          {'bairro': 'Centro', 'postes': 46, 'online': 40},
        ],
        'buffer': 12,
        'atualizadoEm': null,
      },
      'trafego': {
        'janelaS': 60,
        'entrada': {'msgs': 0, 'bytes': 0},
        'saida': {'msgs': 0, 'bytes': 0},
        'reducaoMsgsPct': null,
        'reducaoBytesPct': null,
        'postes': {'total': 248, 'online': 0},
        'em': '2026-10-18T18:11:06.722Z',
      },
      // `alertas` ausente → lista vazia.
      'geradoEm': '2026-10-18T18:11:46.729Z',
    });

    expect(e.brokerConectado, isFalse);
    expect(e.edge, isNotNull);
    expect(e.edge!.online, isNull);
    expect(e.fog!.buffer, 12);
    expect(e.fog!.atualizadoEm, isNull);
    expect(e.trafego!.reducaoMsgsPct, isNull);
    expect(e.trafego!.reducaoBytesPct, isNull);
    expect(e.alertas, isEmpty);
  });

  test('fog presente sem tráfego (antes da primeira janela)', () {
    final json = jsonArquiteturaCamadas()
      ..['trafego'] = null
      ..['edge'] = null;
    final e = EstadoArquitetura.fromJson(json);

    expect(e.modoInterno, isFalse);
    expect(e.edge, isNull);
    expect(e.fog, isNotNull);
    expect(e.trafego, isNull);
  });

  test('valores desconhecidos caem em padrões seguros', () {
    final e = EstadoArquitetura.fromJson({
      'modo': 'outro',
      'nuvem': {'brokerConectado': true},
      'alertas': [
        {'codigo': 'P-001', 'status': 'XYZ', 'statusAnterior': 'NORMAL'},
      ],
      'geradoEm': '2026-10-18T18:11:46.729Z',
    });

    expect(e.modo, ModoArquitetura.camadas);
    final a = e.alertas.single;
    expect(a.status, StatusPoste.normal);
    expect(a.temPoste, isFalse);
    expect(a.em, isNull);
  });

  test('Fmt.kb converte bytes em KB com 1 casa', () {
    expect(Fmt.kb(98834), '96,5 KB');
    expect(Fmt.kb(237231), '231,7 KB');
    expect(Fmt.kb(0), '0,0 KB');
  });
}
