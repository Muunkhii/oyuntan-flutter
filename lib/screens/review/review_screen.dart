// lib/screens/review/review_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class ReviewScreen extends StatefulWidget {
  final String internshipId;
  const ReviewScreen({super.key, required this.internshipId});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _commentCtrl = TextEditingController();
  final _reviewService = ReviewService();

  int _envScore      = 3;
  int _mentorScore   = 3;
  int _learnScore    = 3;
  int _relationScore = 3;
  bool _wouldReturn  = true;
  bool _saving       = false;

  String? _companyId;
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _loadInternship();
  }

  Future<void> _loadInternship() async {
    final doc = await DB.internships.doc(widget.internshipId).get();
    if (mounted) {
      setState(() {
        _companyId = doc.data()?['companyId'] as String? ?? doc.data()?['postId'] as String?;
        _studentId = context.read<AuthProvider>().user?.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Үнэлгээ өгөх'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black))
                : const Text('Илгээх', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.black)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Дадлагаа үнэлнэ үү', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Text('Таны үнэлгээ бусад оюутанд тусална', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 28),

          _RatingRow('Ажлын орчин', _envScore,      (v) => setState(() => _envScore = v)),
          _RatingRow('Ментор',      _mentorScore,   (v) => setState(() => _mentorScore = v)),
          _RatingRow('Суралцах',    _learnScore,    (v) => setState(() => _learnScore = v)),
          _RatingRow('Харилцаа',    _relationScore, (v) => setState(() => _relationScore = v)),

          const SizedBox(height: 20),
          const Text('Дахин ажиллахыг хүсэх үү?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Row(children: [
            _ReturnChip('Тийм',  true,  _wouldReturn, () => setState(() => _wouldReturn = true)),
            const SizedBox(width: 10),
            _ReturnChip('Үгүй', false, _wouldReturn, () => setState(() => _wouldReturn = false)),
          ]),

          const SizedBox(height: 20),
          const Text('Сэтгэгдэл (заавал биш)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _commentCtrl,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Дадлагын туршлагаа хуваалцаарай...'),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: const Text('Үнэлгээ илгээх'),
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_companyId == null || _studentId == null) return;
    setState(() => _saving = true);
    try {
      await _reviewService.submitReview(
        internshipId:  widget.internshipId,
        studentId:     _studentId!,
        companyId:     _companyId!,
        envScore:      _envScore,
        mentorScore:   _mentorScore,
        learnScore:    _learnScore,
        relationScore: _relationScore,
        wouldReturn:   _wouldReturn,
        comment:       _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Үнэлгээ илгээгдлээ'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _RatingRow(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13))),
      Expanded(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => onChanged(star),
              child: Icon(
                star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 32,
                color: star <= value ? AppColors.amber : AppColors.border,
              ),
            );
          }),
        ),
      ),
      SizedBox(width: 24, child: Text('$value', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
    ]),
  );
}

class _ReturnChip extends StatelessWidget {
  final String label;
  final bool chipValue, selected;
  final VoidCallback onTap;
  const _ReturnChip(this.label, this.chipValue, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = selected == chipValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.black : AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.black : AppColors.border, width: 0.5),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: active ? AppColors.white : AppColors.textSecondary,
        )),
      ),
    );
  }
}
