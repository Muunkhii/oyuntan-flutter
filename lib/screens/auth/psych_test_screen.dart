// lib/screens/auth/psych_test_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class PsychTestScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  const PsychTestScreen({super.key, required this.studentData});
  @override
  State<PsychTestScreen> createState() => _PsychTestScreenState();
}

class _PsychTestScreenState extends State<PsychTestScreen> {
  int _step = 0;
  bool _loading = false;
  final Map<String, String> _answers = {};

  static const _questions = [
    (
      q: 'Шинэ мэдлэг сурах дуртай уу?',
      key: 'learning',
      options: ['Маш их дуртай', 'Дуртай', 'Дунд зэрэг', 'Дургүй'],
    ),
    (
      q: 'Багаар ажиллах дуртай уу?',
      key: 'teamwork',
      options: ['Маш их дуртай', 'Дуртай', 'Ганцаараа илүүд үздэг', 'Хамаагүй'],
    ),
    (
      q: 'Даралттай нөхцөлд хэрхэн ажилладаг вэ?',
      key: 'pressure',
      options: ['Маш сайн', 'Сайн', 'Дунд зэрэг', 'Хэцүү санагддаг'],
    ),
    (
      q: 'Ямар чиглэлд хамгийн их сонирхолтой вэ?',
      key: 'interest',
      options: ['Техник/Код', 'Дизайн/UI', 'Маркетинг/Борлуулалт', 'Удирдлага/Менежмент'],
    ),
    (
      q: 'Ирээдүйн зорилго чинь юу вэ?',
      key: 'goal',
      options: ['Гадаадад суралцах', 'Монголд карьер хийх', 'Бизнес эхлүүлэх', 'Эрдэм шинжилгээ'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final q = _questions[_step];
    final progress = (_step + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        automaticallyImplyLeading: false,
        title: Text('${_step + 1} / ${_questions.length}',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w400)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.bg,
            color: AppColors.black,
            minHeight: 3,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Text(q.q, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, height: 1.4)),
          const SizedBox(height: 32),
          ...q.options.map((opt) => _OptionTile(
            label: opt,
            selected: _answers[q.key] == opt,
            onTap: () => setState(() => _answers[q.key] = opt),
          )),
          const Spacer(),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2))
          else
            ElevatedButton(
              onPressed: _answers[q.key] == null ? null : _next,
              child: Text(_step < _questions.length - 1 ? 'Үргэлжлүүлэх' : 'Дуусгах'),
            ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Future<void> _next() async {
    if (_step < _questions.length - 1) {
      setState(() => _step++);
      return;
    }
    setState(() => _loading = true);
    final data = Map<String, dynamic>.from(widget.studentData);
    data['psychProfile'] = Map<String, String>.from(_answers);
    final password = data.remove('password') as String;

    final auth = context.read<AuthProvider>();
    final ok = await auth.registerStudent(data, password);
    if (mounted) {
      if (ok) {
        context.go('/home');
      } else {
        setState(() => _loading = false);
        if (auth.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(auth.error!),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? AppColors.black : AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.black : AppColors.border, width: selected ? 1 : 0.5),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 14,
        fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
        color: selected ? AppColors.white : AppColors.textPrimary,
      )),
    ),
  );
}
