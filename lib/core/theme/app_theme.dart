import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground1,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        primaryContainer: Color(0xFF3D0E7A),
        onPrimaryContainer: Color(0xFFE9DDFF),
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnSecondary,
        secondaryContainer: Color(0xFF004E59),
        onSecondaryContainer: Color(0xFFB3ECFF),
        tertiary: AppColors.darkTertiary,
        onTertiary: AppColors.darkOnTertiary,
        tertiaryContainer: Color(0xFF660025),
        onTertiaryContainer: Color(0xFFFFD9E3),
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
        errorContainer: AppColors.darkErrorContainer,
        onErrorContainer: Color(0xFFFFB3AE),
        background: AppColors.darkBackground1,
        onBackground: AppColors.darkOnBackground,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        surfaceVariant: AppColors.darkSurfaceVariant,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorderFaint,
        shadow: Colors.black,
        scrim: Colors.black54,
        inverseSurface: AppColors.lightSurface,
        onInverseSurface: AppColors.lightOnSurface,
        inversePrimary: AppColors.lightPrimary,
        surfaceTint: AppColors.darkPrimary,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: AppColors.darkOnBackground, letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkOnBackground),
      ),
      cardTheme: CardTheme(
        color: AppColors.darkSurfaceVariant, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorderFaint, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorderFaint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkError, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.darkOnSurfaceVariant, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.darkOnSurfaceVariant, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const MaterialStatePropertyAll(AppColors.darkPrimary),
          foregroundColor: const MaterialStatePropertyAll(AppColors.darkOnPrimary),
          elevation: const MaterialStatePropertyAll(0),
          padding: const MaterialStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: MaterialStatePropertyAll(
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const MaterialStatePropertyAll(AppColors.darkPrimary),
          foregroundColor: const MaterialStatePropertyAll(AppColors.darkOnPrimary),
          elevation: const MaterialStatePropertyAll(0),
          padding: const MaterialStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: MaterialStatePropertyAll(
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const MaterialStatePropertyAll(AppColors.darkPrimary),
          side: const MaterialStatePropertyAll(BorderSide(color: AppColors.darkBorder)),
          padding: const MaterialStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const MaterialStatePropertyAll(AppColors.darkPrimary),
          padding: const MaterialStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.darkPrimary.withOpacity(0.2),
        side: const BorderSide(color: AppColors.darkBorder),
        labelStyle: GoogleFonts.inter(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
          color: AppColors.darkBorderFaint, thickness: 1, space: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        showDragHandle: true,
        dragHandleColor: AppColors.darkBorder,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkSurfaceVariant,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceContainer,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.darkOnSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.darkPrimary.withOpacity(0.08),
        iconColor: AppColors.darkOnSurfaceVariant,
        textColor: AppColors.darkOnSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return AppColors.darkOnPrimary;
          return AppColors.darkOnSurfaceVariant;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return AppColors.darkPrimary;
          return AppColors.darkSurfaceContainer;
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.darkPrimary,
        thumbColor: AppColors.darkPrimary,
        overlayColor: AppColors.glowPrimary,
        inactiveTrackColor: AppColors.darkBorder,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        primaryContainer: Color(0xFFE9DDFF),
        onPrimaryContainer: Color(0xFF21005D),
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightOnSecondary,
        secondaryContainer: Color(0xFFB3ECFF),
        onSecondaryContainer: Color(0xFF001F24),
        tertiary: AppColors.lightTertiary,
        onTertiary: AppColors.lightOnTertiary,
        tertiaryContainer: Color(0xFFFFD9E3),
        onTertiaryContainer: Color(0xFF3E001E),
        error: AppColors.lightError,
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD5),
        onErrorContainer: Color(0xFF410002),
        background: AppColors.lightBackground,
        onBackground: AppColors.lightOnBackground,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        surfaceVariant: AppColors.lightSurfaceVariant,
        onSurfaceVariant: AppColors.lightOnSurfaceVariant,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightBorderFaint,
        shadow: Colors.black26,
        scrim: Colors.black54,
        inverseSurface: AppColors.darkSurface,
        onInverseSurface: AppColors.darkOnSurface,
        inversePrimary: AppColors.darkPrimary,
        surfaceTint: AppColors.lightPrimary,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
            color: AppColors.lightOnSurfaceVariant, fontSize: 14),
      ),
      cardTheme: CardTheme(
        color: AppColors.lightSurface, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground;
    final secondary = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    return TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -1.5, color: primary),
      displayMedium: GoogleFonts.spaceGrotesk(fontSize: 45, fontWeight: FontWeight.w600, letterSpacing: -1.0, color: primary),
      displaySmall: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: primary),
      headlineLarge: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w600, color: primary),
      headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w600, color: primary),
      headlineSmall: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w600, color: primary),
      titleLarge: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: primary, height: 1.6),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: primary, height: 1.6),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: secondary),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: primary),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }
}
