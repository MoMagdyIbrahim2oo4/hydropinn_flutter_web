import 'package:flutter/material.dart';

class HydroColors {
  final Color bg;
  final Color bg2;
  final Color panel;
  final Color panel2;
  final Color panel3;
  final Color stroke;
  final Color strokeStrong;
  final Color text;
  final Color text2;
  final Color muted;
  final Color faint;
  final Color accent;
  final Color accent2;
  final Color violet;
  final Color warn;
  final Color danger;
  final Color good;
  final bool isDark;

  const HydroColors({
    required this.bg,
    required this.bg2,
    required this.panel,
    required this.panel2,
    required this.panel3,
    required this.stroke,
    required this.strokeStrong,
    required this.text,
    required this.text2,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accent2,
    required this.violet,
    required this.warn,
    required this.danger,
    required this.good,
    required this.isDark,
  });

  static const dark = HydroColors(
    bg: Color(0xFF060A12),
    bg2: Color(0xFF0A1120),
    panel: Color(0xFF0C1425),
    panel2: Color(0xFF111C30),
    panel3: Color(0xFF15223B),
    stroke: Color(0x2294B1D6),
    strokeStrong: Color(0x4294B1D6),
    text: Color(0xFFE9EFFB),
    text2: Color(0xFFC4D3E8),
    muted: Color(0xFFA2B5CF),
    faint: Color(0xFF8EA3C4),
    accent: Color(0xFF22D3EE),
    accent2: Color(0xFF34D399),
    violet: Color(0xFFA78BFA),
    warn: Color(0xFFFBBF24),
    danger: Color(0xFFFB7185),
    good: Color(0xFF34D399),
    isDark: true,
  );

  static const light = HydroColors(
    bg: Color(0xFFEEF2F8),
    bg2: Color(0xFFE5ECF5),
    panel: Color(0xFFFFFFFF),
    panel2: Color(0xFFF3F7FD),
    panel3: Color(0xFFE8EFF9),
    stroke: Color(0x240F172A),
    strokeStrong: Color(0x420F172A),
    text: Color(0xFF0D1A2D),
    text2: Color(0xFF1E293B),
    muted: Color(0xFF334155),
    faint: Color(0xFF475569),
    accent: Color(0xFF0891B2),
    accent2: Color(0xFF059669),
    violet: Color(0xFF7C3AED),
    warn: Color(0xFFB45309),
    danger: Color(0xFFE11D48),
    good: Color(0xFF059669),
    isDark: false,
  );
}
