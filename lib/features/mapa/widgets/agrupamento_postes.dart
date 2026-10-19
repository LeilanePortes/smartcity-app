import 'dart:ui' show Offset;

import '../../../shared/models/models.dart';

/// Raio, em pixels de tela, dentro do qual os postes entram no mesmo grupo.
const double kRaioAgrupamentoPx = 44;

/// Diâmetro visual da bolha e tamanho padrão de um poste individual (sem a
/// área de toque). A camada passa o diâmetro real do ponto no zoom atual.
const double kTamanhoBolhaPx = 38;
const double kTamanhoMarcadorPx = 26;

/// Folga mínima entre dois itens depois da fusão.
const double kFolgaAgrupamentoPx = 4;

/// Gravidade do status para escolher o "pior" de um grupo:
/// falha > consumo alto > manutenção > normal.
int gravidadeStatus(StatusPoste s) => switch (s) {
      StatusPoste.falhaOffline => 3,
      StatusPoste.consumoAlto => 2,
      StatusPoste.manutencao => 1,
      StatusPoste.normal => 0,
    };

/// Um item da camada de marcadores: um poste individual ou uma bolha.
class GrupoPostes {
  GrupoPostes._(this.postes, this.centro, double tamanhoIndividual)
      : _tamanhoIndividual = tamanhoIndividual;

  final List<PosteResumo> postes;

  /// Centro na tela (média das posições dos postes do grupo).
  final Offset centro;

  bool get individual => postes.length == 1;

  /// Status mais grave do grupo.
  StatusPoste get piorStatus => postes
      .map((p) => p.status)
      .reduce((a, b) => gravidadeStatus(b) > gravidadeStatus(a) ? b : a);

  /// Quantos postes do grupo não estão `NORMAL`.
  int get comProblema =>
      postes.where((p) => p.status != StatusPoste.normal).length;

  final double _tamanhoIndividual;

  double get tamanho => individual ? _tamanhoIndividual : kTamanhoBolhaPx;
}

/// Agrupa postes por distância na tela, sem depender do zoom:
///
/// 1. Guloso, na ordem da lista: cada poste ainda livre puxa os livres a até
///    [raio] px dele (mesma regra da camada anterior).
/// 2. Fusão: enquanto dois itens (bolha ou marcador) se sobrepõem — contando o
///    tamanho de cada um e [kFolgaAgrupamentoPx] —, viram um só.
///
/// O resultado não tem itens sobrepostos. [tamanhoIndividual] é o lado/diâmetro
/// de um poste sozinho na tela (o ponto no zoom atual).
List<GrupoPostes> agruparPorDistancia(
  List<(PosteResumo, Offset)> itens, {
  double raio = kRaioAgrupamentoPx,
  double tamanhoIndividual = kTamanhoMarcadorPx,
}) {
  // 1. Guloso.
  final grupos = <_Acumulador>[];
  final usado = List<bool>.filled(itens.length, false);
  for (var i = 0; i < itens.length; i++) {
    if (usado[i]) continue;
    usado[i] = true;
    final g = _Acumulador(tamanhoIndividual)..add(itens[i]);
    for (var j = i + 1; j < itens.length; j++) {
      if (usado[j]) continue;
      if ((itens[j].$2 - itens[i].$2).distance <= raio) {
        usado[j] = true;
        g.add(itens[j]);
      }
    }
    grupos.add(g);
  }

  // 2. Fusão até não sobrar sobreposição.
  var i = 0;
  while (i < grupos.length) {
    var fundiu = false;
    for (var j = 0; j < grupos.length; j++) {
      if (j == i) continue;
      if (_sobrepoe(grupos[i], grupos[j])) {
        grupos[i].absorver(grupos[j]);
        grupos.removeAt(j);
        if (j < i) i--;
        fundiu = true;
        break;
      }
    }
    // Depois de uma fusão o centro mudou: confere o mesmo grupo de novo.
    if (!fundiu) i++;
  }

  return [
    for (final g in grupos)
      GrupoPostes._(g.postes, g.centro, tamanhoIndividual),
  ];
}

bool _sobrepoe(_Acumulador a, _Acumulador b) {
  final limite = (a.tamanho + b.tamanho) / 2 + kFolgaAgrupamentoPx;
  final d = a.centro - b.centro;
  return d.dx.abs() < limite && d.dy.abs() < limite;
}

class _Acumulador {
  _Acumulador(this._tamanhoIndividual);

  final double _tamanhoIndividual;
  final postes = <PosteResumo>[];
  var _soma = Offset.zero;

  void add((PosteResumo, Offset) item) {
    postes.add(item.$1);
    _soma += item.$2;
  }

  void absorver(_Acumulador outro) {
    postes.addAll(outro.postes);
    _soma += outro._soma;
  }

  Offset get centro => _soma / postes.length.toDouble();

  double get tamanho =>
      postes.length == 1 ? _tamanhoIndividual : kTamanhoBolhaPx;
}
