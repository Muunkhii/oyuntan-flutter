// lib/screens/auth/register_student_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});
  @override State<RegisterStudentScreen> createState() => _State();
}
class _State extends State<RegisterStudentScreen> {
  final _fn=TextEditingController(), _ln=TextEditingController(),
        _ph=TextEditingController(), _em=TextEditingController(),
        _pw=TextEditingController(), _un=TextEditingController(),
        _mj=TextEditingController();
  DateTime? _dob; String _country='Монгол'; bool _obscure=true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Оюутан бүртгэл'), actions: [const LangToggle(), const SizedBox(width: 12)]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (auth.error != null) ...[
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10)),
              child: Text(auth.error!, style: const TextStyle(fontSize: 12, color: AppColors.red))),
            const SizedBox(height: 14),
          ],

          const FieldLabel('Нэр'), TextField(controller: _fn, decoration: const InputDecoration(hintText: 'Болд')),
          const FieldLabel('Овог'), TextField(controller: _ln, decoration: const InputDecoration(hintText: 'Төмөр')),
          const FieldLabel('Төрсөн огноо'),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1990), lastDate: DateTime(2010));
              if (d != null) setState(() => _dob=d);
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 0.5)),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.faint),
                const SizedBox(width: 8),
                Text(_dob==null ? 'Огноо сонгох' : '${_dob!.year}-${_dob!.month.toString().padLeft(2,'0')}-${_dob!.day.toString().padLeft(2,'0')}',
                  style: TextStyle(fontSize: 13, color: _dob==null ? AppColors.faint : AppColors.text)),
              ])),
          ),
          const FieldLabel('Утасны дугаар'), TextField(controller: _ph, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+976 ···· ····')),
          const FieldLabel('Улс'), TextField(controller: TextEditingController(text: _country), onChanged: (v)=>_country=v, decoration: const InputDecoration(hintText: 'Монгол')),
          const FieldLabel('Имэйл'), TextField(controller: _em, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(hintText: 'name@example.com')),
          const FieldLabel('Сургууль'), TextField(controller: _un, decoration: const InputDecoration(hintText: 'ШУТИС, МУИС...')),
          const FieldLabel('Суралцаж буй мэргэжил'), TextField(controller: _mj, decoration: const InputDecoration(hintText: 'Програм хангамж...')),
          const FieldLabel('Нууц үг'),
          TextField(controller: _pw, obscureText: _obscure,
            decoration: InputDecoration(hintText: '••••••••',
              suffixIcon: IconButton(icon: Icon(_obscure?Icons.visibility_off_outlined:Icons.visibility_outlined,size:18,color:AppColors.faint), onPressed:()=>setState(()=>_obscure=!_obscure)))),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Бүртгүүлэх →', loading: auth.loading, onTap: _register),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Future<void> _register() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    if ([_fn.text, _ln.text, _em.text, _pw.text, _un.text, _mj.text].any((s) => s.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Бүх талбарыг бөглөнө үү'), backgroundColor: AppColors.red));
      return;
    }
    final data = {
      'firstName': _fn.text.trim(), 'lastName': _ln.text.trim(),
      'birthDate': _dob?.toIso8601String(), 'phone': _ph.text.trim(),
      'country': _country, 'email': _em.text.trim(),
      'university': _un.text.trim(), 'major': _mj.text.trim(), 'year': 1,
    };
    final ok = await auth.registerStudent(data, _pw.text);
    if (ok && mounted) context.go('/welcome?type=student');
  }

  @override void dispose() { for(final c in [_fn,_ln,_ph,_em,_pw,_un,_mj]) { c.dispose(); } super.dispose(); }
}

// ── COMPANY REGISTER ──────────────────────────────────────────
class RegisterCompanyScreen extends StatefulWidget {
  const RegisterCompanyScreen({super.key});
  @override State<RegisterCompanyScreen> createState() => _CState();
}
class _CState extends State<RegisterCompanyScreen> {
  final _name=TextEditingController(), _desc=TextEditingController(),
        _phone=TextEditingController(), _em=TextEditingController(),
        _pw=TextEditingController(), _industry=TextEditingController();
  final _majors = <String>[];
  bool _obscure=true;
  static const _allMajors = ['Програм хангамж','Хиймэл оюун ухаан','Дизайн','Маркетинг','Санхүү','Эрх зүй','Эдийн засаг','Менежмент','Барилга','Анагаах ухаан'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Компани бүртгэл'), actions: [const LangToggle(), const SizedBox(width:12)]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (auth.error!=null) ...[
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10)),
              child: Text(auth.error!, style: const TextStyle(fontSize:12,color:AppColors.red))),
            const SizedBox(height:14),
          ],
          const FieldLabel('Компанийн нэр'), TextField(controller: _name, decoration: const InputDecoration(hintText: 'Datacom LLC')),
          const FieldLabel('Тайлбар мэдээлэл'), TextField(controller: _desc, maxLines: 2, decoration: const InputDecoration(hintText: 'Компанийн товч тайлбар...')),
          const FieldLabel('Утасны дугаар'), TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+976...')),
          const FieldLabel('Имэйл'), TextField(controller: _em, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(hintText: 'info@company.mn')),
          const FieldLabel('Ажлын чиглэл'), TextField(controller: _industry, decoration: const InputDecoration(hintText: 'Мэдээллийн технологи')),
          const FieldLabel('Хайж буй мэргэжил (олон сонгох)'),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8,
            children: _allMajors.map((m) {
              final on = _majors.contains(m);
              return GestureDetector(
                onTap: () => setState(() => on ? _majors.remove(m) : _majors.add(m)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: on ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: on ? AppColors.primary : AppColors.border, width: on?1.5:0.5),
                  ),
                  child: Text(m, style: TextStyle(fontSize: 12, fontWeight: on?FontWeight.w600:FontWeight.w400, color: on?AppColors.white:AppColors.muted)),
                ),
              );
            }).toList(),
          ),
          const FieldLabel('Нууц үг'),
          TextField(controller: _pw, obscureText: _obscure,
            decoration: InputDecoration(hintText: '••••••••',
              suffixIcon: IconButton(icon: Icon(_obscure?Icons.visibility_off_outlined:Icons.visibility_outlined,size:18,color:AppColors.faint), onPressed:()=>setState(()=>_obscure=!_obscure)))),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Бүртгүүлэх', loading: auth.loading, onTap: _register),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Future<void> _register() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final data = {'name':_name.text.trim(),'description':_desc.text.trim(),'phone':_phone.text.trim(),'email':_em.text.trim(),'industry':_industry.text.trim(),'desiredMajors':_majors};
    final ok = await auth.registerCompany(data, _pw.text);
    if (ok && mounted) context.go('/welcome?type=company');
  }

  @override void dispose() { for(final c in [_name,_desc,_phone,_em,_pw,_industry]) { c.dispose(); } super.dispose(); }
}

