import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const Gradient neonGlow = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFF22D3EE)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const Gradient darkBackground = LinearGradient(
    colors: [Color(0xFF07070F), Color(0xFF0D0D1F), Color(0xFF07070F)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );

  // Dark theme
  static const Color darkBackground1 = Color(0xFF07070F);
  static const Color darkSurface = Color(0xFF0F0F1E);
  static const Color darkSurfaceVariant = Color(0xFF171730);
  static const Color darkSurfaceContainer = Color(0xFF1C1C35);
  static const Color darkBorder = Color(0xFF2D2D52);
  static const Color darkBorderFaint = Color(0xFF1E1E3A);

  static const Color darkPrimary = Color(0xFF8B5CF6);
  static const Color darkPrimaryLight = Color(0xFFA78BFA);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);

  static const Color darkSecondary = Color(0xFF22D3EE);
  static const Color darkOnSecondary = Color(0xFF001F24);

  static const Color darkTertiary = Color(0xFFF472B6);
  static const Color darkOnTertiary = Color(0xFF2D0028);

  static const Color darkAccentGreen = Color(0xFF34D399);
  static const Color darkAccentOrange = Color(0xFFFB923C);
  static const Color darkAccentYellow = Color(0xFFFBBF24);

  static const Color darkOnBackground = Color(0xFFEEF2FF);
  static const Color darkOnSurface = Color(0xFFE0E7FF);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkTextDisabled = Color(0xFF475569);

  static const Color darkError = Color(0xFFF87171);
  static const Color darkOnError = Color(0xFF2D0A0A);
  static const Color darkErrorContainer = Color(0xFF4C1414);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkInfo = Color(0xFF60A5FA);

  // Glass
  static const Color glassLight = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);

  // Glow
  static const Color glowPrimary = Color(0x338B5CF6);
  static const Color glowSecondary = Color(0x2222D3EE);

  // Light theme
  static const Color lightBackground = Color(0xFFF8FAFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightSurfaceContainer = Color(0xFFEEF2FF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderFaint = Color(0xFFF1F5F9);

  static const Color lightPrimary = Color(0xFF7C3AED);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFF0891B2);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightTertiary = Color(0xFFDB2777);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);

  static const Color lightOnBackground = Color(0xFF0F172A);
  static const Color lightOnSurface = Color(0xFF1E293B);
  static const Color lightOnSurfaceVariant = Color(0xFF475569);

  static const Color lightError = Color(0xFFEF4444);
  static const Color lightWarning = Color(0xFFD97706);
  static const Color lightSuccess = Color(0xFF059669);

  // Provider brand colors
  static const Color openAIColor = Color(0xFF10A37F);
  static const Color anthropicColor = Color(0xFFD97706);
  static const Color googleColor = Color(0xFF4285F4);
  static const Color xAIColor = Color(0xFF9CA3AF);
  static const Color deepSeekColor = Color(0xFF1B6CF2);
  static const Color mistralColor = Color(0xFFFF7000);
  static const Color openRouterColor = Color(0xFF6366F1);
  static const Color huggingFaceColor = Color(0xFFFFD21E);
  static const Color llamaColor = Color(0xFF0467DF);
  static const Color qwenColor = Color(0xFF6E3CF5);
  static const Color ollamaColor = Color(0xFF4B5563);
  static const Color stabilityColor = Color(0xFFA855F7);
  static const Color replicateColor = Color(0xFF374151);
  static const Color runwayColor = Color(0xFF23F08A);
  static const Color pikaColor = Color(0xFFFF6B6B);
  static const Color lumaColor = Color(0xFF4FC3F7);
  static const Color sunoColor = Color(0xFFFFC933);
  static const Color udioColor = Color(0xFFFF4FF8);
  static const Color elevenLabsColor = Color(0xFF22D3EE);
}
