// lib/screens/internship/company_interns_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class CompanyInternsScreen extends StatefulWidget {
  const CompanyInternsScreen({super.key});
  @override State<CompanyInternsScreen> createState() => _CIState();
}

class _CIState extends State<CompanyInternsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  late String _uid;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _uid = context.read<AuthProvider>().uid;
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Дадлага', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.push('/company/post/create').then((_) {
                if (mounted) setState(() {});
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, size: 15, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Зар', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ]),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: TabBar(
            controller: _tab,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Зарууд'),
              Tab(text: 'Хүсэлтүүд'),
              Tab(text: 'Дадлагчид'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _PostsTab(companyId: _uid),
          _ApplicationsTab(companyId: _uid),
          _InternsTab(companyId: _uid),
        ],
      ),
    );
  }
}

// ── Tab 1: Posts ──────────────────────────────────────────────
class _PostsTab extends StatefulWidget {
  final String companyId;
  const _PostsTab({required this.companyId});
  @override State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;
  @override bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); }

  void _load() {
    setState(() { _future = InternshipService().getCompanyPosts(widget.companyId); });
  }

  void _editPost(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditPostSheet(post: post, onDone: _load),
    );
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Зар устгах', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Энэ зарыг устгах уу? Устгасан зарыг сэргээх боломжгүй.',
          style: TextStyle(fontSize: 13, color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Болих')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Устгах'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await InternshipService().deletePost(postId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Зар устгагдлаа'),
        backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
        }
        final posts = snap.data ?? [];
        if (posts.isEmpty) {
          return const _Empty(
            icon: Icons.work_outline_rounded,
            title: 'Зар байхгүй байна',
            sub: '"Зар" товч дарж шинэ зар нийтэлнэ үү',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (_, i) {
              final p      = posts[i];
              final count  = (p['applicant_count'] as num?)?.toInt() ?? 0;
              final active = p['is_active'] as bool? ?? true;
              return _Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primaryLight : AppColors.bg,
                        borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.work_rounded, size: 22, color: active ? AppColors.primary : AppColors.faint)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p['title'] as String? ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                      const SizedBox(height: 2),
                      Row(children: [
                        if (p['location'] != null) ...[
                          const Icon(Icons.location_on_outlined, size: 11, color: AppColors.muted),
                          const SizedBox(width: 2),
                          Text(p['location'] as String, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          const SizedBox(width: 8),
                        ],
                        const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.muted),
                        const SizedBox(width: 2),
                        Text('${p['duration_days'] ?? 0} өдөр', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      ]),
                    ])),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      _Chip(
                        count > 0 ? '$count хүсэлт' : 'Хүсэлт байхгүй',
                        bg: count > 0 ? AppColors.primaryLight : AppColors.bg,
                        fg: count > 0 ? AppColors.primary : AppColors.faint),
                      const SizedBox(height: 4),
                      _Chip(
                        active ? 'Идэвхтэй' : 'Хаалттай',
                        bg: active ? AppColors.tealLight : AppColors.bg,
                        fg: active ? AppColors.teal : AppColors.faint),
                    ]),
                  ]),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(children: [
                    if (count > 0) ...[
                      Expanded(child: _ActionBtn(
                        'CV харах', Icons.people_outline_rounded,
                        AppColors.teal, AppColors.tealLight,
                        () => context.push('/company/swipe/${p['id']}'))),
                      const SizedBox(width: 8),
                    ],
                    Expanded(child: _ActionBtn(
                      'Засах', Icons.edit_outlined,
                      AppColors.primary, AppColors.primaryLight,
                      () => _editPost(p))),
                    const SizedBox(width: 8),
                    Expanded(child: _ActionBtn(
                      'Устгах', Icons.delete_outline_rounded,
                      AppColors.red, AppColors.redLight,
                      () => _deletePost(p['id'] as String))),
                  ]),
                ]),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Tab 2: Applications ───────────────────────────────────────
class _ApplicationsTab extends StatefulWidget {
  final String companyId;
  const _ApplicationsTab({required this.companyId});
  @override State<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<_ApplicationsTab> with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;
  @override bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); }

  void _load() {
    setState(() {
      _future = InternshipService().getCompanyApplications(widget.companyId, status: 'pending');
    });
  }

  Future<void> _accept(Map<String, dynamic> app) async {
    final duration = await _askDuration(context);
    if (duration == null || !mounted) return;
    try {
      await InternshipService().acceptApplication(
        applicationId: app['id'] as String,
        studentId: app['student_id'] as String,
        postId: app['post_id'] as String,
        durationDays: duration,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Өргөдөл хүлээн авлаа ✓'),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
      ));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _reject(Map<String, dynamic> app, {String? reason}) async {
    try {
      await InternshipService().rejectApplication(app['id'] as String, reason: reason);
      if (!mounted) return;
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
    }
  }

  Future<int?> _askDuration(BuildContext ctx) {
    final ctrl = TextEditingController(text: '30');
    return showDialog<int>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Дадлагын хугацаа', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Хэдэн өдөр дадлага хийх вэ?', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 12),
          TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(suffixText: 'өдөр')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Болих')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, int.tryParse(ctrl.text) ?? 30),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Зөвшөөрөх'),
          ),
        ],
      ),
    );
  }

  void _openDetail(Map<String, dynamic> app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplicantDetailSheet(
        application: app,
        onAccept: () => _accept(app),
        onReject: (reason) => _reject(app, reason: reason),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
        }
        final apps = snap.data ?? [];
        if (apps.isEmpty) {
          return const _Empty(
            icon: Icons.inbox_outlined,
            title: 'Хүсэлт байхгүй байна',
            sub: 'Шинэ хүсэлт ирэхэд энд харагдана',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (_, i) {
              final a        = apps[i];
              final fn       = a['first_name'] as String? ?? '';
              final ln       = a['last_name']  as String? ?? '';
              final name     = '$ln $fn'.trim();
              final univ     = a['university'] as String? ?? '';
              final major    = a['major']      as String? ?? '';
              final skills   = (a['skills'] as List?)?.cast<String>() ?? [];
              final postTitle= a['post_title'] as String? ?? '';

              return _Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header row
                  Row(children: [
                    _InitialsAvatar(name: name),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                      Text('$univ · $major', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ])),
                    if (postTitle.isNotEmpty)
                      _Chip(postTitle, bg: AppColors.primaryLight, fg: AppColors.primary),
                  ]),
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6,
                      children: skills.take(4).map((s) => _Chip(s, bg: AppColors.bg, fg: AppColors.muted)).toList()),
                  ],
                  const SizedBox(height: 12),
                  // Action row
                  Row(children: [
                    Expanded(child: _ActionBtn('Дэлгэрэнгүй', Icons.person_outline_rounded,
                      AppColors.primary, AppColors.primaryLight, () => _openDetail(a))),
                    const SizedBox(width: 8),
                    Expanded(child: _ActionBtn('Татгалзах', Icons.close_rounded,
                      AppColors.red, AppColors.redLight, () => _openDetail(a))),
                    const SizedBox(width: 8),
                    Expanded(child: _ActionBtn('Зөвшөөрөх', Icons.check_rounded,
                      Colors.white, AppColors.teal, () => _accept(a))),
                  ]),
                ]),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Tab 3: Active / Completed Interns ─────────────────────────
class _InternsTab extends StatefulWidget {
  final String companyId;
  const _InternsTab({required this.companyId});
  @override State<_InternsTab> createState() => _InternsTabState();
}

class _InternsTabState extends State<_InternsTab> with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;
  @override bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); }

  void _load() {
    setState(() { _future = InternTrackingService().getCompanyInternships(widget.companyId); });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
        }
        final all        = snap.data ?? [];
        final active     = all.where((d) => d['status'] == 'active').toList();
        final completed  = all.where((d) => d['status'] == 'completed').toList();
        final terminated = all.where((d) => d['status'] == 'terminated').toList();
        if (all.isEmpty) {
          return const _Empty(
            icon: Icons.people_outline_rounded,
            title: 'Дадлагачид байхгүй байна',
            sub: 'Хүсэлт зөвшөөрснөөр дадлагачид энд харагдана',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                _SectionHeader('Одоо дадлага хийж байгаа (${active.length})'),
                ...active.map((d) => _InternCard(data: d, isActive: true, onRefresh: _load)),
                const SizedBox(height: 8),
              ],
              if (completed.isNotEmpty) ...[
                _SectionHeader('Дадлага дууссан (${completed.length})'),
                ...completed.map((d) => _InternCard(data: d, isActive: false, onRefresh: _load)),
              ],
              if (terminated.isNotEmpty) ...[
                _SectionHeader('Цуцлагдсан (${terminated.length})'),
                ...terminated.map((d) => _InternCard(data: d, isActive: false, onRefresh: _load)),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ── Intern card ───────────────────────────────────────────────
class _InternCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isActive;
  final VoidCallback onRefresh;
  const _InternCard({required this.data, required this.isActive, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final d            = data;
    final firstName    = d['first_name'] as String? ?? '';
    final lastName     = d['last_name']  as String? ?? '';
    final name         = '$lastName $firstName'.trim();
    final title        = d['title']      as String? ?? '';
    final internId     = d['id']         as String;
    final studentId    = d['student_id'] as String? ?? '';
    final completed    = (d['completed_days'] as num?)?.toInt() ?? 0;
    final total        = (d['duration_days']  as num?)?.toInt() ?? 1;
    final progress     = (completed / total).clamp(0.0, 1.0);
    final isTerminated = d['status'] == 'terminated';
    final photo        = d['photo'] as String?;
    final univ         = d['university'] as String? ?? '';
    final major        = d['major']      as String? ?? '';

    return _Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header row
        Row(children: [
          _StudentPhoto(photo: photo, name: name, size: 44),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            if (univ.isNotEmpty)
              Text(univ + (major.isNotEmpty ? ' · $major' : ''),
                style: const TextStyle(fontSize: 10, color: AppColors.faint)),
          ])),
          if (isTerminated)
            const _Chip('Цуцлагдсан', bg: AppColors.redLight, fg: AppColors.red)
          else if (!isActive)
            const _Chip('Дууссан', bg: AppColors.tealLight, fg: AppColors.teal)
          else
            GestureDetector(
              onTap: () => _openDetail(context, d),
              child: const _Chip('Дэлгэрэнгүй ▼', bg: AppColors.primaryLight, fg: AppColors.primary),
            ),
        ]),

        // Progress (active only)
        if (isActive && !isTerminated) ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$completed / $total өдөр',
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            Text('${(progress * 100).round()}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress, minHeight: 5,
              backgroundColor: AppColors.bg, color: AppColors.teal)),
        ],

        // Termination reason
        if (isTerminated && (d['termination_reason'] as String? ?? '').isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Цуцлалтын шалтгаан', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.red)),
              const SizedBox(height: 4),
              Text(d['termination_reason'] as String, style: const TextStyle(fontSize: 11, color: AppColors.text)),
            ]),
          ),
        ],

        // Action buttons
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 10),
        if (isActive && !isTerminated)
          Row(children: [
            Expanded(child: _ActionBtn(
              'Дэлгэрэнгүй', Icons.person_outline_rounded,
              AppColors.primary, AppColors.primaryLight,
              () => _openDetail(context, d))),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn(
              'Дуусгах', Icons.stop_circle_outlined,
              AppColors.red, AppColors.redLight,
              () => _showTerminate(context, internId))),
          ])
        else
          Row(children: [
            Expanded(child: _ActionBtn(
              'Дэлгэрэнгүй', Icons.person_outline_rounded,
              AppColors.primary, AppColors.primaryLight,
              () => _openDetail(context, d))),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn(
              'Оюутан үнэлэх', Icons.star_outline_rounded,
              AppColors.amber, AppColors.amberLight,
              () => _showRateStudent(context, internId, studentId, name))),
          ]),
      ]),
    );
  }

  void _openDetail(BuildContext ctx, Map<String, dynamic> d) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InternDetailSheet(data: d),
    );
  }

  void _showTerminate(BuildContext ctx, String internId) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TerminateSheet(internshipId: internId, onDone: onRefresh),
    );
  }

  void _showRateStudent(BuildContext ctx, String internId, String studentId, String studentName) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RateStudentSheet(
        internshipId: internId, studentId: studentId,
        studentName: studentName, onDone: onRefresh),
    );
  }
}

// ── Intern detail sheet ───────────────────────────────────────
class _InternDetailSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  const _InternDetailSheet({required this.data});
  @override State<_InternDetailSheet> createState() => _InternDetailSheetState();
}

class _InternDetailSheetState extends State<_InternDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Future<Map<String, dynamic>?> _studentFuture;
  late Future<Map<String, dynamic>?> _cvFuture;
  late Future<List<Map<String, dynamic>>> _diaryFuture;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    final sid      = widget.data['student_id'] as String? ?? '';
    final internId = widget.data['id']         as String? ?? '';
    _studentFuture = ApiClient.get('/students/$sid').then((v) => v as Map<String, dynamic>?).catchError((_) => null);
    _cvFuture      = CVService().get(sid);
    _diaryFuture   = DiaryService().getEntries(internId);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d          = widget.data;
    final firstName  = d['first_name'] as String? ?? '';
    final lastName   = d['last_name']  as String? ?? '';
    final name       = '$lastName $firstName'.trim();
    final title      = d['title']      as String? ?? '';
    final univ       = d['university'] as String? ?? '';
    final major      = d['major']      as String? ?? '';
    final photo      = d['photo']      as String?;
    final completed  = (d['completed_days'] as num?)?.toInt() ?? 0;
    final total      = (d['duration_days']  as num?)?.toInt() ?? 1;
    final progress   = (completed / total).clamp(0.0, 1.0);
    final isActive   = d['status'] == 'active';

    return DraggableScrollableSheet(
      initialChildSize: 0.92, maxChildSize: 0.97, minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              _StudentPhoto(photo: photo, name: name, size: 52),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                if (title.isNotEmpty)
                  Text(title, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                if (univ.isNotEmpty || major.isNotEmpty)
                  Text([univ, major].where((s) => s.isNotEmpty).join(' · '),
                    style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ])),
              _Chip(
                isActive ? 'Идэвхтэй' : 'Дууссан',
                bg: isActive ? AppColors.tealLight : AppColors.bg,
                fg: isActive ? AppColors.teal : AppColors.muted),
            ]),
          ),

          // Progress bar
          if (isActive) Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('$completed / $total өдөр',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                Text('${(progress * 100).round()}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress, minHeight: 6,
                  backgroundColor: AppColors.bg, color: AppColors.teal)),
            ]),
          ),

          const SizedBox(height: 8),
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [Tab(text: 'Тэмдэглэл'), Tab(text: 'Профайл'), Tab(text: 'CV')],
          ),

          Expanded(child: TabBarView(controller: _tab, children: [
            _FullDiaryTab(future: _diaryFuture),
            _InternProfileTab(studentFuture: _studentFuture, internData: d),
            _CvTabContent(cvFuture: _cvFuture),
          ])),

          // Bottom: message button
          const SizedBox.shrink(),
        ]),
      ),
    );
  }
}

// ── Full diary tab ─────────────────────────────────────────────
class _FullDiaryTab extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  const _FullDiaryTab({required this.future});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: future,
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
      }
      final entries = snap.data ?? [];
      if (entries.isEmpty) {
        return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.book_outlined, size: 48, color: AppColors.faint),
          SizedBox(height: 12),
          Text('Тэмдэглэл байхгүй байна', style: TextStyle(color: AppColors.muted)),
          SizedBox(height: 4),
          Text('Оюутан дадлагын тэмдэглэлээ бичээгүй байна',
            style: TextStyle(fontSize: 11, color: AppColors.faint)),
        ]));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (_, i) {
          final e      = entries[i];
          final isLast = i == entries.length - 1;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(width: 10, height: 10,
                decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
              if (!isLast) Container(width: 2, height: 80, color: AppColors.border),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(6)),
                    child: Text('${e['day_number']}-р өдөр',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teal))),
                  if ((e['mood'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(e['mood'] as String, style: const TextStyle(fontSize: 16)),
                  ],
                ]),
                const SizedBox(height: 8),
                Text(e['work_done'] as String? ?? '',
                  style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.5)),
                if ((e['interactions'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Харилцаа: ${e['interactions']}',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4)),
                ],
                if ((e['categories'] as List? ?? []).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 5, runSpacing: 4,
                    children: (e['categories'] as List).cast<String>().map((c) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4)),
                        child: Text(c, style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      )).toList()),
                ],
              ]),
            )),
          ]);
        },
      );
    },
  );
}

// ── Intern profile tab ─────────────────────────────────────────
class _InternProfileTab extends StatelessWidget {
  final Future<Map<String, dynamic>?> studentFuture;
  final Map<String, dynamic> internData;
  const _InternProfileTab({required this.studentFuture, required this.internData});

  @override
  Widget build(BuildContext context) {
    final d    = internData;
    final univ = d['university'] as String? ?? '';
    final major = d['major']    as String? ?? '';

    return FutureBuilder<Map<String, dynamic>?>(
      future: studentFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
        }
        final s      = snap.data ?? {};
        final phone  = s['phone']  as String? ?? '';
        final gpa    = (s['gpa'] ?? '').toString();
        final bio    = s['bio']    as String? ?? '';
        final skills = (s['skills'] as List?)?.cast<String>() ?? [];
        final email  = s['email']  as String? ?? '';
        final uUniv  = s['university'] as String? ?? univ;
        final uMajor = s['major']      as String? ?? major;
        final year   = s['year'];

        return ListView(padding: const EdgeInsets.all(16), children: [
          _DL('ХУВИЙН МЭДЭЭЛЭЛ'),
          _InfoBox(children: [
            _DRow(Icons.school_outlined,    'Сургууль', uUniv),
            _DRow(Icons.menu_book_outlined, 'Мэргэжил', uMajor),
            if (year != null) _DRow(Icons.class_outlined, 'Курс', '$year-р курс'),
            if (phone.isNotEmpty) _DRow(Icons.phone_outlined, 'Утас', phone),
            if (email.isNotEmpty) _DRow(Icons.email_outlined, 'Имэйл', email),
            if (gpa.isNotEmpty && gpa != 'null') _DRow(Icons.grade_outlined, 'GPA', gpa),
          ]),

          if (bio.isNotEmpty) ...[
            _DL('ТАНИЛЦУУЛГА'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
              child: Text(bio, style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.6))),
            const SizedBox(height: 14),
          ],

          if (skills.isNotEmpty) ...[
            _DL('УР ЧАДВАР'),
            Wrap(spacing: 7, runSpacing: 6,
              children: skills.map((sk) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: Text(sk, style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
              )).toList()),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 20),
        ]);
      },
    );
  }
}

// ── Student photo avatar ───────────────────────────────────────
class _StudentPhoto extends StatelessWidget {
  final String? photo;
  final String name;
  final double size;
  const _StudentPhoto({required this.name, this.photo, required this.size});

  @override
  Widget build(BuildContext context) {
    if (photo != null && photo!.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(base64Decode(photo!)));
      } catch (_) {}
    }
    const bgs = [AppColors.blueLight, AppColors.tealLight, AppColors.purpleLight, AppColors.primaryLight];
    const fgs = [AppColors.blue, AppColors.teal, AppColors.purple, AppColors.primary];
    final idx  = name.isNotEmpty ? name.codeUnitAt(0) % 4 : 0;
    final init = name.length >= 2 ? name.substring(0, 2) : name;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgs[idx],
      child: Text(init, style: TextStyle(fontSize: size * 0.26, fontWeight: FontWeight.w600, color: fgs[idx])));
  }
}

// ── Shared small widgets ──────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  const _Card({required this.child, this.margin = EdgeInsets.zero, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _Chip(this.label, {required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color fg, bg;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.icon, this.fg, this.bg, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 15, color: fg),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      ]),
    ),
  );
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});
  static const _bgs = [AppColors.blueLight, AppColors.tealLight, AppColors.purpleLight, AppColors.primaryLight];
  static const _fgs = [AppColors.blue, AppColors.teal, AppColors.purple, AppColors.primary];

  @override
  Widget build(BuildContext context) {
    final i    = name.isNotEmpty ? name.codeUnitAt(0) % 4 : 0;
    final init = name.length >= 2 ? name.substring(0, 2) : name;
    return CircleAvatar(radius: 20, backgroundColor: _bgs[i],
      child: Text(init, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _fgs[i])));
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
  );
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  const _Empty({required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 64, height: 64,
          decoration: const BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
          child: Icon(icon, size: 30, color: AppColors.faint)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
          textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
          textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Terminate Sheet ───────────────────────────────────────────
class _TerminateSheet extends StatefulWidget {
  final String internshipId;
  final VoidCallback onDone;
  const _TerminateSheet({required this.internshipId, required this.onDone});
  @override State<_TerminateSheet> createState() => _TerminateSheetState();
}
class _TerminateSheetState extends State<_TerminateSheet> {
  final _reason = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 44, height: 4,
        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 20),
          SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Дадлага хугацаанаас өмнө дуусгах', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.red)),
            Text('Гэрээнд тусгагдсан нөхцөл зөрчигдсөн тохиолдолд', style: TextStyle(fontSize: 11, color: AppColors.red)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      const Text('Шалтгаан', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        controller: _reason,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Дадлагыг дуусгах шалтгаанаа дэлгэрэнгүй бичнэ үү. '
              'Жишээ нь: гэрээний нөхцөл зөрчих, чанаргүй ажил...',
        ),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Болих'),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(
          onPressed: _saving ? null : _terminate,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Дуусгах'),
        )),
      ]),
    ]),
  );

  Future<void> _terminate() async {
    if (_reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Шалтгаан бичнэ үү'), backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _saving = true);
    try {
      await InternshipService().terminateInternship(widget.internshipId, _reason.text.trim());
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override void dispose() { _reason.dispose(); super.dispose(); }
}

// ── Rate Student Sheet ────────────────────────────────────────
class _RateStudentSheet extends StatefulWidget {
  final String internshipId, studentId, studentName;
  final VoidCallback onDone;
  const _RateStudentSheet({
    required this.internshipId, required this.studentId,
    required this.studentName, required this.onDone,
  });
  @override State<_RateStudentSheet> createState() => _RateStudentSheetState();
}
class _RateStudentSheetState extends State<_RateStudentSheet> {
  final _scores = <String, int>{'work': 0, 'attitude': 0, 'punctuality': 0, 'learning': 0};
  bool? _wouldRehire;
  final _comment = TextEditingController();
  bool _saving = false, _done = false;

  static const _criteria = [
    ('work',        'Ажлын гүйцэтгэл'),
    ('attitude',    'Хандлага ба хамт олонтой харилцаа'),
    ('punctuality', 'Цаг баримтлал'),
    ('learning',    'Суралцах чадвар'),
  ];

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 64, height: 64,
            decoration: const BoxDecoration(color: AppColors.greenLight, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 32, color: AppColors.green)),
          const SizedBox(height: 16),
          const Text('Үнэлгээ илгээгдлээ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Баярлалаа! Таны үнэлгээ оюутанд илгээгдлээ.',
            style: TextStyle(fontSize: 13, color: AppColors.muted), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); widget.onDone(); },
            child: const Text('Хаах'),
          ),
        ]),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 44, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.star_rounded, color: AppColors.amber, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Оюутан үнэлэх', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(widget.studentName, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ])),
        ]),
        const SizedBox(height: 20),

        ..._criteria.map((cr) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cr.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _scores[cr.$1] = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  i < (_scores[cr.$1] ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 32,
                  color: i < (_scores[cr.$1] ?? 0) ? const Color(0xFFF59E0B) : AppColors.faint,
                ),
              ),
            ))),
          ]),
        )),

        const Text('Дахин энэ оюутантай хамтрах уу?',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ynBtn('Тийм', _wouldRehire == true, () => setState(() => _wouldRehire = true))),
          const SizedBox(width: 10),
          Expanded(child: _ynBtn('Үгүй', _wouldRehire == false, () => setState(() => _wouldRehire = false))),
        ]),

        const SizedBox(height: 16),
        const Text('Сэтгэгдэл (заавал биш)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _comment, maxLines: 3,
          decoration: const InputDecoration(hintText: 'Оюутны ажлын талаар нэмэлт сэтгэгдэл...'),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Үнэлгээ илгээх'),
        ),
        const SizedBox(height: 8),
      ])),
    );
  }

  Widget _ynBtn(String l, bool on, VoidCallback t) => GestureDetector(
    onTap: t,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: on ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: on ? AppColors.primary : AppColors.border, width: on ? 1.5 : 0.5),
      ),
      child: Text(l, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: on ? Colors.white : AppColors.muted)),
    ),
  );

  Future<void> _submit() async {
    if (_scores.values.any((v) => v == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Бүх үнэлгээг дүүргэнэ үү'),
        backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
      return;
    }
    if (_wouldRehire == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Дахин хамтрах эсэхийг сонгоно уу'),
        backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _saving = true);
    try {
      await StudentReviewService().submit(
        internshipId: widget.internshipId,
        studentId: widget.studentId,
        work: _scores['work']!,
        attitude: _scores['attitude']!,
        punctuality: _scores['punctuality']!,
        learning: _scores['learning']!,
        wouldRehire: _wouldRehire!,
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      );
      if (mounted) setState(() => _done = true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override void dispose() { _comment.dispose(); super.dispose(); }
}

// ═══════════════════════════════════════════════════════════════
// APPLICANT DETAIL SHEET — 4 tabs
// ═══════════════════════════════════════════════════════════════
class _ApplicantDetailSheet extends StatefulWidget {
  final Map<String, dynamic> application;
  final VoidCallback onAccept;
  final void Function(String? reason) onReject;
  const _ApplicantDetailSheet({required this.application, required this.onAccept, required this.onReject});
  @override State<_ApplicantDetailSheet> createState() => _ApplicantDetailSheetState();
}

class _ApplicantDetailSheetState extends State<_ApplicantDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Future<Map<String, dynamic>?> _cvFuture;
  late Future<List<Map<String, dynamic>>> _scheduleFuture;
  late Future<Map<String, dynamic>?> _studentFuture;
  late Future<Map<String, dynamic>?> _assessmentFuture;
  bool _showRejectInput = false;
  final _rejectCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    final sid   = widget.application['student_id'] as String? ?? '';
    final appId = widget.application['id']         as String? ?? '';
    _cvFuture          = CVService().get(sid);
    _scheduleFuture    = ScheduleService().getSchedule(sid);
    _studentFuture     = ApiClient.get('/students/$sid').then((v) => v as Map<String, dynamic>?);
    _assessmentFuture  = AssessmentService().getAnswers(appId);
  }

  @override
  void dispose() { _tab.dispose(); _rejectCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final a   = widget.application;
    final fn  = a['first_name'] as String? ?? '';
    final ln  = a['last_name']  as String? ?? '';
    final name = '$ln $fn'.trim();
    final univ  = a['university'] as String? ?? '';
    final major = a['major']      as String? ?? '';
    final year  = a['year'];
    final postTitle = a['post_title'] as String? ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.92, maxChildSize: 0.97, minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              _InitialsAvatar(name: name),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text(
                  [univ, major, year != null ? '$year-р курс' : null]
                    .where((s) => s != null && s.isNotEmpty).join(' · '),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ])),
              if (postTitle.isNotEmpty)
                _Chip(postTitle, bg: AppColors.primaryLight, fg: AppColors.primary),
            ]),
          ),

          // Tabs
          const SizedBox(height: 8),
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [Tab(text: 'Профайл'), Tab(text: 'CV'), Tab(text: 'Хуваарь'), Tab(text: 'Шалгалт')],
          ),

          // Content
          Expanded(
            child: TabBarView(controller: _tab, children: [
              _ProfileTabContent(application: a, studentFuture: _studentFuture),
              _CvTabContent(cvFuture: _cvFuture),
              _ScheduleTabContent(scheduleFuture: _scheduleFuture),
              _AssessmentAnswersTab(assessmentFuture: _assessmentFuture),
            ]),
          ),

          // Bottom actions
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
            child: _showRejectInput
              ? Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                      controller: _rejectCtrl, maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Татгалзсан шалтгаан (заавал биш)...')),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: OutlinedButton(
                        onPressed: () => setState(() { _showRejectInput = false; _rejectCtrl.clear(); }),
                        child: const Text('Болих'))),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton(
                        onPressed: () {
                          final r = _rejectCtrl.text.trim().isEmpty ? null : _rejectCtrl.text.trim();
                          Navigator.pop(context);
                          widget.onReject(r);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
                        child: const Text('Татгалзах'))),
                    ]),
                  ]))
              : Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // Message button
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => setState(() => _showRejectInput = true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red),
                          padding: const EdgeInsets.symmetric(vertical: 13)),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Татгалзах', style: TextStyle(fontWeight: FontWeight.w600)))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton.icon(
                        onPressed: () { Navigator.pop(context); widget.onAccept(); },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13)),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Зөвшөөрөх', style: TextStyle(fontWeight: FontWeight.w600)))),
                    ]),
                  ])),
          ),
        ]),
      ),
    );
  }
}

// ── Tab 1: Profile ─────────────────────────────────────────────
class _ProfileTabContent extends StatelessWidget {
  final Map<String, dynamic> application;
  final Future<Map<String, dynamic>?> studentFuture;
  const _ProfileTabContent({required this.application, required this.studentFuture});

  @override
  Widget build(BuildContext context) {
    final a       = application;
    final bio     = a['bio']      as String? ?? '';
    final skills  = (a['skills'] as List?)?.cast<String>() ?? [];
    final message = a['message'] as String? ?? '';
    final univ    = a['university'] as String? ?? '';
    final major   = a['major']      as String? ?? '';
    final year    = a['year'];

    return ListView(padding: const EdgeInsets.all(16), children: [
      _DL('ХУВИЙН МЭДЭЭЛЭЛ'),
      _InfoBox(children: [
        _DRow(Icons.school_outlined,   'Сургууль', univ),
        _DRow(Icons.menu_book_outlined, 'Мэргэжил', major),
        if (year != null) _DRow(Icons.class_outlined, 'Курс', '$year-р курс'),
      ]),

      FutureBuilder<Map<String, dynamic>?>(
        future: studentFuture,
        builder: (_, snap) {
          final s = snap.data;
          if (s == null) return const SizedBox.shrink();
          final phone = s['phone'] as String? ?? '';
          final gpa   = (s['gpa']   ?? '').toString();
          if (phone.isEmpty && gpa.isEmpty) return const SizedBox.shrink();
          return _InfoBox(children: [
            _DRow(Icons.phone_outlined, 'Утас', phone),
            _DRow(Icons.grade_outlined, 'GPA',  gpa),
          ]);
        },
      ),

      if (bio.isNotEmpty) ...[
        _DL('ТАНИЛЦУУЛГА'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
          child: Text(bio, style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.6))),
        const SizedBox(height: 14),
      ],

      if (skills.isNotEmpty) ...[
        _DL('УР ЧАДВАР'),
        Wrap(spacing: 7, runSpacing: 6,
          children: skills.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Text(s, style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
          )).toList()),
        const SizedBox(height: 14),
      ],

      if (message.isNotEmpty) ...[
        _DL('ӨРГӨДЛИЙН МЭДЭГДЭЛ'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.format_quote_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(message,
              style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.6))),
          ])),
        const SizedBox(height: 14),
      ],

      // ── GitHub ─────────────────────────────────────────────
      if ((a['github_link'] as String?)?.isNotEmpty == true) ...[
        _DL('GITHUB'),
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.code_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(
              a['github_link'] as String,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ],

      // ── Portfolio ──────────────────────────────────────────
      if ((a['portfolio'] as List?)?.isNotEmpty == true) ...[
        _DL('БҮТЭЭЛҮҮД'),
        ...(a['portfolio'] as List).cast<Map<String, dynamic>>().map((p) {
          final pName = p['name'] as String? ?? '';
          final pUrl  = p['url']  as String? ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (pName.isNotEmpty)
                Text(pName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
              if (pUrl.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.link_rounded, size: 13, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Expanded(child: Text(pUrl,
                    style: const TextStyle(fontSize: 11, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ]),
          );
        }),
      ],

      const SizedBox(height: 20),
    ]);
  }
}

// ── Tab 2: CV ──────────────────────────────────────────────────
class _CvTabContent extends StatelessWidget {
  final Future<Map<String, dynamic>?> cvFuture;
  const _CvTabContent({required this.cvFuture});

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: cvFuture,
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
      }
      if (snap.data == null) {
        return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.description_outlined, size: 48, color: AppColors.faint),
          SizedBox(height: 12),
          Text('CV оруулаагүй байна', style: TextStyle(color: AppColors.muted)),
        ]));
      }
      return _CVContent(cv: snap.data!);
    },
  );
}

// ── Tab 3: Schedule ────────────────────────────────────────────
class _ScheduleTabContent extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> scheduleFuture;
  const _ScheduleTabContent({required this.scheduleFuture});

  static const _days = ['Даваа','Мягмар','Лхагва','Пүрэв','Баасан','Бямба','Ням'];
  static const _colors = [AppColors.primary, AppColors.teal, AppColors.purple, AppColors.amber, AppColors.green, AppColors.red];

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: scheduleFuture,
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
      }
      final items = snap.data ?? [];
      if (items.isEmpty) {
        return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.faint),
          SizedBox(height: 12),
          Text('Хуваарь оруулаагүй байна', style: TextStyle(color: AppColors.muted)),
        ]));
      }
      final byDay = <int, List<Map<String, dynamic>>>{};
      for (final it in items) {
        final d = (it['day'] as num?)?.toInt() ?? 0;
        byDay.putIfAbsent(d, () => []).add(it);
      }
      return ListView(padding: const EdgeInsets.all(16), children: [
        for (final day in (byDay.keys.toList()..sort())) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(_days[day],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted))),
          ...byDay[day]!.map((it) {
            final sh   = (it['startHour'] as num?)?.toInt() ?? 8;
            final sm   = (it['startMin']  as num?)?.toInt() ?? 0;
            final eh   = (it['endHour']   as num?)?.toInt() ?? 9;
            final em   = (it['endMin']    as num?)?.toInt() ?? 0;
            final subj = it['subject'] as String? ?? '';
            final room = it['room']    as String? ?? '';
            final teacher = it['teacher'] as String? ?? '';
            final type = it['type']    as String? ?? '';
            final col  = _colors[subj.hashCode.abs() % _colors.length];
            final time = '${_f(sh, sm)} – ${_f(eh, em)}'
              '${room.isNotEmpty ? "  ·  $room" : ""}'
              '${teacher.isNotEmpty ? "  ·  $teacher" : ""}';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: col.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: col, width: 3))),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(subj, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(time, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ])),
                if (type.isNotEmpty) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: col.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: col))),
              ]),
            );
          }),
          const SizedBox(height: 4),
        ],
      ]);
    },
  );

  String _f(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}


// ── CV content renderer ────────────────────────────────────────
class _CVContent extends StatelessWidget {
  final Map<String, dynamic> cv;
  const _CVContent({required this.cv});

  @override
  Widget build(BuildContext context) {
    final summary  = cv['summary']      as String? ?? '';
    final skills   = (cv['skills']      as List?)?.cast<String>() ?? [];
    final exps     = (cv['experiences'] as List?) ?? [];
    final grades   = (cv['grades']      as List?) ?? [];
    final langs    = (cv['languages']   as List?)?.cast<String>() ?? [];
    final certs    = (cv['certs']       as List?)?.cast<String>() ?? [];
    final univ     = cv['university']   as String? ?? '';
    final major    = cv['major']        as String? ?? '';
    final year     = cv['year']?.toString() ?? '';
    final gpa      = cv['gpa']          as String? ?? '';
    final email    = cv['email']        as String? ?? '';
    final phone    = cv['phone']        as String? ?? '';
    final country  = cv['country']      as String? ?? '';
    final dob      = cv['dob']          as String? ?? '';

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (email.isNotEmpty || phone.isNotEmpty || country.isNotEmpty || dob.isNotEmpty) ...[
        _DL('ХОЛБОО БАРИХ'),
        _InfoBox(children: [
          if (email.isNotEmpty)   _DRow(Icons.email_outlined,          'Имэйл',    email),
          if (phone.isNotEmpty)   _DRow(Icons.phone_outlined,          'Утас',     phone),
          if (country.isNotEmpty) _DRow(Icons.location_on_outlined,    'Улс/Хот',  country),
          if (dob.isNotEmpty)     _DRow(Icons.cake_outlined,           'Төрсөн',   dob.length >= 10 ? dob.substring(0, 10) : dob),
        ]),
      ],

      if (univ.isNotEmpty) ...[
        _DL('БОЛОВСРОЛ'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(univ, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            if (major.isNotEmpty) Text(major, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              if (year.isNotEmpty) _MiniChip('$year-р курс', AppColors.primary),
              if (gpa.isNotEmpty)  _MiniChip('GPA: $gpa',    AppColors.teal),
            ]),
          ])),
        const SizedBox(height: 14),
      ],

      if (grades.isNotEmpty) ...[
        const _DL('ХИЧЭЭЛИЙН ДҮН'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: grades.cast<Map>().asMap().entries.map((e) {
              final g = e.value;
              final isLast = e.key == grades.length - 1;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(children: [
                    Expanded(child: Text(
                      g['subject']?.toString() ?? '',
                      style: const TextStyle(fontSize: 12, color: AppColors.text),
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        g['grade']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                      ),
                    ),
                  ]),
                ),
                if (!isLast) const Divider(height: 1, indent: 12, endIndent: 12),
              ]);
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
      ],

      if (summary.isNotEmpty) ...[
        _DL('ТАНИЛЦУУЛГА'),
        Text(summary, style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.6)),
        const SizedBox(height: 14),
      ],

      if (exps.isNotEmpty) ...[
        _DL('ТУРШЛАГА'),
        ...exps.cast<Map>().map((e) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.amberLight, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.25))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(e['role'] as String? ?? '',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
              Text(e['period'] as String? ?? '',
                style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            ]),
            if ((e['company'] as String? ?? '').isNotEmpty)
              Text(e['company'] as String,
                style: const TextStyle(fontSize: 11, color: AppColors.amber, fontWeight: FontWeight.w600)),
            if ((e['desc'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(e['desc'] as String,
                style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.5)),
            ],
          ]))),
      ],

      if (skills.isNotEmpty) ...[
        _DL('УР ЧАДВАР'),
        Wrap(spacing: 7, runSpacing: 6,
          children: skills.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Text(s, style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
          )).toList()),
        const SizedBox(height: 14),
      ],

      if (langs.isNotEmpty) ...[
        _DL('ХЭЛ'),
        Wrap(spacing: 7, runSpacing: 6,
          children: langs.map((l) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(8)),
            child: Text(l, style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w500)),
          )).toList()),
        const SizedBox(height: 14),
      ],

      if (certs.isNotEmpty) ...[
        _DL('ГЭРЧИЛГЭЭ'),
        ...certs.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            const Icon(Icons.military_tech_outlined, size: 16, color: AppColors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text(c, style: const TextStyle(fontSize: 13, color: AppColors.text))),
          ]))),
      ],
      const SizedBox(height: 20),
    ]);
  }
}

// ── Shared small helpers ───────────────────────────────────────
class _DL extends StatelessWidget {                             // section divider label
  final String text;
  const _DL(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.8)));
}

class _InfoBox extends StatelessWidget {
  final List<Widget> children;
  const _InfoBox({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
    child: Column(children: children));
}

class _DRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _DRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(width: 6),
        Expanded(child: Text(value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text))),
      ]));
  }
}

class _MiniChip extends StatelessWidget {
  final String label; final Color color;
  const _MiniChip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)));
}

// ── Edit Post Sheet ───────────────────────────────────────────
class _EditPostSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onDone;
  const _EditPostSheet({required this.post, required this.onDone});
  @override State<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<_EditPostSheet> {
  late final TextEditingController _title, _desc, _loc, _dur, _salary, _skillCtrl;
  late List<String> _skills;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _title     = TextEditingController(text: p['title']       as String? ?? '');
    _desc      = TextEditingController(text: p['description'] as String? ?? '');
    _loc       = TextEditingController(text: p['location']    as String? ?? '');
    _dur       = TextEditingController(text: (p['duration_days'] ?? 30).toString());
    _salary    = TextEditingController(text: p['salary']      as String? ?? '');
    _skillCtrl = TextEditingController();
    _skills    = ((p['required_skills'] as List?)?.cast<String>() ?? []).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 44, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        const Text('Зар засах', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),

        _Label('Ажлын нэр'),
        TextField(controller: _title, decoration: const InputDecoration(hintText: 'Frontend хөгжүүлэгч...')),
        const SizedBox(height: 12),

        _Label('Тайлбар'),
        TextField(controller: _desc, maxLines: 3, decoration: const InputDecoration(hintText: 'Ажлын дэлгэрэнгүй...')),
        const SizedBox(height: 12),

        _Label('Байршил'),
        TextField(controller: _loc, decoration: const InputDecoration(hintText: 'Улаанбаатар / Онлайн')),
        const SizedBox(height: 12),

        _Label('Хугацаа (хоног)'),
        TextField(controller: _dur, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '30')),
        const SizedBox(height: 12),

        _Label('Цалин (заавал биш)'),
        TextField(controller: _salary, decoration: const InputDecoration(hintText: 'Сард 500,000₮')),
        const SizedBox(height: 12),

        _Label('Шаардлагатай мэдлэг'),
        Row(children: [
          Expanded(child: TextField(controller: _skillCtrl, decoration: const InputDecoration(hintText: 'React, Python...'))),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              if (_skillCtrl.text.trim().isNotEmpty) {
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
              label: Text(s, style: const TextStyle(fontSize: 12)),
              onDeleted: () => setState(() => _skills.remove(s)),
              deleteIconColor: AppColors.muted,
              backgroundColor: AppColors.bg,
            )).toList()),
        ],
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Болих'),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Хадгалах'),
          )),
        ]),
        const SizedBox(height: 8),
      ])),
    );
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await InternshipService().updatePost(widget.post['id'] as String, {
        'title':          _title.text.trim(),
        'description':    _desc.text.trim(),
        'location':       _loc.text.trim(),
        'durationDays':   int.tryParse(_dur.text) ?? 30,
        'salary':         _salary.text.trim().isEmpty ? null : _salary.text.trim(),
        'requiredSkills': _skills,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Зар шинэчлэгдлээ ✓'),
          backgroundColor: AppColors.teal, behavior: SnackBarBehavior.floating));
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _loc, _dur, _salary, _skillCtrl]) { c.dispose(); }
    super.dispose();
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
  );
}

// ── Assessment Answers Tab ─────────────────────────────────────
class _AssessmentAnswersTab extends StatelessWidget {
  final Future<Map<String, dynamic>?> assessmentFuture;
  const _AssessmentAnswersTab({required this.assessmentFuture});

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: assessmentFuture,
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
      }
      final answers = (snap.data?['answers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (answers.isEmpty) {
        return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.quiz_outlined, size: 48, color: AppColors.faint),
          SizedBox(height: 12),
          Text('Шалгалт өгөөгүй байна', style: TextStyle(color: AppColors.muted)),
          SizedBox(height: 4),
          Text('Оюутан шалгалтын асуултанд хариулаагүй байна',
            style: TextStyle(fontSize: 11, color: AppColors.faint), textAlign: TextAlign.center),
        ]));
      }
      return ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(10)),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.amber),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Оюутанд хариултын дүн харагдахгүй. Зөвхөн та үзэх боломжтой.',
              style: TextStyle(fontSize: 11, color: AppColors.amber))),
          ]),
        ),
        const SizedBox(height: 14),
        ...answers.asMap().entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Center(child: Text('${e.key + 1}',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)))),
              const SizedBox(width: 8),
              Expanded(child: Text(e.value['question'] as String? ?? '',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text))),
            ]),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text(e.value['answer'] as String? ?? '',
                style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.5)),
            ),
          ]),
        )),
      ]);
    },
  );
}
