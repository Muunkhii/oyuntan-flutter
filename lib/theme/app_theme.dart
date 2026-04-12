// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF0F4FF);
  static const surface    = Color(0xFFFFFFFF);
  static const border     = Color(0xFFE2E8F0);
  static const borderMid  = Color(0xFFCBD5E1);

  // Text
  static const textPrimary   = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary  = Color(0xFF94A3B8);

  // Brand blue (primary)
  static const primary      = Color(0xFF2563EB);
  static const primaryDark  = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFFEFF6FF);
  static const primaryMid   = Color(0xFFBFDBFE);

  // Semantic
  static const teal       = Color(0xFF0D9488);
  static const tealLight  = Color(0xFFCCFBF1);
  static const tealDark   = Color(0xFF0F766E);
  static const purple     = Color(0xFF7C3AED);
  static const purpleLight= Color(0xFFEDE9FE);
  static const coral      = Color(0xFFEA580C);
  static const coralLight = Color(0xFFFEF3C7);
  static const amber      = Color(0xFFD97706);
  static const amberLight = Color(0xFFFEF9C3);
  static const red        = Color(0xFFDC2626);
  static const redLight   = Color(0xFFFEE2E2);
  static const blue       = Color(0xFF2563EB);
  static const blueLight  = Color(0xFFEFF6FF);

  // Status colors
  static const success    = Color(0xFF16A34A);
  static const successLight = Color(0xFFDCFCE7);
  static const warning    = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF9C3);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
      primary: AppColors.primary,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge:   GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5)
                        .copyWith(fontFamilyFallback: const ['NotoSans']),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)
                        .copyWith(fontFamilyFallback: const ['NotoSans']),
      titleLarge:     GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)
                        .copyWith(fontFamilyFallback: const ['NotoSans']),
      titleMedium:    GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)
                        .copyWith(fontFamilyFallback: const ['NotoSans']),
      bodyLarge:      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary)
                        .copyWith(fontFamilyFallback: const ['NotoSans']),
      bodyMedium:     GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary)
                        .copyWith(fontFamilyFallback: const ['NotoSans']),
      bodySmall:      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textTertiary)
                        .copyWith(fontFamilyFallback: const ['NotoSans']),
      labelSmall:     GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.5)
                        .copyWith(fontFamilyFallback: const ['NotoSans']),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
      titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      elevation: 0,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10),
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 0.8, space: 0),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryLight,
      selectedColor: AppColors.primary,
      labelStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
      secondaryLabelStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
  );

  static ThemeData get dark => light.copyWith(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark),
  );
}

// ── Reusable widget helpers ───────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: child,
    ),
  );
}

class AppTag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const AppTag(this.label, {super.key, this.bg = AppColors.purpleLight, this.textColor = AppColors.purple});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: textColor)),
  );
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary, letterSpacing: 0.6)),
  );
}
