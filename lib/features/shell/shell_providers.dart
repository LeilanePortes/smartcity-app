import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abas da casca de navegação.
/// A galeria do design system saiu da barra: abre pelo AppBar da Arquitetura.
enum HomeTab { mapa, kpis, arquitetura, dispositivos }

/// Aba ativa do [HomeShell]. Compartilhada para permitir que ações como
/// "Ver no mapa" (detalhe do poste) troquem de aba.
class HomeTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.mapa;

  void ir(HomeTab tab) => state = tab;
}

final homeTabProvider =
    NotifierProvider<HomeTabNotifier, HomeTab>(HomeTabNotifier.new);
