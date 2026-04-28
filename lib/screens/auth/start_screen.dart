// lib/screens/auth/start_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/locale_provider.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ── Floating orbs ──────────────────────────────────
          Positioned(
            top: -80, right: -60,
            child: _Orb(220)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -40, duration: 4000.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            top: size.height * 0.3, left: -90,
            child: _Orb(160)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: 24, duration: 3500.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: 120, right: -40,
            child: _Orb(110)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -20, duration: 5000.ms, curve: Curves.easeInOut),
          ),

          // ── Content ────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  // Language toggle top-right
                  Align(
                    alignment: Alignment.topRight,
                    child: Consumer<LocaleProvider>(
                      builder: (_, locale, __) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () => locale.toggle(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.5),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.language_rounded, size: 13, color: Colors.white70),
                              const SizedBox(width: 5),
                              Text(locale.isMN ? 'МН' : 'EN',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Logo
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
                  )
                    .animate()
                    .scale(begin: const Offset(0.3, 0.3), duration: 700.ms, curve: Curves.elasticOut, delay: 100.ms)
                    .fadeIn(duration: 400.ms, delay: 100.ms),

                  const SizedBox(height: 20),

                  const Text(
                    'Оюунтан',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.2),
                  )
                    .animate()
                    .slideY(begin: 0.4, duration: 500.ms, curve: Curves.easeOutCubic, delay: 270.ms)
                    .fadeIn(duration: 400.ms, delay: 270.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Карьерын гарааны платформ',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.65)),
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

                  const Spacer(flex: 2),

                  // Choose label
                  Text(
                    'Та хэн бэ?',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                  ).animate().fadeIn(delay: 550.ms),

                  const SizedBox(height: 16),

                  // ── Two role cards ────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          icon: Icons.person_rounded,
                          title: 'Оюутан',
                          subtitle: 'Student',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          onTap: () => context.go('/login/student'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _RoleCard(
                          icon: Icons.business_rounded,
                          title: 'Компани',
                          subtitle: 'Company',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          onTap: () => context.go('/login/company'),
                        ),
                      ),
                    ],
                  )
                    .animate()
                    .fadeIn(delay: 620.ms)
                    .slideY(begin: 0.3, duration: 500.ms, delay: 620.ms, curve: Curves.easeOutCubic),

                  const Spacer(flex: 2),

                  Text(
                    '© 2025 Oyuntan. Бүх эрх хуулиар хамгаалагдсан.',
                    style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35)),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 900.ms),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating orb ──────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final double size;
  const _Orb(this.size);
  @override Widget build(BuildContext ctx) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
  );
}

// ── Role card ─────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Нэвтрэх', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
