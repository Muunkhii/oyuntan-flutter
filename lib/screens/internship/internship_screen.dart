// lib/screens/internship/internship_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class InternshipScreen extends StatefulWidget {
  const InternshipScreen({super.key});
  @override State<InternshipScreen> createState() => _IState();
}

class _IState extends State<InternshipScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Дадлага'),
        actions: [const LangToggle(), const SizedBox(width: 12)],
        bottom: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [Tab(text: 'Зар харах'), Tab(text: 'Миний дадлага')],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        const _FeedTab(),
        const _MyInternshipsTab(),
      ]),
    );
  }
}

// ── Зарын жагсаалт ────────────────────────────────────────────
class _FeedTab extends StatefulWidget {
  const _FeedTab();
  @override State<_FeedTab> createState() => _FeedTabState();
}
class _FeedTabState extends State<_FeedTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override void initState() { super.initState(); _load(); }
  void _load() { setState(() { _future = InternshipService().getFeed(); }); }

  void _showPostDetail(Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostDetailSheet(post: d, onApply: () => _showApplySheet(d)),
    );
  }

  void _showApplySheet(Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplySheet(post: d),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (c, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
        }
        if (snap.hasError) {
          return Center(child: Text(snap.error.toString(), style: const TextStyle(color: AppColors.muted)));
        }
        final posts = snap.data ?? [];
        if (posts.isEmpty) {
          return const Center(child: Text('Зар байхгүй байна', style: TextStyle(color: AppColors.muted)));
        }
        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (c, i) {
              final d = posts[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => _showPostDetail(d),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(d['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Дадлага', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('${d['location'] ?? ''} · ${d['duration_days'] ?? 0} хоног',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    if (d['company_name'] != null) ...[
                      const SizedBox(height: 2),
                      Text(d['company_name'] as String, style: const TextStyle(fontSize: 11, color: AppColors.faint)),
                    ],
                    if ((d['required_skills'] as List?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 4,
                        children: ((d['required_skills'] as List).cast<String>()).take(4).map((s) =>
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
                            child: Text(s, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                          )).toList()),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity, height: 38,
                      child: ElevatedButton(
                        onPressed: () => _showApplySheet(d),
                        child: const Text('Хүсэлт илгээх'),
                      ),
                    ),
                  ]),
                ).animate().fadeIn(delay: Duration(milliseconds: i * 60)),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Миний дадлага ─────────────────────────────────────────────
class _MyInternshipsTab extends StatefulWidget {
  const _MyInternshipsTab();
  @override State<_MyInternshipsTab> createState() => _MyTabState();
}
class _MyTabState extends State<_MyInternshipsTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override void initState() { super.initState(); _load(); }
  void _load() {
    final uid = context.read<AuthProvider>().uid;
    setState(() { _future = InternshipService().getStudentInternships(uid); });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (c, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
        }
        final interns = snap.data ?? [];
        if (interns.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.work_outline, size: 48, color: AppColors.faint),
            const SizedBox(height: 12),
            const Text('Дадлага байхгүй байна', style: TextStyle(color: AppColors.muted)),
          ]));
        }
        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: interns.length,
            itemBuilder: (c, i) {
              final d      = interns[i];
              final id     = d['id'] as String;
              final total  = (d['duration_days'] as num?)?.toInt() ?? 30;
              final done   = (d['completed_days'] as num?)?.toInt() ?? 0;
              final pct    = total > 0 ? done / total : 0.0;
              final status = d['status'] as String? ?? 'active';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(d['title'] ?? 'Дадлага', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                    StatusBadge(
                      status == 'active' ? 'Идэвхтэй' : 'Дууссан',
                      bg: status == 'active' ? AppColors.greenLight : AppColors.bg,
                      textColor: status == 'active' ? AppColors.green : AppColors.muted,
                    ),
                  ]),
                  if (d['company_name'] != null) ...[
                    const SizedBox(height: 2),
                    Text(d['company_name'] as String, style: const TextStyle(fontSize: 11, color: AppColors.faint)),
                  ],
                  const SizedBox(height: 4),
                  Text('$done / $total өдөр', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct.toDouble(),
                      minHeight: 5,
                      backgroundColor: AppColors.bg,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    )),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => c.push('/diary/$id'),
                      child: const Text('Тэмдэглэл'),
                    )),
                    const SizedBox(width: 8),
                    if (status == 'active' && done >= total) Expanded(child: ElevatedButton(
                      onPressed: () => c.push('/review/$id'),
                      child: const Text('Үнэлэх'),
                    )),
                  ]),
                ])),
              );
            },
          ),
        );
      },
    );
  }
}

// ── SWIPE SCREEN (Company) ─────────────────────────────────────
class SwipeScreen extends StatefulWidget {
  final String postId;
  const SwipeScreen({super.key, required this.postId});
  @override State<SwipeScreen> createState() => _SState();
}
class _SState extends State<SwipeScreen> {
  final _svc = InternshipService();
  List<Map<String, dynamic>> _candidates = [];
  int _idx = 0; bool _loading = true;
  Offset _drag = Offset.zero;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final list = await _svc.getCandidates(widget.postId);
    if (!mounted) return;
    setState(() { _candidates = list; _loading = false; });
  }

  Future<void> _swipe(String status) async {
    if (_idx >= _candidates.length) return;
    final app = _candidates[_idx];
    try {
      if (status == 'accepted') {
        await _svc.acceptApplication(
          applicationId: app['id'] as String,
          studentId: app['student_id'] as String,
          postId: widget.postId,
          durationDays: 30,
        );
      } else {
        await _svc.rejectApplication(app['id'] as String);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() { _drag = Offset.zero; _idx++; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CV харах'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
          : _idx >= _candidates.length
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppColors.green),
                  SizedBox(height: 16),
                  Text('Бүх CV-г үзлээ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ]))
              : Column(children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('${_idx + 1} / ${_candidates.length}', style: const TextStyle(fontSize: 12, color: AppColors.faint))),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onPanUpdate: (d) => setState(() => _drag += d.delta),
                        onPanEnd: (_) {
                          if (_drag.dx > 80) { _swipe('accepted'); }
                          else if (_drag.dx < -80) { _swipe('rejected'); }
                          else { setState(() => _drag = Offset.zero); }
                        },
                        child: Transform.translate(
                          offset: Offset(_drag.dx, _drag.dy * 0.2),
                          child: Transform.rotate(
                            angle: _drag.dx * 0.006,
                            child: _buildCard(_candidates[_idx]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
                    child: Row(children: [
                      Expanded(child: OutlinedButton(onPressed: () => _swipe('rejected'), child: const Text('Үгүй'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: () => _swipe('accepted'), child: const Text('Урих ✓'))),
                    ]),
                  ),
                ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> app) {
    final name   = '${app['first_name'] ?? ''} ${app['last_name'] ?? ''}'.trim();
    final skills = (app['skills'] as List?)?.cast<String>() ?? [];
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        if (_drag.dx > 30) Align(alignment: Alignment.topRight,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(border: Border.all(color: AppColors.green, width: 2), borderRadius: BorderRadius.circular(8)),
            child: const Text('УРИХ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)))),
        if (_drag.dx < -30) Align(alignment: Alignment.topLeft,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(border: Border.all(color: AppColors.red, width: 2), borderRadius: BorderRadius.circular(8)),
            child: const Text('ҮГҮЙ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.red)))),
        AvatarCircle(name: name, size: 72),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('${app['university'] ?? ''} · ${app['major'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 14),
        if (skills.isNotEmpty) Wrap(spacing: 6, runSpacing: 6,
          children: skills.take(5).map((sk) =>
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
              child: Text(sk, style: const TextStyle(fontSize: 11, color: AppColors.muted)))).toList()),
        const SizedBox(height: 8),
        const Text('← шударж үзэх →', style: TextStyle(fontSize: 10, color: AppColors.faint)),
      ]),
    );
  }
}

// ── CREATE POST ───────────────────────────────────────────────
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override State<CreatePostScreen> createState() => _CPState();
}
class _CPState extends State<CreatePostScreen> {
  final _title    = TextEditingController();
  final _desc     = TextEditingController();
  final _loc      = TextEditingController();
  final _dur      = TextEditingController(text: '30');
  final _salary   = TextEditingController();
  final _skillCtrl= TextEditingController();
  bool _saving    = false;
  final _skills   = <String>[];

  @override Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final router    = GoRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Зар нийтлэх')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FieldLabel('Ажлын нэр'),
          TextField(controller: _title, decoration: const InputDecoration(hintText: 'Frontend хөгжүүлэгч...')),
          const FieldLabel('Тайлбар'),
          TextField(controller: _desc, maxLines: 3, decoration: const InputDecoration(hintText: 'Ажлын дэлгэрэнгүй...')),
          const FieldLabel('Байршил'),
          TextField(controller: _loc, decoration: const InputDecoration(hintText: 'Улаанбаатар / Онлайн')),
          const FieldLabel('Хугацаа (хоног)'),
          TextField(controller: _dur, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '30')),
          const FieldLabel('Цалин (заавал биш)'),
          TextField(controller: _salary, decoration: const InputDecoration(hintText: 'Сард 500,000₮')),
          const FieldLabel('Шаардлагатай мэдлэг'),
          Row(children: [
            Expanded(child: TextField(controller: _skillCtrl, decoration: const InputDecoration(hintText: 'React, Python...'))),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (_skillCtrl.text.isNotEmpty) {
                  setState(() { _skills.add(_skillCtrl.text.trim()); _skillCtrl.clear(); });
                }
              },
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
            ),
          ]),
          if (_skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6,
              children: _skills.map((s) => Chip(
                label: Text(s),
                onDeleted: () => setState(() => _skills.remove(s)),
                deleteIconColor: AppColors.muted,
                backgroundColor: AppColors.bg,
              )).toList()),
          ],
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Зар нийтлэх',
            loading: _saving,
            onTap: () async {
              setState(() => _saving = true);
              try {
                await InternshipService().createPost({
                  'title': _title.text.trim(),
                  'description': _desc.text.trim(),
                  'location': _loc.text.trim(),
                  'durationDays': int.tryParse(_dur.text) ?? 30,
                  'salary': _salary.text.trim().isEmpty ? null : _salary.text.trim(),
                  'requiredSkills': _skills,
                });
                if (!mounted) return;
                router.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Зар нийтлэгдлээ ✓'),
                    backgroundColor: AppColors.green, behavior: SnackBarBehavior.floating));
              } on ApiException catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text(e.message), backgroundColor: AppColors.red));
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  @override void dispose() {
    for (final c in [_title, _desc, _loc, _dur, _salary, _skillCtrl]) { c.dispose(); }
    super.dispose();
  }
}

// ── Post Detail Sheet ─────────────────────────────────────────
class _PostDetailSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onApply;
  const _PostDetailSheet({required this.post, required this.onApply});
  @override State<_PostDetailSheet> createState() => _PostDetailSheetState();
}
class _PostDetailSheetState extends State<_PostDetailSheet> {
  late Future<Map<String, dynamic>> _future;

  @override void initState() {
    super.initState();
    _future = ApiClient.get('/posts/${widget.post['id']}').then((r) => r as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (c, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
                }
                if (snap.hasError) {
                  return Center(child: Text(snap.error.toString(), style: const TextStyle(color: AppColors.muted)));
                }
                return _buildContent(snap.data!, ctrl);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity, height: 46,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); widget.onApply(); },
                  child: const Text('Хүсэлт илгээх'),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> d, ScrollController ctrl) {
    final skills   = (d['required_skills'] as List?)?.cast<String>() ?? [];
    final avgScore = (d['avg_score'] as num?)?.toDouble();
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          d['logo_url'] != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(d['logo_url'] as String, width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _CompanyAvatar(size: 56, name: d['company_name'] as String?)))
              : _CompanyAvatar(size: 56, name: d['company_name'] as String?),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['company_name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (d['industry'] != null)
              Text(d['industry'] as String, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            if (avgScore != null)
              Row(children: [
                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                const SizedBox(width: 3),
                Text(avgScore.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Text('(${d['review_count'] ?? 0} үнэлгээ)', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
          ])),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 16, children: [
          if (d['company_location'] != null)
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
              const SizedBox(width: 3),
              Text(d['company_location'] as String, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          if (d['website'] != null)
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.language_outlined, size: 13, color: AppColors.muted),
              const SizedBox(width: 3),
              Text(d['website'] as String, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            ]),
        ]),
        if ((d['company_description'] as String?)?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(d['company_description'] as String, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5)),
        ],
        const Divider(height: 28),
        Text(d['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 16, runSpacing: 4, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
            const SizedBox(width: 3),
            Text(d['location'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.muted),
            const SizedBox(width: 3),
            Text('${d['duration_days'] ?? 0} хоног', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
          if ((d['salary'] as String?)?.isNotEmpty == true)
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.payments_outlined, size: 13, color: AppColors.muted),
              const SizedBox(width: 3),
              Text(d['salary'] as String, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
        ]),
        if ((d['description'] as String?)?.isNotEmpty == true) ...[
          const SizedBox(height: 14),
          const Text('Тайлбар', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(d['description'] as String, style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5)),
        ],
        if (skills.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Шаардлагатай мэдлэг', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6,
            children: skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark)),
            )).toList()),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Apply Sheet ───────────────────────────────────────────────
class _ApplySheet extends StatefulWidget {
  final Map<String, dynamic> post;
  const _ApplySheet({required this.post});
  @override State<_ApplySheet> createState() => _ApplySheetState();
}
class _ApplySheetState extends State<_ApplySheet> {
  final _msgCtrl = TextEditingController();
  bool _loading = false;
  bool _done = false;
  late Future<Map<String, dynamic>?> _cvFuture;
  late String _uid;

  @override void initState() {
    super.initState();
    _uid = context.read<AuthProvider>().uid;
    _cvFuture = CVService().get(_uid);
  }

  @override void dispose() { _msgCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await InternshipService().apply(
        postId: widget.post['id'] as String,
        companyId: widget.post['company_id'] as String? ?? '',
        message: _msgCtrl.text.trim().isNotEmpty ? _msgCtrl.text.trim() : null,
      );
      if (mounted) setState(() { _done = true; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.read<AuthProvider>().profile;
    final name = '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}'.trim();
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          if (_done) _buildSuccess() else _buildForm(profile, name, ctrl),
        ]),
      ),
    );
  }

  Widget _buildSuccess() => Expanded(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.check_circle_rounded, size: 72, color: AppColors.green),
      const SizedBox(height: 16),
      const Text('Хүсэлт амжилттай илгээгдлээ!',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text('Компани таны мэдээлэлтэй танилцсаны дараа хариу өгнө.',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
          textAlign: TextAlign.center),
      ),
      const SizedBox(height: 32),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: SizedBox(
          width: double.infinity, height: 46,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Хаах'),
          ),
        ),
      ),
    ]),
  );

  Widget _buildForm(Map<String, dynamic>? profile, String name, ScrollController ctrl) => Expanded(
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Хүсэлт илгээх', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(widget.post['title'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        ]),
      ),
      const Divider(height: 20),
      Expanded(
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            Row(children: [
              AvatarCircle(name: name, size: 40),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (profile?['university'] != null)
                  Text('${profile!['university']} · ${profile['major'] ?? ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ])),
            ]),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>?>(
              future: _cvFuture,
              builder: (c, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 40,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)));
                }
                final cv = snap.data;
                if (cv == null) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'CV оруулаагүй байна. CV хэсгийг бөглөсний дараа хүсэлт илгээвэл компани таны мэдээллийг харах боломжтой.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF7A4500)))),
                    ]),
                  );
                }
                final skills = (cv['skills'] as List?)?.cast<String>() ?? [];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.attach_file_rounded, size: 16, color: AppColors.green),
                      SizedBox(width: 6),
                      Text('CV хавсаргагдсан',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green)),
                    ]),
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 4,
                        children: skills.take(5).map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                          child: Text(s, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        )).toList()),
                    ],
                  ]),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Нэмэлт мессеж (заавал биш)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _msgCtrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Компанид хэлэхийг хүсэж буй зүйлс...'),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity, height: 46,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Хүсэлт илгээх'),
            ),
          ),
        ),
      ),
    ]),
  );
}

// ── Company Avatar helper ─────────────────────────────────────
class _CompanyAvatar extends StatelessWidget {
  final double size;
  final String? name;
  const _CompanyAvatar({this.size = 48, this.name});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
    alignment: Alignment.center,
    child: Text(
      name?.isNotEmpty == true ? name![0].toUpperCase() : '?',
      style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
    ),
  );
}
