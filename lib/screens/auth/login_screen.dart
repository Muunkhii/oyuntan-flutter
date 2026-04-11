// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isStudent  = true;
  bool _obscure    = true;
  String _lang     = 'mn';

  final _t = {
    'mn': {
      'title': 'Оюунтан', 'sub': 'Карьерын гарааны платформ',
      'student': 'Оюутан', 'company': 'Компани',
      'email': 'Имэйл', 'password': 'Нууц үг',
      'login': 'Нэвтрэх', 'register': 'Бүртгүүлэх',
      'forgot': 'Нууц үг мартсан?',
      'help': 'Нэвтрэлтийн тусламж',
    },
    'en': {
      'title': 'Oyuntan', 'sub': 'Career launchpad platform',
      'student': 'Student', 'company': 'Company',
      'email': 'Email', 'password': 'Password',
      'login': 'Login', 'register': 'Register',
      'forgot': 'Forgot password?',
      'help': 'Need help signing in?',
    },
  };

  Map<String,String> get t => (_t[_lang] ?? _t['mn']!).cast<String, String>();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lang toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LangPill('МН', _lang == 'mn', () => setState(() => _lang = 'mn')),
                  const SizedBox(width: 6),
                  _LangPill('EN', _lang == 'en', () => setState(() => _lang = 'en')),
                ],
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 40),

              // Logo
              Text(t['title']!, style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary, letterSpacing: -1,
              )).animate().fadeIn().slideY(begin: 0.2),
              const SizedBox(height: 4),
              Text(t['sub']!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))
                  .animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 36),

              // Segment control
              _SegmentControl(
                left: t['student']!, right: t['company']!,
                isLeft: _isStudent,
                onLeft:  () => setState(() => _isStudent = true),
                onRight: () => setState(() => _isStudent = false),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // Error
              if (auth.error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(auth.error!, style: const TextStyle(fontSize: 12, color: AppColors.red)),
                ),
                const SizedBox(height: 14),
              ],

              // Email
              _FieldLabel(t['email']!),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(hintText: 'name@example.com'),
              ),
              const SizedBox(height: 14),

              // Password
              _FieldLabel(t['password']!),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18, color: AppColors.textTertiary),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login button
              ElevatedButton(
                onPressed: auth.loading ? null : _login,
                child: auth.loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : Text(t['login']!),
              ),
              const SizedBox(height: 10),

              // Register button
              OutlinedButton(
                onPressed: () => context.push(
                  _isStudent ? '/register/student' : '/register/company'),
                child: Text(t['register']!),
              ),
              const SizedBox(height: 12),

              // Forgot password
              Center(
                child: GestureDetector(
                  onTap: () => _showForgotPassword(context),
                  child: Text(t['forgot']!,
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    )),
                ),
              ),
              const SizedBox(height: 20),

              // Help
              Center(
                child: GestureDetector(
                  onTap: () => _showHelp(context),
                  child: Text(t['help']!,
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary,
                      decoration: TextDecoration.underline,
                    )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) {
      context.go(auth.isCompany ? '/company' : '/home');
    }
  }

  void _showForgotPassword(BuildContext ctx) {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24,
            MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Нууц үг сэргээх', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Имэйл хаягт нууц үг сэргээх холбоос илгээнэ.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'name@example.com'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.trim().isEmpty) return;
              final auth = context.read<AuthProvider>();
              final ok = await auth.sendPasswordReset(emailCtrl.text.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(ok
                  ? '${emailCtrl.text.trim()} руу холбоос илгээгдлээ'
                  : auth.error ?? 'Алдаа гарлаа'),
                backgroundColor: ok ? AppColors.teal : AppColors.red,
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('Холбоос илгээх'),
          ),
        ]),
      ),
    );
  }

  void _showHelp(BuildContext ctx) => showModalBottomSheet(
    context: ctx,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const Padding(
      padding: EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Тусламж', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        SizedBox(height: 12),
        Text('Нэвтрэхэд асуудал гарвал support@oyuntan.mn руу холбогдоно уу.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        SizedBox(height: 20),
      ]),
    ),
  );

  @override
  void dispose() {
    _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose();
  }
}

class _LangPill extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _LangPill(this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: 150.ms,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppColors.black : AppColors.border, width: 0.5),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: active ? AppColors.white : AppColors.textSecondary,
      )),
    ),
  );
}

class _SegmentControl extends StatelessWidget {
  final String left, right; final bool isLeft;
  final VoidCallback onLeft, onRight;
  const _SegmentControl({required this.left, required this.right, required this.isLeft, required this.onLeft, required this.onRight});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(11)),
    child: Row(children: [
      Expanded(child: _Seg(left,  isLeft,  onLeft)),
      Expanded(child: _Seg(right, !isLeft, onRight)),
    ]),
  );
}

class _Seg extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _Seg(this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: 150.ms,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        border: active ? Border.all(color: AppColors.border, width: 0.5) : null,
      ),
      child: Text(label, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13,
          fontWeight: active ? FontWeight.w500 : FontWeight.w400,
          color: active ? AppColors.textPrimary : AppColors.textSecondary)),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  );
}
