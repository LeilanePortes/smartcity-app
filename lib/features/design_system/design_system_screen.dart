import 'package:flutter/material.dart';

import '../../core/theme/brut_colors.dart';
import '../../core/theme/brut_spacing.dart';
import '../../core/theme/brut_typography.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/widgets.dart';

/// Galeria viva do design system BRUT — serve para validar tokens e
/// componentes contra o design aprovado antes de montar as telas (fase 1).
class DesignSystemScreen extends StatefulWidget {
  const DesignSystemScreen({super.key});

  @override
  State<DesignSystemScreen> createState() => _DesignSystemScreenState();
}

class _DesignSystemScreenState extends State<DesignSystemScreen> {
  PeriodoTelemetria _periodoTele = PeriodoTelemetria.hoje;
  PeriodoKpi _periodoKpi = PeriodoKpi.mes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(BrutSpacing.lg),
      children: [
        const SectionLabel('Tipografia'),
        const SizedBox(height: BrutSpacing.md),
        Text('IBM Plex Sans', style: BrutType.sans(24, weight: FontWeight.w700)),
        Text('Texto de corpo — Prefeitura de Itaguari, GO.',
            style: BrutType.sans(14)),
        const SizedBox(height: BrutSpacing.xs),
        Text('IBM Plex Mono · 248 postes · R\$ 0,58/kWh',
            style: BrutType.mono(14)),
        const SizedBox(height: BrutSpacing.xl),

        const SectionLabel('Cores de status'),
        const SizedBox(height: BrutSpacing.md),
        Wrap(
          spacing: BrutSpacing.sm,
          runSpacing: BrutSpacing.sm,
          children: [
            for (final s in StatusPoste.values) _Swatch(s.label, s.color),
          ],
        ),
        const SizedBox(height: BrutSpacing.xl),

        const SectionLabel('Badges de status'),
        const SizedBox(height: BrutSpacing.md),
        Wrap(
          spacing: BrutSpacing.sm,
          runSpacing: BrutSpacing.sm,
          children: [for (final s in StatusPoste.values) StatusBadge(s)],
        ),
        const SizedBox(height: BrutSpacing.sm),
        Wrap(
          spacing: BrutSpacing.lg,
          runSpacing: BrutSpacing.sm,
          children: [
            for (final s in StatusPoste.values) StatusBadge(s, compact: true),
          ],
        ),
        const SizedBox(height: BrutSpacing.xl),

        const SectionLabel('Seletor de período'),
        const SizedBox(height: BrutSpacing.md),
        PeriodSelector<PeriodoTelemetria>(
          value: _periodoTele,
          options: PeriodoTelemetria.values,
          labelOf: (p) => p.label,
          onChanged: (p) => setState(() => _periodoTele = p),
        ),
        const SizedBox(height: BrutSpacing.sm),
        PeriodSelector<PeriodoKpi>(
          value: _periodoKpi,
          options: PeriodoKpi.values,
          labelOf: (p) => p.label,
          onChanged: (p) => setState(() => _periodoKpi = p),
        ),
        const SizedBox(height: BrutSpacing.xl),

        const SectionLabel('Botões'),
        const SizedBox(height: BrutSpacing.md),
        Wrap(
          spacing: BrutSpacing.sm,
          runSpacing: BrutSpacing.sm,
          children: [
            BrutButton(label: 'Ver no mapa', icon: Icons.map, onPressed: () {}),
            BrutButton(
              label: 'Agendar manutenção',
              variant: BrutButtonVariant.secondary,
              onPressed: () {},
            ),
            BrutButton(
              label: 'Abrir chamado',
              variant: BrutButtonVariant.danger,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: BrutSpacing.xl),

        const SectionLabel('Cards e indicadores'),
        const SizedBox(height: BrutSpacing.md),
        BrutCard(
          accent: BrutColors.statusAtencao,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('P-042', style: BrutType.mono(18, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Rua Itaguari, 136 · Centro', style: BrutType.sans(13)),
            ],
          ),
        ),
        const SizedBox(height: BrutSpacing.md),
        const Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Consumo total',
                value: '10.695,6',
                unit: 'kWh',
                deltaLabel: '−5,4%',
                deltaValue: -5.4,
              ),
            ),
            SizedBox(width: BrutSpacing.md),
            Expanded(
              child: StatCard(
                label: 'Custo total',
                value: 'R\$ 6.203',
                deltaLabel: '+3,1%',
                deltaValue: 3.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: BrutSpacing.xl),

        const SectionLabel('Estados'),
        const SizedBox(height: BrutSpacing.md),
        const SizedBox(height: 80, child: BrutLoading()),
        const SizedBox(height: BrutSpacing.md),
        const SizedBox(
          height: 120,
          child: BrutEmpty(message: 'Sem eventos no período.', icon: Icons.inbox),
        ),
        const SizedBox(height: BrutSpacing.xl),

        const SectionLabel('Tempo real'),
        const SizedBox(height: BrutSpacing.md),
        const Row(
          children: [
            LiveIndicator(),
            SizedBox(width: BrutSpacing.md),
            LiveIndicator(active: false),
          ],
        ),
        const SizedBox(height: BrutSpacing.xxl),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: BrutColors.line, width: BrutStroke.regular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 28, height: 28, color: color),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BrutSpacing.sm),
            child: Text(label, style: BrutType.mono(11)),
          ),
        ],
      ),
    );
  }
}
