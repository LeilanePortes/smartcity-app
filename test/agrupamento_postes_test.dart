import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcity_app/features/mapa/widgets/agrupamento_postes.dart';
import 'package:smartcity_app/shared/models/models.dart';

PosteResumo _poste(String id, [StatusPoste status = StatusPoste.normal]) =>
    PosteResumo(
      id: id,
      codigo: id,
      endereco: 'Rua X, 1',
      bairro: 'Centro',
      latitude: -15.92,
      longitude: -49.60,
      status: status,
      luminosidadeAtual: 50,
      consumoInstantaneoKw: 0.05,
      ultimaLeituraEm: null,
    );

(PosteResumo, Offset) _em(String id, double x, double y,
        [StatusPoste status = StatusPoste.normal]) =>
    (_poste(id, status), Offset(x, y));

/// Verdadeiro se algum par de itens ficou sobreposto (tamanho + folga).
bool _haSobreposicao(List<GrupoPostes> grupos) {
  for (var i = 0; i < grupos.length; i++) {
    for (var j = i + 1; j < grupos.length; j++) {
      final lim = (grupos[i].tamanho + grupos[j].tamanho) / 2 +
          kFolgaAgrupamentoPx;
      final d = grupos[i].centro - grupos[j].centro;
      if (d.dx.abs() < lim && d.dy.abs() < lim) return true;
    }
  }
  return false;
}

void main() {
  test('postes próximos viram bolha; distantes ficam individuais', () {
    final g = agruparPorDistancia([
      _em('a', 0, 0),
      _em('b', 10, 0),
      _em('c', 200, 0),
    ]);

    expect(g, hasLength(2));
    expect(g[0].postes.map((p) => p.id), ['a', 'b']);
    expect(g[0].individual, isFalse);
    expect(g[0].centro, const Offset(5, 0));
    expect(g[1].individual, isTrue);
    expect(g[1].postes.single.id, 'c');
  });

  test('marcador que encostaria numa bolha é fundido a ela', () {
    // 'c' está fora do raio (45 px > 44) do primeiro poste, mas o marcador
    // dele encostaria na bolha centrada em x = 20.
    final g = agruparPorDistancia([
      _em('a', 0, 0),
      _em('b', 40, 0),
      _em('c', 45, 0),
    ]);

    expect(g, hasLength(1));
    expect(g.single.postes, hasLength(3));
  });

  test('tamanho do item individual entra na regra de fusão', () {
    // Bolha centrada em x = 20; 'c' a 30 px dela (e a 50 px de 'a').
    final itens = [_em('a', 0, 0), _em('b', 40, 0), _em('c', 50, 0)];

    // Item de 26 px: limite (38 + 26) / 2 + 4 = 36 > 30 → funde.
    expect(agruparPorDistancia(itens), hasLength(1));
    // Ponto de 8 px: limite (38 + 8) / 2 + 4 = 27 < 30 → fica separado.
    expect(agruparPorDistancia(itens, tamanhoIndividual: 8), hasLength(2));
  });

  test('rede densa: nenhum item sobreposto e nenhum poste perdido', () {
    final rnd = Random(42);
    final itens = [
      for (var i = 0; i < 248; i++)
        _em('p$i', rnd.nextDouble() * 230, rnd.nextDouble() * 240),
    ];
    final g = agruparPorDistancia(itens);

    expect(_haSobreposicao(g), isFalse);
    expect(g.fold<int>(0, (s, x) => s + x.postes.length), 248);
    expect({for (final x in g) ...x.postes.map((p) => p.id)}, hasLength(248));
  });

  test('pior status e contagem de postes com problema', () {
    final g = agruparPorDistancia([
      _em('a', 0, 0),
      _em('b', 5, 0, StatusPoste.manutencao),
      _em('c', 10, 0, StatusPoste.falhaOffline),
      _em('d', 15, 0, StatusPoste.consumoAlto),
    ]).single;

    expect(g.piorStatus, StatusPoste.falhaOffline);
    expect(g.comProblema, 3);
  });

  test('gravidade: falha > consumo alto > manutenção > normal', () {
    expect(gravidadeStatus(StatusPoste.falhaOffline),
        greaterThan(gravidadeStatus(StatusPoste.consumoAlto)));
    expect(gravidadeStatus(StatusPoste.consumoAlto),
        greaterThan(gravidadeStatus(StatusPoste.manutencao)));
    expect(gravidadeStatus(StatusPoste.manutencao),
        greaterThan(gravidadeStatus(StatusPoste.normal)));
  });

  test('lista vazia não gera grupos', () {
    expect(agruparPorDistancia(const []), isEmpty);
  });
}
