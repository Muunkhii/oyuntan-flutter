// lib/screens/auth/register_student_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});
  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _uniCtrl   = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _bioCtrl   = TextEditingController();

  int _year = 1;
  bool _obscure = true;
  final List<String> _skills = [];
  final _skillCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text('Оюутан бүртгүүлэх'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Label('Овог'),
          TextField(controller: _lastCtrl,  decoration: const InputDecoration(hintText: 'Бат-Эрдэнэ')),
          const SizedBox(height: 12),

          const _Label('Нэр'),
          TextField(controller: _firstCtrl, decoration: const InputDecoration(hintText: 'Болд')),
          const SizedBox(height: 12),

          const _Label('Имэйл'),
          TextField(controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress, autocorrect: false,
            decoration: const InputDecoration(hintText: 'name@example.com')),
          const SizedBox(height: 12),

          const _Label('Нууц үг'),
          TextField(
            controller: _passCtrl,
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
          const SizedBox(height: 12),

          const _Label('Их сургууль'),
          TextField(controller: _uniCtrl, decoration: const InputDecoration(hintText: 'МУИС')),
          const SizedBox(height: 12),

          const _Label('Мэргэжил'),
          TextField(controller: _majorCtrl, decoration: const InputDecoration(hintText: 'Програм хангамж')),
          const SizedBox(height: 12),

          const _Label('Курс'),
          Row(children: List.generate(4, (i) {
            final y = i + 1;
            return Expanded(child: Padding(
              padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _year = y),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _year == y ? AppColors.black : AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _year == y ? AppColors.black : AppColors.border, width: 0.5),
                  ),
                  child: Text('$y-р', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: _year == y ? AppColors.white : AppColors.textSecondary)),
                ),
              ),
            ));
          })),
          const SizedBox(height: 12),

          const _Label('Ур чадвар'),
          Row(children: [
            Expanded(child: TextField(
              controller: _skillCtrl,
              decoration: const InputDecoration(hintText: 'Flutter, Python...'),
              onSubmitted: _addSkill,
            )),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _addSkill(_skillCtrl.text),
              icon: const Icon(Icons.add_circle_outline, color: AppColors.black),
            ),
          ]),
          if (_skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6,
              children: _skills.map((s) => Chip(
                label: Text(s, style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => setState(() => _skills.remove(s)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList()),
          ],
          const SizedBox(height: 12),

          const _Label('Товч танилцуулга (заавал биш)'),
          TextField(
            controller: _bioCtrl, maxLines: 3,
            decoration: const InputDecoration(hintText: 'Өөрийгөө товч танилцуул...'),
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: _next,
            child: const Text('Үргэлжлүүлэх →'),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _addSkill(String s) {
    final skill = s.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() => _skills.add(skill));
    }
    _skillCtrl.clear();
  }

  void _next() {
    if (_firstCtrl.text.trim().isEmpty || _lastCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty ||
        _uniCtrl.text.trim().isEmpty   || _majorCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Бүх талбарыг бөглөнө үү'),
        backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    context.push('/psych-test', extra: {
      'firstName': _firstCtrl.text.trim(),
      'lastName':  _lastCtrl.text.trim(),
      'email':     _emailCtrl.text.trim(),
      'password':  _passCtrl.text,
      'university':_uniCtrl.text.trim(),
      'major':     _majorCtrl.text.trim(),
      'year':      _year,
      'skills':    List<String>.from(_skills),
      'bio':       _bioCtrl.text.trim(),
    });
  }

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose();  _uniCtrl.dispose();  _majorCtrl.dispose();
    _bioCtrl.dispose();   _skillCtrl.dispose();
    super.dispose();
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  );
}
