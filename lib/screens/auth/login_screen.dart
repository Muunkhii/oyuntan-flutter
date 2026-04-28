// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

// ─────────────────────────────────────────────────────────────
//  LoginScreen  –  isCompany: false → student, true → company
// ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  final bool isCompany;
  const LoginScreen({super.key, required this.isCompany});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _email  = TextEditingController();
  final _pw     = TextEditingController();
  bool _obscure = true;
  late AnimationController _ctrl;

  // ── Localized strings (driven by LocaleProvider) ─────────────
  bool get _mn => context.read<LocaleProvider>().isMN;
  String get _t_title    => _mn ? (widget.isCompany ? 'Компани нэвтрэх' : 'Оюутан нэвтрэх') : (widget.isCompany ? 'Company Login' : 'Student Login');
  String get _t_email    => _mn ? 'Имэйл'        : 'Email';
  String get _t_pw       => _mn ? 'Нууц үг'      : 'Password';
  String get _t_login    => _mn ? 'Нэвтрэх'      : 'Sign in';
  String get _t_register => _mn ? 'Бүртгүүлэх'   : 'Register';
  String get _t_forgot   => _mn ? 'Нууц үг мартсан уу?' : 'Forgot password?';
  String get _t_help     => _mn ? 'Тусламж авах'  : 'Get help';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _ctrl.forward();
  }

  // ── Gradient colors per role ────────────────────────────────
  List<Color> get _gradColors => widget.isCompany
    ? const [Color(0xFF0F172A), Color(0xFF3B0764), Color(0xFF7C3AED)]
    : const [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)];

  Color get _accentColor => widget.isCompany ? AppColors.purple : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Gradient background ────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _gradColors,
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ── Floating orbs ──────────────────────────────────
          Positioned(top: -80, right: -60,
            child: _Orb(220, 0.09)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -40, duration: 4000.ms, curve: Curves.easeInOut)),
          Positioned(top: size.height * 0.18, left: -80,
            child: _Orb(160, 0.07)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: 22, duration: 3500.ms, curve: Curves.easeInOut)),

          // ── Page content ───────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top bar: back + lang toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      // Back button → start screen
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => context.go('/start'),
                      ),
                      const Spacer(),
                      // Language toggle
                      _LangToggle(
                        mn: context.watch<LocaleProvider>().isMN,
                        onToggle: (v) => context.read<LocaleProvider>().set(v),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                // Logo + title
                Expanded(flex: 4, child: _buildLogoArea()),

                // Login card
                _buildCard(auth, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo area ────────────────────────────────────────────────
  Widget _buildLogoArea() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Icon(
          widget.isCompany ? Icons.business_rounded : Icons.school_rounded,
          color: Colors.white, size: 36,
        ),
      )
        .animate()
        .scale(begin: const Offset(0.4, 0.4), duration: 700.ms, curve: Curves.elasticOut, delay: 100.ms)
        .fadeIn(duration: 400.ms, delay: 100.ms),

      const SizedBox(height: 14),

      Text(
        _t_title,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8),
      )
        .animate()
        .slideY(begin: 0.4, duration: 500.ms, curve: Curves.easeOutCubic, delay: 260.ms)
        .fadeIn(duration: 400.ms, delay: 260.ms),

      const SizedBox(height: 4),

      Text(
        _mn ? 'Оюунтан платформд тавтай морил' : 'Welcome to Oyuntan Platform',
        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.60)),
      ).animate().fadeIn(duration: 400.ms, delay: 380.ms),
    ],
  );

  // ── Login card ───────────────────────────────────────────────
  Widget _buildCard(AuthProvider auth, BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 22, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(child: Container(
              width: 44, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),

            // Role badge
            Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(widget.isCompany ? Icons.business_rounded : Icons.person_rounded,
                  size: 14, color: _accentColor),
                const SizedBox(width: 6),
                Text(
                  widget.isCompany ? (_mn ? 'Компани' : 'Company') : (_mn ? 'Оюутан' : 'Student'),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accentColor),
                ),
              ]),
            )).animate().fadeIn(delay: 440.ms),

            const SizedBox(height: 18),

            // Error
            if (auth.error != null) ...[
              Container(
                width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(auth.error!, style: const TextStyle(fontSize: 12, color: AppColors.red))),
                ]),
              ),
              const SizedBox(height: 14),
            ],

            // Email field
            _FieldLabel(_t_email),
            TextField(
              controller: _email, keyboardType: TextInputType.emailAddress, autocorrect: false,
              decoration: InputDecoration(
                hintText: 'name@example.com',
                prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.faint),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _accentColor, width: 1.5),
                ),
              ),
              onChanged: (_) => auth.clearError(),
            ).animate().fadeIn(delay: 500.ms),

            // Password field
            _FieldLabel(_t_pw),
            TextField(
              controller: _pw, obscureText: _obscure,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.faint),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _accentColor, width: 1.5),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18, color: AppColors.faint),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onChanged: (_) => auth.clearError(),
            ).animate().fadeIn(delay: 540.ms),

            // Forgot password link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showForgotPassword(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(_t_forgot,
                  style: TextStyle(fontSize: 12, color: _accentColor, fontWeight: FontWeight.w500)),
              ),
            ).animate().fadeIn(delay: 560.ms),

            const SizedBox(height: 18),

            // Login button
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: auth.loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: auth.loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_t_login, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ).animate().fadeIn(delay: 590.ms).slideY(begin: 0.2, duration: 350.ms, delay: 590.ms),

            const SizedBox(height: 10),

            // Register button
            OutlinedButton(
              onPressed: () => context.push(
                widget.isCompany ? '/register/company' : '/register/student',
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _accentColor.withValues(alpha: 0.40), width: 1),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_t_register,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _accentColor)),
            ).animate().fadeIn(delay: 630.ms),

            const SizedBox(height: 12),

            // Help link
            Center(
              child: GestureDetector(
                onTap: () => _showHelp(context),
                child: Text(_t_help,
                  style: TextStyle(fontSize: 12, color: AppColors.faint, decoration: TextDecoration.underline)),
              ),
            ).animate().fadeIn(delay: 660.ms),
          ],
        ),
      ),
    )
      .animate()
      .slideY(begin: 0.6, duration: 600.ms, curve: Curves.easeOutCubic, delay: 200.ms)
      .fadeIn(duration: 400.ms, delay: 200.ms);
  }

  // ── Handlers ─────────────────────────────────────────────────
  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(_email.text.trim(), _pw.text);
    if (ok && mounted) context.go(auth.isCompany ? '/company/home' : '/home');
  }

  void _showForgotPassword(BuildContext ctx) {
    final emailCtrl = TextEditingController(text: _email.text.trim());
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => _ForgotPasswordSheet(
        emailCtrl: emailCtrl,
        accentColor: _accentColor,
        mn: _mn,
        onSend: (email) async {
          final auth = context.read<AuthProvider>();
          final ok = await auth.resetPassword(email);
          if (ok && ctx.mounted) {
            Navigator.pop(sheetCtx);
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(_mn
                ? 'Имэйл илгээлээ! Шуудан хайрцагаа шалгана уу.'
                : 'Email sent! Please check your inbox.'),
              backgroundColor: AppColors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ));
          }
        },
      ),
    );
  }

  void _showHelp(BuildContext ctx) => showModalBottomSheet(
    context: ctx,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Icon(Icons.help_outline_rounded, size: 40, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(_mn ? 'Тусламж' : 'Help',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(
          _mn
            ? 'Нэвтрэхэд асуудал гарвал support@oyuntan.mn руу имэйл илгээх эсвэл +976 9900-0000 дугаарт залгана уу.'
            : 'If you have trouble signing in, email support@oyuntan.mn or call +976 9900-0000.',
          style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
      ]),
    ),
  );

  @override void dispose() { _email.dispose(); _pw.dispose(); _ctrl.dispose(); super.dispose(); }
}

// ─────────────────────────────────────────────────────────────
//  Forgot Password sheet
// ─────────────────────────────────────────────────────────────
class _ForgotPasswordSheet extends StatefulWidget {
  final TextEditingController emailCtrl;
  final Color accentColor;
  final bool mn;
  final Future<void> Function(String) onSend;
  const _ForgotPasswordSheet({required this.emailCtrl, required this.accentColor, required this.mn, required this.onSend});
  @override State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}
class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  bool _sending = false;

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Handle
      Center(child: Container(width: 44, height: 4,
        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 20),

      Row(children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 22)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.mn ? 'Нууц үг сэргээх' : 'Reset Password',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          Text(widget.mn ? 'Имэйл хаягаа оруулна уу' : 'Enter your email address',
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      ]),
      const SizedBox(height: 20),

      Text(widget.mn ? 'Имэйл' : 'Email',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted)),
      const SizedBox(height: 6),
      TextField(
        controller: widget.emailCtrl,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: 'name@example.com',
          prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.faint),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: widget.accentColor, width: 1.5),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        widget.mn
          ? 'Тухайн имэйл рүү нууц үг шинэчлэх холбоос илгээгдэнэ.'
          : 'A password reset link will be sent to this email.',
        style: const TextStyle(fontSize: 11, color: AppColors.faint, height: 1.5),
      ),
      const SizedBox(height: 20),

      SizedBox(
        width: double.infinity, height: 48,
        child: ElevatedButton(
          onPressed: _sending ? null : () async {
            if (widget.emailCtrl.text.trim().isEmpty) return;
            setState(() => _sending = true);
            await widget.onSend(widget.emailCtrl.text.trim());
            if (mounted) setState(() => _sending = false);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accentColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _sending
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(widget.mn ? 'Холбоос илгээх' : 'Send reset link',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  Language toggle
// ─────────────────────────────────────────────────────────────
class _LangToggle extends StatelessWidget {
  final bool mn;
  final void Function(bool) onToggle;
  const _LangToggle({required this.mn, required this.onToggle});

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 0.5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _Pill('МН', mn,  () => onToggle(true)),
      _Pill('EN', !mn, () => onToggle(false)),
    ]),
  );
}

class _Pill extends StatelessWidget {
  final String l; final bool on; final VoidCallback t;
  const _Pill(this.l, this.on, this.t);
  @override Widget build(BuildContext c) => GestureDetector(
    onTap: t,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: on ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(l, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: on ? const Color(0xFF1E3A8A) : Colors.white70,
      )),
    ),
  );
}

// ── Helpers ───────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final double size; final double opacity;
  const _Orb(this.size, this.opacity);
  @override Widget build(BuildContext ctx) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 14),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted)),
  );
}
