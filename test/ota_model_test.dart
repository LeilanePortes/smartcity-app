import 'package:flutter_test/flutter_test.dart';
import 'package:smartcity_app/shared/models/models.dart';

import 'support/fake_smartcity_api.dart';

void main() {
  test('EstadoOta.fromJson lê uma implantação revertida completa', () {
    final e = EstadoOta.fromJson(jsonOtaRevertida());

    expect(e.modo, ModoArquitetura.camadas);
    expect(e.otaDisponivel, isTrue);
    expect(e.emAndamento, isFalse);
    expect(e.catalogo.map((v) => v.versao), ['2.4.1', '2.5.0', '3.0.0', '3.0.1']);
    expect(e.versoesEmCampo.map((v) => v.versao),
        ['2.4.1', '3.0.0', 'desconhecida']);
    expect(e.totalEmCampo, 248);
    expect(e.versaoPredominante, '2.4.1');
    expect(e.criterios.ondas, [5, 25, 50, 100]);
    expect(e.criterios.janelaS, 120);
    expect(e.criterios.limiarRazaoConsumo, 1.5);

    final imp = e.implantacao!;
    expect(imp.versao, '3.0.0');
    expect(imp.versaoAnterior, '2.4.1');
    expect(imp.status, StatusImplantacao.revertida);
    expect(imp.encerradaEm, DateTime.utc(2026, 10, 18, 18, 45, 26));
    expect(imp.proximaAvaliacaoEm, isNull);
    expect(imp.ondaAtual, 0);
    expect(imp.ondaAtualPct, 5);
    expect(imp.aparelhos.elegiveis, 241);
    expect(imp.aparelhos.revertidos, 13);
    expect(imp.canario, hasLength(3));
    expect(imp.controle.first, 'P-069');

    final m = imp.metricas!;
    expect(m.canario!.consumoNormalizadoMedio, 0.1814);
    expect(m.canario!.consumoAltoPct, 100);
    expect(m.controle!.consumoNormalizadoMedio, 0.0999);
    expect(m.razaoConsumo, 1.82);
    expect(m.referenciaConsumo, 0.0999);

    expect(imp.falhas.single.codigo, 'P-010');
    final d = imp.decisoes.single;
    expect(d.decisao, DecisaoPortao.reverter);
    expect(d.ondaPct, 5);
    expect(d.razaoConsumo, 1.82);
    expect(d.motivo, contains('limite 1,50×'));
  });

  test('implantacao null quando nenhuma foi iniciada', () {
    final e = EstadoOta.fromJson(jsonOtaSemImplantacao());

    expect(e.implantacao, isNull);
    expect(e.emAndamento, isFalse);
    expect(e.versoesEmCampo.first.postes, 246);
    expect(e.versoesEmCampo.last.desconhecida, isTrue);
  });

  test('metricas null antes do 1º portão (em andamento)', () {
    final e = EstadoOta.fromJson(jsonOtaEmAndamento('2.5.0'));
    final imp = e.implantacao!;

    expect(e.emAndamento, isTrue);
    expect(imp.status, StatusImplantacao.emAndamento);
    expect(imp.metricas, isNull);
    expect(imp.encerradaEm, isNull);
    expect(imp.proximaAvaliacaoEm, isNotNull);
    expect(imp.decisoes, isEmpty);
    expect(imp.falhas, isEmpty);
  });

  test('controle null na onda de 100% e razão null', () {
    final json = jsonOtaRevertida();
    final imp = json['implantacao'] as Map<String, dynamic>;
    imp['metricas'] = {
      'canario': {
        'aparelhos': 241,
        'reportaram': 200,
        'consumoNormalizadoMedio': 0.1001,
        'consumoAltoPct': 0,
      },
      'controle': null,
      'referenciaConsumo': null,
      'razaoConsumo': null,
    };
    final m = EstadoOta.fromJson(json).implantacao!.metricas!;

    expect(m.canario!.reportaram, 200);
    expect(m.controle, isNull);
    expect(m.razaoConsumo, isNull);
    expect(m.referenciaConsumo, isNull);
  });

  test('valores ausentes ou desconhecidos caem em padrões seguros', () {
    final e = EstadoOta.fromJson({
      'modo': 'interno',
      'implantacao': {
        'status': 'XYZ',
        'decisoes': [
          {'decisao': 'OUTRA', 'ondaPct': 25},
        ],
      },
    });

    expect(e.otaDisponivel, isFalse);
    expect(e.catalogo, isEmpty);
    expect(e.versoesEmCampo, isEmpty);
    expect(e.versaoPredominante, isNull);
    expect(e.criterios.ondas, [5, 25, 50, 100]);
    expect(e.criterios.limiarRazaoConsumo, 1.5);

    final imp = e.implantacao!;
    expect(imp.status, StatusImplantacao.desconhecido);
    expect(imp.ondas, [5, 25, 50, 100]);
    expect(imp.canario, isEmpty);
    expect(imp.metricas, isNull);
    expect(imp.decisoes.single.decisao, DecisaoPortao.desconhecida);
    expect(imp.decisoes.single.em, isNull);
    // Sem implantação em andamento reconhecida, as ações não ficam travadas.
    expect(e.emAndamento, isFalse);
  });
}
