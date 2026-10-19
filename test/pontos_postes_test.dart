import 'package:flutter_test/flutter_test.dart';
import 'package:smartcity_app/features/mapa/widgets/pontos_postes.dart';
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

void main() {
  group('diâmetro por zoom', () {
    test('âncoras e interpolação linear', () {
      expect(diametroBase(12), 6); // abaixo da 1ª âncora
      expect(diametroBase(14), 6);
      expect(diametroBase(15), 8);
      expect(diametroBase(15.2), closeTo(8.4, 1e-9)); // zoom inicial
      expect(diametroBase(16), 10);
      expect(diametroBase(16.5), closeTo(12, 1e-9));
      expect(diametroBase(17), 14);
      expect(diametroBase(18), 16);
      expect(diametroBase(18.5), 16); // acima da última âncora
    });

    test('fora do NORMAL fica 3 px maior', () {
      expect(diametroPonto(15, StatusPoste.normal), 8);
      for (final s in [
        StatusPoste.consumoAlto,
        StatusPoste.falhaOffline,
        StatusPoste.manutencao,
      ]) {
        expect(diametroPonto(15, s), 8 + kAcrescimoProblemaPx);
      }
    });
  });

  test('ordem de desenho: normais, manutenção, consumo alto, falha, selecionado',
      () {
    final pontos = ordenarParaDesenho(
      [
        (_poste('falha', StatusPoste.falhaOffline), Offset.zero),
        (_poste('n1'), Offset.zero),
        (_poste('alto', StatusPoste.consumoAlto), Offset.zero),
        (_poste('sel'), Offset.zero),
        (_poste('manut', StatusPoste.manutencao), Offset.zero),
        (_poste('n2'), Offset.zero),
      ],
      zoom: 15.2,
      selecionadoId: 'sel',
    );

    expect(pontos.map((p) => p.poste.id),
        ['n1', 'n2', 'manut', 'alto', 'falha', 'sel']);
    expect(pontos.last.selecionado, isTrue);
    expect(pontos.where((p) => p.selecionado), hasLength(1));
    expect(pontos.first.diametro, closeTo(8.4, 1e-9));
    expect(pontos[4].diametro, closeTo(11.4, 1e-9));
  });

  group('toque', () {
    List<PontoPoste> pontos(List<(PosteResumo, Offset)> itens) =>
        ordenarParaDesenho(itens, zoom: 15.2);

    test('escolhe o poste mais próximo do dedo', () {
      final p = pontos([
        (_poste('a'), const Offset(100, 100)),
        (_poste('b'), const Offset(110, 100)),
      ]);
      expect(posteNoToque(const Offset(108, 100), p)!.id, 'b');
      expect(posteNoToque(const Offset(101, 100), p)!.id, 'a');
    });

    test('prioriza o poste com problema por até 6 px', () {
      final p = pontos([
        (_poste('normal'), const Offset(100, 100)),
        (_poste('falha', StatusPoste.falhaOffline), const Offset(105, 100)),
      ]);
      // Normal a 0 px, falha a 5 px: 5 − 6 < 0 → falha.
      expect(posteNoToque(const Offset(100, 100), p)!.id, 'falha');

      final longe = pontos([
        (_poste('normal'), const Offset(100, 100)),
        (_poste('falha', StatusPoste.falhaOffline), const Offset(110, 100)),
      ]);
      // Normal a 0 px, falha a 10 px: 10 − 6 > 0 → normal.
      expect(posteNoToque(const Offset(100, 100), longe)!.id, 'normal');
    });

    test('fora do alcance (22 px) não pega nenhum poste', () {
      final p = pontos([(_poste('a'), const Offset(100, 100))]);
      expect(posteNoToque(const Offset(121, 100), p)!.id, 'a');
      expect(posteNoToque(const Offset(123, 100), p), isNull);
      expect(algumPosteAoAlcance(const Offset(121, 100), p), isTrue);
      expect(algumPosteAoAlcance(const Offset(200, 200), p), isFalse);
    });

    test('lista vazia não pega nada', () {
      expect(posteNoToque(Offset.zero, const []), isNull);
      expect(algumPosteAoAlcance(Offset.zero, const []), isFalse);
    });
  });
}
