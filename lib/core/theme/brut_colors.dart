import 'package:flutter/material.dart';

/// Paleta herdada do design system BRUT.
///
/// Brutalismo aplicado: alto contraste, sem gradientes, bordas duras.
/// As cores de status seguem o PRD §5.1 (verde = normal, laranja = atenção,
/// vermelho = falha/offline, cinza = manutenção).
abstract final class BrutColors {
  // Base
  static const Color paper = Color(0xFFF2F0E9); // fundo da aplicação
  static const Color surface = Color(0xFFFFFFFF); // cards e folhas
  static const Color ink = Color(0xFF141210); // texto primário e bordas
  static const Color inkMuted = Color(0xFF5C574F); // texto secundário
  static const Color inkFaint = Color(0xFF94918A); // rótulos mono, texto terciário
  static const Color line = Color(0xFF141210); // traço padrão (2px)
  static const Color lineSoft = Color(0xFFE0DDD4); // hairline tênue (cards)
  static const Color lineMedium = Color(0xFFC7C3B6); // hairline de controles/chips
  static const Color accent = Color(0xFF2F27CE); // foco de input (legado)
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Vermelho de destaque do design aprovado (`#FF3520`). É o accent visual da
  /// UI: CTA principal, indicadores ao vivo, alertas e realce de variação
  /// desfavorável. Usar este token — não o `accent` (azul, só foco de input)
  /// nem o `statusFalha` (vermelho de status/erro). Ver `design-canvas-claude`.
  static const Color destaque = Color(0xFFFF3520);
  static const Color onDestaque = Color(0xFFFFFFFF);

  // Status do poste
  static const Color statusNormal = Color(0xFF1B7F3B);
  static const Color statusAtencao = Color(0xFFC15600);
  static const Color statusFalha = Color(0xFFC01C1C);
  static const Color statusManutencao = Color(0xFF6B6B6B);

  // Superfícies tênues por status (fundo de badges/realces)
  static const Color statusNormalSoft = Color(0xFFE0F0E4);
  static const Color statusAtencaoSoft = Color(0xFFF7E6D5);
  static const Color statusFalhaSoft = Color(0xFFF7DADA);
  static const Color statusManutencaoSoft = Color(0xFFE7E7E7);

  // Escala de luminosidade (heatmap 50% → 100%, PRD §5.1)
  static const Color lumBaixa = Color(0xFF15324A); // ~50% (piso)
  static const Color lumMedia = Color(0xFFE0A93B);
  static const Color lumAlta = Color(0xFFF5E663); // ~100% (pico)
}
