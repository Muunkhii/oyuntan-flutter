// lib/screens/home/company_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});
  @override State<CompanyHomeScreen> createState() => _CompanyHomeState();
}

class _CompanyHomeState extends State<CompanyHomeScreen> {
  late Future<List<Map<String, dynamic>>> _postsFuture;
  String _uid = '';

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthProvider>().uid;
    _postsFuture = _uid.isNotEmpty
        ? InternshipService().getCompanyPosts(_uid)
        : Future.value([]);
  }

  void _load() {
    if (!mounted) return;
    setState(() {
      _postsFuture = _uid.isNotEmpty
          ? InternshipService().getCompanyPosts(_uid)
          : Future.value([]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final mn   = context.watch<LocaleProvider>().isMN;
    final h    = DateTime.now().hour;
    final greeting = h < 12 ? (mn ? 'Өглөөний мэнд' : 'Good morning')
                   : h < 17 ? (mn ? 'Өдрийн мэнд'   : 'Good afternoon')
                   :           (mn ? 'Оройн мэнд'    : 'Good evening');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _postsFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.muted),
                const SizedBox(height: 12),
                Text(snap.error.toString(), style: const TextStyle(color: AppColors.muted, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(onPressed: _load, child: const Text('Дахин оролдох')),
              ]),
            ));
          }
          final loading = snap.connectionState == ConnectionState.waiting;
          final posts   = snap.data ?? [];
          final total   = posts.fold<int>(0, (s, d) => s + ((d['applicant_count'] as num?)?.toInt() ?? 0));
          final active  = posts.where((d) => d['is_active'] == true).length;

          return RefreshIndicator(
            color: AppColors.teal,
            onRefresh: () async => _load(),
            child: CustomScrollView(
              slivers: [
                // ── Teal gradient header ──────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0E7490), Color(0xFF06B6D4)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(greeting,
                                style: const TextStyle(fontSize: 12, color: Colors.white70)),
                              const SizedBox(height: 2),
                              Text(
                                auth.displayName.isEmpty ? (mn ? 'Компани' : 'Company') : auth.displayName,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ])),
                            GestureDetector(
                              onTap: () => context.push('/company/notif'),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // 3-column stats row
                          if (loading)
                            const Center(child: SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                          else
                            Row(children: [
                              _StatPill(mn ? 'Нийт зар' : 'Posts',      '${posts.length}', Icons.description_outlined),
                              const SizedBox(width: 10),
                              _StatPill(mn ? 'Хүсэлт'  : 'Applicants', '$total',           Icons.people_outline),
                              const SizedBox(width: 10),
                              _StatPill(mn ? 'Идэвхтэй': 'Active',      '$active',          Icons.check_circle_outline),
                            ]),
                        ]),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // ── Quick actions ───────────────────────
                      Row(children: [
                        _QuickAction(
                          icon: Icons.add_circle_outline,
                          label: mn ? 'Зар нэмэх' : 'New post',
                          color: AppColors.teal,
                          onTap: () => _showCreatePost(context),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.people_alt_outlined,
                          label: mn ? 'Дадлагчид' : 'Interns',
                          color: AppColors.primary,
                          onTap: () => context.go('/company/interns'),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.person_outline,
                          label: mn ? 'Профайл' : 'Profile',
                          color: AppColors.purple,
                          onTap: () => context.go('/company/profile'),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // ── Posts section ───────────────────────
                      Row(children: [
                        Expanded(child: SectionLabel(mn ? 'Миний зарууд' : 'My posts')),
                        GestureDetector(
                          onTap: () => _showCreatePost(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.add, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(mn ? 'Нэмэх' : 'Add',
                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 10),

                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2)),
                        )
                      else if (posts.isEmpty)
                        const _EmptyPosts()
                      else
                        ...posts.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PostCard(data: d),
                        )),

                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreatePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreatePostSheet(onSaved: _load),
    );
  }
}

// ── Stat Pill ──────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatPill(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70), textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Quick Action ───────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}

// ── Post Card ─────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PostCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title    = data['title']           as String? ?? 'Зар';
    final count    = (data['applicant_count'] as num?)?.toInt() ?? 0;
    final isActive = data['is_active']       as bool?   ?? false;
    final duration = (data['duration_days']  as num?)?.toInt() ?? 0;
    final location = data['location']        as String? ?? '';

    return GestureDetector(
      onTap: () => context.push('/company/swipe/${data['id']}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.tealLight : AppColors.bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Идэвхтэй' : 'Хаалттай',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.teal : AppColors.muted,
                ),
              ),
            ),
          ]),

          if (location.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.faint),
              const SizedBox(width: 4),
              Text(location, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(children: [
            _MetricChip(Icons.people_outline, '$count хүсэлт', AppColors.primary),
            const SizedBox(width: 10),
            _MetricChip(Icons.schedule_outlined, '$duration өдөр', AppColors.purple),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.faint),
          ]),
        ]),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetricChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: color),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
  ]);
}

// ── Empty Posts ────────────────────────────────────────────────
class _EmptyPosts extends StatelessWidget {
  const _EmptyPosts();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: AppColors.tealLight,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Icon(Icons.work_outline, size: 30, color: AppColors.teal),
      ),
      const SizedBox(height: 14),
      const Text('Зар байхгүй байна', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Шинэ зар нэмж оюутан хайж эхэлнэ үү',
          style: TextStyle(fontSize: 12, color: AppColors.muted)),
    ])),
  );
}

// ── Create Post Sheet ──────────────────────────────────────────
class _CreatePostSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _CreatePostSheet({required this.onSaved});
  @override State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _daysCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _salaryCtrl   = TextEditingController();
  final _skillCtrl    = TextEditingController();
  bool _saving        = false;
  final List<String> _skills = [];

  void _addSkill(String s) {
    final sk = s.trim();
    if (sk.isNotEmpty && !_skills.contains(sk)) setState(() => _skills.add(sk));
    _skillCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 4, height: 20,
              decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            const Text('Шинэ зар', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          const _L('Ажлын нэр'),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Жишээ нь: Frontend Intern')),
          const SizedBox(height: 10),
          const _L('Хугацаа (өдөр)'),
          TextField(controller: _daysCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '30')),
          const SizedBox(height: 10),
          const _L('Байршил'),
          TextField(controller: _locationCtrl, decoration: const InputDecoration(hintText: 'Улаанбаатар / Онлайн')),
          const SizedBox(height: 10),
          const _L('Цалин (заавал биш)'),
          TextField(controller: _salaryCtrl, decoration: const InputDecoration(hintText: 'Сараар / Дүн дээр')),
          const SizedBox(height: 10),
          const _L('Тайлбар'),
          TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Ажлын агуулга, шаардлага...')),
          const SizedBox(height: 10),
          const _L('Шаардлагатай ур чадвар'),
          Row(children: [
            Expanded(child: TextField(controller: _skillCtrl, decoration: const InputDecoration(hintText: 'React, Figma...'), onSubmitted: _addSkill)),
            const SizedBox(width: 6),
            IconButton(onPressed: () => _addSkill(_skillCtrl.text), icon: const Icon(Icons.add_circle_outline, color: AppColors.teal)),
          ]),
          if (_skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: _skills.map((s) => Chip(
              label: Text(s, style: const TextStyle(fontSize: 11)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => setState(() => _skills.remove(s)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList()),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
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
      await InternshipService().createPost({
        'title':          _titleCtrl.text.trim(),
        'description':    _descCtrl.text.trim(),
        'durationDays':   int.tryParse(_daysCtrl.text) ?? 30,
        'location':       _locationCtrl.text.trim(),
        'salary':         _salaryCtrl.text.trim(),
        'requiredSkills': List<String>.from(_skills),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Зар амжилттай нийтлэгдлээ'),
        backgroundColor: AppColors.teal, behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
      widget.onSaved();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _descCtrl, _daysCtrl, _locationCtrl, _salaryCtrl, _skillCtrl]) { c.dispose(); }
    super.dispose();
  }
}

class _L extends StatelessWidget {
  final String text;
  const _L(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
  );
}
