import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Shared Palette ───────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF3D8EFF);
  static const Color primaryDark  = Color(0xFF2563EB);
  static const Color secondary    = Color(0xFF06D6A0);
  static const Color error        = Color(0xFFEF4444);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color success      = Color(0xFF10B981);

  // ── Dark Palette ─────────────────────────────────────────────────────────
  static const Color bgDark        = Color(0xFF0A0E1A);
  static const Color bgSurface     = Color(0xFF111827);
  static const Color bgCard        = Color(0xFF1A2235);
  static const Color bgCardLight   = Color(0xFF1F2D40);
  static const Color glass         = Color(0x1AFFFFFF);
  static const Color glassBorder   = Color(0x33FFFFFF);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textHint      = Color(0xFF475569);

  // ── Light Palette ─────────────────────────────────────────────────────────
  static const Color bgLight         = Color(0xFFF0F4FF);
  static const Color bgSurfaceLight  = Color(0xFFFFFFFF);
  static const Color bgCardLt        = Color(0xFFFFFFFF);
  static const Color glassBorderLt   = Color(0xFFE2E8F0);
  static const Color textPrimaryLt   = Color(0xFF0F172A);
  static const Color textSecondaryLt = Color(0xFF64748B);
  static const Color textHintLt      = Color(0xFF94A3B8);

  // ── Reusable gradient ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient get bgGradientDark => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1321), Color(0xFF0A0E1A), Color(0xFF0D1B2E)],
    stops: [0, 0.5, 1],
  );

  static LinearGradient get bgGradientLight => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEFF6FF), Color(0xFFF0F4FF), Color(0xFFE8F5FF)],
    stops: [0, 0.5, 1],
  );

  // ── Text Themes ──────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) => TextTheme(
    displayLarge  : GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: primary),
    displayMedium : GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: primary),
    headlineLarge : GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: primary),
    headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
    headlineSmall : GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
    titleLarge    : GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
    titleMedium   : GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: primary),
    bodyLarge     : GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
    bodyMedium    : GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: secondary),
    bodySmall     : GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
    labelLarge    : GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
    labelSmall    : GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
  );

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color hint,
    required Color label,
  }) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        floatingLabelStyle: GoogleFonts.inter(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.error)),
        hintStyle: GoogleFonts.inter(color: hint, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: label, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      );

  // ── DARK THEME ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      error: error,
      surface: bgSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: bgDark,
    textTheme: _buildTextTheme(textPrimary, textSecondary),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary, minimumSize: const Size(double.infinity, 54),
        side: const BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: _inputTheme(fill: bgCard, border: glassBorder, hint: textHint, label: textSecondary),
    cardTheme: CardThemeData(
      color: bgCard, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: glassBorder, width: 1)),
      margin: EdgeInsets.zero,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: bgCard,
      contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(color: glassBorder, thickness: 1, space: 1),
  );

  // ── LIGHT THEME ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: secondary,
      error: error,
      surface: bgSurfaceLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryLt,
    ),
    scaffoldBackgroundColor: bgLight,
    textTheme: _buildTextTheme(textPrimaryLt, textSecondaryLt),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimaryLt),
      iconTheme: const IconThemeData(color: textPrimaryLt),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: _inputTheme(fill: bgCardLt, border: glassBorderLt, hint: textHintLt, label: textSecondaryLt),
    cardTheme: CardThemeData(
      color: bgCardLt, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: glassBorderLt, width: 1)),
      margin: EdgeInsets.zero,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: bgCardLt,
      contentTextStyle: GoogleFonts.inter(color: textPrimaryLt, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      actionTextColor: primary,
    ),
    dividerTheme: DividerThemeData(color: glassBorderLt, thickness: 1, space: 1),
  );
}
