// lib/screens/diary/diary_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class DiaryScreen extends StatefulWidget {
  final String internshipId;
  const DiaryScreen({super.key, required this.internshipId});
  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _workCtrl    = TextEditingController();
  final _interCtrl   = TextEditingController();
  final _diary       = DiaryService();

  String? _mood;
  List<String> _categories = [];
  bool _saving = false;
  int _dayNumber = 1;

  static const _moods = [
    ('Урамтай',    Color(0xFFE1F5EE), Color(0xFF0F6E56)),
    ('Тайван',     Color(0xFFEEEDFE), Color(0xFF534AB7)),
    ('Ядарсан',    Color(0xFFF1EFE8), Color(0xFF5F5E5A)),
    ('Стресстэй',  Color(0xFFFAECE7), Color(0xFF993C1D)),
    ('Баяртай',    Color(0xFFEAF3DE), Color(0xFF3B6D11)),
    ('Санаа зовсон',Color(0xFFFAEEDA), Color(0xFF854F0B)),
    ('Хэцүүхэн',   Color(0xFFFCEBEB), Color(0xFFA32D2D)),
    ('Гайхалтай',  Color(0xFFE6F1FB), Color(0xFF185FA5)),
  ];

  static const _cats = ['Суралцах','Код бичих','Хурал','Дизайн','Тест','Баримт бичих'];

  @override
  void initState() {
    super.initState();
    _loadDayNumber();
  }

  Future<void> _loadDayNumber() async {
    final doc = await DiaryService().getEntries(widget.internshipId).first;
    if (mounted) setState(() => _dayNumber = doc.docs.length + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Өдрийн тэмдэглэл'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black))
                : const Text('Хадгалах', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.black)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // What did you do
          const _SLabel('ӨНӨӨДӨР ЮУ ХИЙЛЭЭ?'),
          TextField(
            controller: _workCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Жишээ нь: API судалж, POST request илгээх дасгал хийлээ...',
            ),
          ),
          const SizedBox(height: 24),

          // Mood
          const _SLabel('ӨНӨӨДРИЙН МЭДРЭМЖ'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _moods.map((m) {
              final selected = _mood == m.$1;
              return GestureDetector(
                onTap: () => setState(() => _mood = m.$1),
                child: AnimatedContainer(
                  duration: 120.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? m.$2 : AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? m.$3 : AppColors.border,
                      width: selected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(m.$1, style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    color: selected ? m.$3 : AppColors.textSecondary,
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Interactions
          const _SLabel('ХҮМҮҮС НАДТАЙ ХЭРХЭН ХАРЬЦСАН БЭ?'),
          TextField(
            controller: _interCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Mentor тайвнаар тайлбарласан, багийнхан найрсаг байсан...',
            ),
          ),
          const SizedBox(height: 24),

          // Categories
          const _SLabel('АЖЛЫН АНГИЛАЛ'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _cats.map((c) {
              final on = _categories.contains(c);
              return FilterChip(
                label: Text(c),
                selected: on,
                onSelected: (_) => setState(() =>
                  on ? _categories.remove(c) : _categories.add(c)),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Save button
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: const Text('Хадгалах'),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (_workCtrl.text.trim().isEmpty) {
      _snack('Өнөөдөр юу хийснээ бичнэ үү'); return;
    }
    if (_mood == null) { _snack('Мэдрэмжээ сонгоно уу'); return; }

    setState(() => _saving = true);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      await _diary.addEntry(
        internshipId: widget.internshipId,
        studentId: uid,
        dayNumber: _dayNumber,
        workDone: _workCtrl.text.trim(),
        mood: _mood!,
        interactions: _interCtrl.text.trim().isEmpty ? null : _interCtrl.text.trim(),
        categories: _categories,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Тэмдэглэл хадгалагдлаа'),
            backgroundColor: AppColors.teal, behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      }
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));

  @override
  void dispose() { _workCtrl.dispose(); _interCtrl.dispose(); super.dispose(); }
}

class _SLabel extends StatelessWidget {
  final String text;
  const _SLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(
      fontSize: 10, fontWeight: FontWeight.w600,
      color: AppColors.textSecondary, letterSpacing: 0.6)),
  );
}
