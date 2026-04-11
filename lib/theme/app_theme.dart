// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF7F7F5);
  static const surface    = Color(0xFFFFFFFF);
  static const border     = Color(0xFFE8E8E4);
  static const borderMid  = Color(0xFFD0D0CB);

  // Text
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF888780);
  static const textTertiary  = Color(0xFFB4B2A9);

  // Semantic
  static const teal       = Color(0xFF1D9E75);
  static const tealLight  = Color(0xFFE1F5EE);
  static const tealDark   = Color(0xFF0F6E56);
  static const purple     = Color(0xFF534AB7);
  static const purpleLight= Color(0xFFEEEDFE);
  static const coral      = Color(0xFFD85A30);
  static const coralLight = Color(0xFFFAECE7);
  static const amber      = Color(0xFFEF9F27);
  static const amberLight = Color(0xFFFAEEDA);
  static const red        = Color(0xFFE24B4A);
  static const redLight   = Color(0xFFFCEBEB);
  static const blue       = Color(0xFF378ADD);
  static const blueLight  = Color(0xFFE6F1FB);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.black,
      brightness: Brightness.light,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge:  GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.textPrimary, letterSpacing: -0.5),
      headlineMedium:GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      titleLarge:    GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      titleMedium:   GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      bodyLarge:     GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium:    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      bodySmall:     GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textTertiary),
      labelSmall:    GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textTertiary, letterSpacing: 0.5),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.black, size: 22),
      titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.black, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border, width: 0.5),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      elevation: 0,
      selectedItemColor: AppColors.black,
      unselectedItemColor: AppColors.textTertiary,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 10),
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 0.5, space: 0),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bg,
      selectedColor: AppColors.black,
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
    scaffoldBackgroundColor: const Color(0xFF111110),
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.black, brightness: Brightness.dark),
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
