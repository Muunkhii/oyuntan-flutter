// lib/screens/home/company_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/home_widgets.dart';

class CompanyHomeScreen extends StatelessWidget {
  const CompanyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid  = auth.user?.uid ?? '';
    final h    = DateTime.now().hour;
    final greeting =
        h < 12 ? 'Өглөөний мэнд' : h < 17 ? 'Өдрийн мэнд' : 'Оройн мэнд';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        automaticallyImplyLeading: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(greeting,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400)),
          Text(auth.displayName.isEmpty ? 'Компани' : auth.displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () => context.push('/company/notifications'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: InternshipService().getCompanyPosts(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2));
          }
          final posts = snap.data?.docs ?? [];

          // Stats
          final totalApplicants = posts.fold<int>(
              0, (s, d) => s + ((d['applicantCount'] as num?)?.toInt() ?? 0));

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const WeatherDateHeader(),
              const SizedBox(height: 8),
              const AdCarousel(ads: companyAds),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.2,
                  children: [
                    _StatCard('Нийт зар',    '${posts.length}',     AppColors.blueLight,   AppColors.blue),
                    _StatCard('Хүсэлт',      '$totalApplicants',    AppColors.tealLight,   AppColors.teal),
                    _StatCard('Идэвхтэй',
                      '${posts.where((d) => d['isActive'] == true).length}',
                      AppColors.purpleLight, AppColors.purple),
                    _StatCard('Дадлагажигч', '—',                   AppColors.amberLight,  AppColors.amber),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionLabel('Миний зарууд'),
                    TextButton(
                      onPressed: () => _showCreatePost(context, uid),
                      style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero),
                      child: const Text('+ Зар нэмэх',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),

              if (posts.isEmpty)
                const _EmptyPosts()
              else
                ...posts.map((doc) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _PostCard(doc: doc),
                )),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePost(context, uid),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Зар нэмэх',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }

  void _showCreatePost(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreatePostSheet(companyId: uid),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color bg, fg;
  const _StatCard(this.label, this.value, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(label, style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.8))),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w500, color: fg)),
    ]),
  );
}

class _PostCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _PostCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data     = doc.data() as Map<String, dynamic>;
    final title    = data['title']          as String? ?? 'Зар';
    final count    = (data['applicantCount'] as num?)?.toInt() ?? 0;
    final isActive = data['isActive']       as bool?   ?? false;
    final duration = (data['durationDays']  as num?)?.toInt() ?? 0;

    return AppCard(
      onTap: () => context.push('/company/swipe/${doc.id}'),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(children: [
              Text('$count хүсэлт',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 10),
              Text('$duration өдөр',
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ]),
          ]),
        ),
        AppTag(
          isActive ? 'Идэвхтэй' : 'Хаалттай',
          bg: isActive ? AppColors.tealLight : AppColors.bg,
          textColor: isActive ? AppColors.teal : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
      ]),
    );
  }
}

class _EmptyPosts extends StatelessWidget {
  const _EmptyPosts();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: AppColors.bg, borderRadius: BorderRadius.circular(28)),
          child: const Icon(Icons.work_outline, size: 28, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        const Text('Зар байхгүй байна',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        const Text('Шинэ зар нэмж оюутан хайж эхэлнэ үү',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    ),
  );
}

// ── Create Post Sheet (improved) ──────────────────────
class _CreatePostSheet extends StatefulWidget {
  final String companyId;
  const _CreatePostSheet({required this.companyId});
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _daysCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _salaryCtrl   = TextEditingController();
  final _skillCtrl    = TextEditingController();
  bool _saving = false;
  bool _isFreelance = false;
  final List<String> _skills = [];

  void _addSkill(String s) {
    final sk = s.trim();
    if (sk.isNotEmpty && !_skills.contains(sk)) {
      setState(() => _skills.add(sk));
    }
    _skillCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('Шинэ зар',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),

          // Type toggle
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              _SheetSeg('Дадлага', !_isFreelance,
                  () => setState(() => _isFreelance = false)),
              _SheetSeg('Freelance', _isFreelance,
                  () => setState(() => _isFreelance = true)),
            ]),
          ),
          const SizedBox(height: 14),

          const _L('Ажлын нэр'),
          TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                  hintText: _isFreelance
                      ? 'Жишээ нь: Лого дизайн'
                      : 'Жишээ нь: Frontend Intern')),
          const SizedBox(height: 10),

          const _L('Хугацаа (өдөр)'),
          TextField(
              controller: _daysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '30')),
          const SizedBox(height: 10),

          const _L('Байршил'),
          TextField(
              controller: _locationCtrl,
              decoration:
                  const InputDecoration(hintText: 'Улаанбаатар / Онлайн')),
          const SizedBox(height: 10),

          const _L('Цалин / Урамшуулал (заавал биш)'),
          TextField(
              controller: _salaryCtrl,
              decoration:
                  const InputDecoration(hintText: 'Сараар / Дүн дээр')),
          const SizedBox(height: 10),

          const _L('Тайлбар'),
          TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Ажлын агуулга, шаардлага...')),
          const SizedBox(height: 10),

          const _L('Шаардлагатай ур чадвар'),
          Row(children: [
            Expanded(
              child: TextField(
                  controller: _skillCtrl,
                  decoration: const InputDecoration(hintText: 'React, Figma...'),
                  onSubmitted: _addSkill),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => _addSkill(_skillCtrl.text),
              icon: const Icon(Icons.add_circle_outline, color: AppColors.black),
            ),
          ]),
          if (_skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: _skills.map((s) => Chip(
                label: Text(s, style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => setState(() => _skills.remove(s)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.white, strokeWidth: 2))
                : const Text('Нийтлэх'),
          ),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final data = {
        'title':       _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'companyId':   widget.companyId,
        'durationDays': int.tryParse(_daysCtrl.text) ?? 30,
        'location':    _locationCtrl.text.trim(),
        'salary':      _salaryCtrl.text.trim(),
        'skills':      List<String>.from(_skills),
        'majors':      <String>[],
        'isActive':    true,
      };
      if (_isFreelance) {
        await DB.freelance.add({
          ...data,
          'category': 'Бусад',
          'budget':   _salaryCtrl.text.trim(),
          'deadline': '${int.tryParse(_daysCtrl.text) ?? 14} хоног',
        });
      } else {
        await InternshipService().createPost(data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Зар амжилттай нийтлэгдлээ'),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Алдаа: ${e.toString().replaceAll('Exception: ', '')}'),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _daysCtrl.dispose();
    _locationCtrl.dispose(); _salaryCtrl.dispose(); _skillCtrl.dispose();
    super.dispose();
  }
}

class _SheetSeg extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SheetSeg(this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active
              ? Border.all(color: AppColors.border, width: 0.5)
              : null,
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                color: active ? AppColors.textPrimary : AppColors.textSecondary)),
      ),
    ),
  );
}

class _L extends StatelessWidget {
  final String text;
  const _L(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style:
            const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  );
}
