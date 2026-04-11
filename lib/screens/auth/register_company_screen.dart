// lib/screens/auth/register_company_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterCompanyScreen extends StatefulWidget {
  const RegisterCompanyScreen({super.key});
  @override
  State<RegisterCompanyScreen> createState() => _RegisterCompanyScreenState();
}

class _RegisterCompanyScreenState extends State<RegisterCompanyScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();

  String _industry = 'Технологи';
  String _size     = '1-10';
  bool _obscure    = true;
  bool _loading    = false;

  static const _industries = ['Технологи','Санхүү','Боловсрол','Эрүүл мэнд','Худалдаа','Бусад'];
  static const _sizes      = ['1-10','11-50','51-200','201-500','500+'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text('Компани бүртгүүлэх'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Label('Компанийн нэр'),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Datacom LLC')),
          const SizedBox(height: 12),

          const _Label('Имэйл'),
          TextField(controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress, autocorrect: false,
            decoration: const InputDecoration(hintText: 'hr@company.mn')),
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

          const _Label('Салбар'),
          _DropRow<String>(
            items: _industries,
            value: _industry,
            label: (s) => s,
            onChanged: (v) => setState(() => _industry = v!),
          ),
          const SizedBox(height: 12),

          const _Label('Ажилтны тоо'),
          _DropRow<String>(
            items: _sizes,
            value: _size,
            label: (s) => s,
            onChanged: (v) => setState(() => _size = v!),
          ),
          const SizedBox(height: 12),

          const _Label('Тайлбар (заавал биш)'),
          TextField(controller: _descCtrl, maxLines: 3,
            decoration: const InputDecoration(hintText: 'Компанийн үйл ажиллагааг товч тайлбарлана уу...')),
          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: _loading ? null : _register,
            child: _loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                : const Text('Бүртгүүлэх'),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Бүх талбарыг бөглөнө үү'),
        backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.registerCompany({
      'name':        _nameCtrl.text.trim(),
      'email':       _emailCtrl.text.trim(),
      'industry':    _industry,
      'size':        _size,
      'description': _descCtrl.text.trim(),
      'avgScore':    0.0,
      'reviewCount': 0,
    }, _passCtrl.text);

    if (mounted) {
      if (ok) {
        context.go('/company');
      } else {
        setState(() => _loading = false);
        if (auth.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(auth.error!),
            backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _descCtrl.dispose();
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

class _DropRow<T> extends StatelessWidget {
  final List<T> items;
  final T value;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;
  const _DropRow({required this.items, required this.value, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(label(e), style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
