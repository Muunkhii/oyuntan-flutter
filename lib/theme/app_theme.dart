// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary     = Color(0xFF5B4FE8);
  static const primaryDark = Color(0xFF4338CA);
  static const primaryLight= Color(0xFFEEF2FF);
  static const primaryMid  = Color(0xFFC7D2FE);
  static const sidebar     = Color(0xFF3730A3);

  static const white  = Color(0xFFFFFFFF);
  static const bg     = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const text   = Color(0xFF1E293B);
  static const muted  = Color(0xFF64748B);
  static const faint  = Color(0xFF94A3B8);

  static const green      = Color(0xFF16A34A);
  static const greenLight = Color(0xFFDCFCE7);
  static const red        = Color(0xFFDC2626);
  static const redLight   = Color(0xFFFEE2E2);
  static const amber      = Color(0xFFD97706);
  static const amberLight = Color(0xFFFEF3C7);
  static const purple     = Color(0xFF7C3AED);
  static const purpleLight= Color(0xFFEDE9FE);
  static const teal       = Color(0xFF06B6D4);
  static const tealDark   = Color(0xFF0891B2);
  static const tealLight  = Color(0xFFCFFAFE);
  static const coral      = Color(0xFFEF4444);
  static const coralLight = Color(0xFFFEE2E2);
  static const blue       = Color(0xFF2563EB);
  static const blueLight  = Color(0xFFEFF6FF);
  static const black      = Color(0xFF0F172A);

  // Text aliases
  static const textPrimary   = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary  = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge:   GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.8),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text),
      titleLarge:     GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text),
      titleMedium:    GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
      bodyLarge:      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.text),
      bodyMedium:     GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.muted),
      bodySmall:      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.faint),
      labelSmall:     GoogleFonts.inter(fontSize: 9,  fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.6),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.text, size: 22),
      titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text),
      actionsIconTheme: const IconThemeData(color: AppColors.muted, size: 22),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: AppColors.white,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.faint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, foregroundColor: AppColors.white,
        elevation: 0, minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.muted,
        side: const BorderSide(color: AppColors.border, width: 0.5),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.white, elevation: 0,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.faint,
      selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
      type: BottomNavigationBarType.fixed,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bg,
      selectedColor: AppColors.primary,
      labelStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
      secondaryLabelStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 0.5, space: 0),
  );
}

// ── Shared Widgets ─────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child; final EdgeInsets? padding; final VoidCallback? onTap; final Color? color;
  const AppCard({super.key, required this.child, this.padding, this.onTap, this.color});
  @override
  Widget build(BuildContext c) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: child,
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label; final VoidCallback? onTap; final bool loading; final Color? bg;
  const PrimaryButton({super.key, required this.label, this.onTap, this.loading=false, this.bg});
  @override
  Widget build(BuildContext c) => SizedBox(
    width: double.infinity, height: 50,
    child: ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(backgroundColor: bg ?? AppColors.primary),
      child: loading
          ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(color:AppColors.white,strokeWidth:2))
          : Text(label),
    ),
  );
}

class SectionLabel extends StatelessWidget {
  final String text; final String? action; final VoidCallback? onAction;
  const SectionLabel(this.text, {super.key, this.action, this.onAction});
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Expanded(child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.6))),
      if (action != null) GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500))),
    ]),
  );
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 14),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted)),
  );
}

class LangToggle extends StatefulWidget {
  const LangToggle({super.key});
  @override State<LangToggle> createState() => _LangToggleState();
}
class _LangToggleState extends State<LangToggle> {
  bool _mn = true;
  @override
  Widget build(BuildContext c) => Row(mainAxisSize: MainAxisSize.min, children: [
    _Pill('МН', _mn, () => setState(() => _mn=true)),
    const SizedBox(width: 4),
    _Pill('EN', !_mn, () => setState(() => _mn=false)),
  ]);
}
class _Pill extends StatelessWidget {
  final String l; final bool on; final VoidCallback t;
  const _Pill(this.l, this.on, this.t);
  @override Widget build(BuildContext c) => GestureDetector(
    onTap: t,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: on ? AppColors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: on ? AppColors.primary : AppColors.border, width: on ? 1.5 : 0.5),
      ),
      child: Text(l, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: on ? AppColors.primary : AppColors.faint)),
    ),
  );
}

class AvatarCircle extends StatelessWidget {
  final String name; final double size; final int colorIndex;
  const AvatarCircle({super.key, required this.name, this.size=44, this.colorIndex=0});
  static const _bgs  = [Color(0xFFEFF6FF), Color(0xFFDCFCE7), Color(0xFFEDE9FE), Color(0xFFFEF3C7), Color(0xFFE0F7FA)];
  static const _fgs  = [Color(0xFF1D4ED8), Color(0xFF15803D), Color(0xFF6D28D9), Color(0xFFB45309), Color(0xFF0E7490)];
  @override
  Widget build(BuildContext c) {
    final i = colorIndex % 5;
    final init = name.isNotEmpty ? (name.length >= 2 ? name.substring(0,2).toUpperCase() : name.toUpperCase()) : '?';
    return CircleAvatar(radius: size/2, backgroundColor: _bgs[i],
      child: Text(init, style: TextStyle(fontSize: size*0.32, fontWeight: FontWeight.w700, color: _fgs[i])));
  }
}

class StatusBadge extends StatelessWidget {
  final String label; final Color bg; final Color textColor;
  const StatusBadge(this.label, {super.key, required this.bg, required this.textColor});
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
  );
}
