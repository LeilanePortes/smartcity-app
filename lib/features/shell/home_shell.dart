import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brut_colors.dart';
import '../../core/theme/brut_spacing.dart';
import '../../core/theme/brut_typography.dart';
import '../arquitetura/arquitetura_screen.dart';
import '../design_system/design_system_screen.dart';
import '../dispositivos/dispositivos_screen.dart';
import '../kpis/kpis_screen.dart';
import '../mapa/mapa_screen.dart';
import 'shell_providers.dart';

/// Casca de navegação entre as telas principais (`IndexedStack`). A galeria do
/// design system não ocupa aba: abre por um ícone no AppBar da Arquitetura.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _tabs = <_TabDef>[
    _TabDef(HomeTab.mapa, 'Mapa', Icons.map_outlined, MapaScreen()),
    _TabDef(HomeTab.kpis, 'KPIs', Icons.bar_chart_outlined, KpisScreen()),
    _TabDef(HomeTab.arquitetura, 'Arquitetura', Icons.hub_outlined,
        ArquiteturaScreen()),
    _TabDef(HomeTab.dispositivos, 'Dispositivos', Icons.developer_board,
        DispositivosScreen()),
  ];

  static void _abrirDesignSystem(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text('Design system',
              style: BrutType.sans(18, weight: FontWeight.w700)),
        ),
        body: const DesignSystemScreen(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);
    final index = _tabs.indexWhere((t) => t.tab == tab);

    return Scaffold(
      // A tela de Mapa traz o próprio cabeçalho (fidelidade ao design aprovado);
      // as demais abas usam a barra padrão do app.
      appBar: tab == HomeTab.mapa
          ? null
          : AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Iluminação Pública',
                      style: BrutType.sans(16, weight: FontWeight.w700)),
                  Text('ITAGUARI · GO', style: BrutType.label(10)),
                ],
              ),
              actions: [
                if (tab == HomeTab.arquitetura)
                  IconButton(
                    key: const Key('abrir-design-system'),
                    tooltip: 'Galeria do design system',
                    icon: const Icon(Icons.grid_view_outlined,
                        size: 20, color: BrutColors.inkMuted),
                    onPressed: () => _abrirDesignSystem(context),
                  ),
              ],
            ),
      body: IndexedStack(
        index: index,
        children: [for (final t in _tabs) t.screen],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: BrutColors.line, width: BrutStroke.regular),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          backgroundColor: BrutColors.surface,
          indicatorColor: BrutColors.ink,
          surfaceTintColor: Colors.transparent,
          onDestinationSelected: (i) =>
              ref.read(homeTabProvider.notifier).ir(_tabs[i].tab),
          destinations: [
            for (final t in _tabs)
              NavigationDestination(
                icon: Icon(t.icon, color: BrutColors.inkMuted),
                selectedIcon: Icon(t.icon, color: BrutColors.paper),
                label: t.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.tab, this.label, this.icon, this.screen);

  final HomeTab tab;
  final String label;
  final IconData icon;
  final Widget screen;
}
