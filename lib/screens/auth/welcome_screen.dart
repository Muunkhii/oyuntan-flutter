// lib/screens/auth/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  final bool isCompany;
  const WelcomeScreen({super.key, required this.isCompany});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // Back button
            Positioned(
              top: 4, left: 4,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                onPressed: () => context.go('/login'),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Success circle ──────────────────────────
                  Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.greenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, size: 52, color: AppColors.green),
                  )
                    .animate()
                    .scale(
                      begin: const Offset(0.0, 0.0),
                      duration: 650.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 300.ms),

                  const SizedBox(height: 28),

                  // ── Title ───────────────────────────────────
                  const Text(
                    'Бүртгэл амжилттай!',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                  )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.3, duration: 400.ms, delay: 300.ms, curve: Curves.easeOutCubic),

                  const SizedBox(height: 8),

                  Text(
                    isCompany
                      ? 'Тавтай морил! Компанийн бүртгэл амжилттай үүслээ.'
                      : 'Тавтай морил! Оюутны бүртгэл амжилттай үүслээ.',
                    style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 420.ms),

                  const Spacer(flex: 4),

                  // ── Continue button ─────────────────────────
                  PrimaryButton(
                    label: 'Эхлэх →',
                    onTap: () {
                      if (isCompany) {
                        context.go('/company/home');
                      } else {
                        context.go('/home');
                      }
                    },
                  ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.2, duration: 400.ms, delay: 650.ms),

                  const SizedBox(height: 12),

                  // ── Back to login link ──────────────────────
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Нэвтрэх хуудас руу буцах',
                      style: TextStyle(fontSize: 12, color: AppColors.muted, decoration: TextDecoration.underline),
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
