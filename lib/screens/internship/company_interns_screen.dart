// lib/screens/internship/company_interns_screen.dart
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
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
                onTap: count > 0 ? () => context.push('/company/swipe/${p['id']}') : null,
                child: Row(children: [
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

  Future<void> _reject(Map<String, dynamic> app) async {
    try {
      await InternshipService().rejectApplication(app['id'] as String);
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
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(suffixText: 'өдөр'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Болих')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, int.tryParse(ctrl.text) ?? 30),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Зөвшөөрөх'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
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
              final a         = apps[i];
              final firstName = a['first_name'] as String? ?? '';
              final lastName  = a['last_name']  as String? ?? '';
              final name      = '$lastName $firstName'.trim();
              final univ      = a['university']  as String? ?? '';
              final major     = a['major']       as String? ?? '';
              final skills    = (a['skills'] as List?)?.cast<String>() ?? [];
              final postTitle = a['post_title']  as String? ?? '';
              final message   = a['message']     as String?;

              return _Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  if (message != null && message.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
                      child: Text(message,
                        style: const TextStyle(fontSize: 12, color: AppColors.text, height: 1.5))),
                  ],
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6,
                      children: skills.take(5).map((s) =>
                        _Chip(s, bg: AppColors.bg, fg: AppColors.muted)).toList()),
                  ],
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _ActionBtn('Татгалзах', Icons.close_rounded,
                      AppColors.red, AppColors.redLight, () => _reject(a))),
                    const SizedBox(width: 10),
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
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
        final all       = snap.data ?? [];
        final active    = all.where((d) => d['status'] == 'active').toList();
        final completed = all.where((d) => d['status'] == 'completed').toList();
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
                ...active.map((d) => _InternCard(data: d, isActive: true)),
                const SizedBox(height: 8),
              ],
              if (completed.isNotEmpty) ...[
                _SectionHeader('Дадлага дууссан (${completed.length})'),
                ...completed.map((d) => _InternCard(data: d, isActive: false)),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ── Intern card with expandable diary ─────────────────────────
class _InternCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isActive;
  const _InternCard({required this.data, required this.isActive});
  @override State<_InternCard> createState() => _InternCardState();
}

class _InternCardState extends State<_InternCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d         = widget.data;
    final firstName = d['first_name'] as String? ?? '';
    final lastName  = d['last_name']  as String? ?? '';
    final name      = '$lastName $firstName'.trim();
    final title     = d['title']      as String? ?? '';
    final completed = (d['completed_days'] as num?)?.toInt() ?? 0;
    final total     = (d['duration_days']  as num?)?.toInt() ?? 1;
    final progress  = (completed / total).clamp(0.0, 1.0);

    return _Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _InitialsAvatar(name: name),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ])),
          if (!widget.isActive)
            const _Chip('Дууссан', bg: AppColors.tealLight, fg: AppColors.teal)
          else
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: _Chip(
                _expanded ? 'Хаах ▲' : 'Дэлгэрэнгүй ▼',
                bg: AppColors.primaryLight, fg: AppColors.primary),
            ),
        ]),
        if (widget.isActive) ...[
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
        if (_expanded && widget.isActive) ...[
          const SizedBox(height: 14),
          _DiaryTimeline(internshipId: d['id'] as String),
        ],
      ]),
    );
  }
}

class _DiaryTimeline extends StatefulWidget {
  final String internshipId;
  const _DiaryTimeline({required this.internshipId});
  @override State<_DiaryTimeline> createState() => _DiaryTimelineState();
}

class _DiaryTimelineState extends State<_DiaryTimeline> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = DiaryService().getEntries(widget.internshipId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const SizedBox(height: 24, child: Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)));
        final entries = snap.data ?? [];
        if (entries.isEmpty)
          return const Text('Тэмдэглэл байхгүй',
            style: TextStyle(fontSize: 11, color: AppColors.muted));
        return Column(
          children: entries.take(5).toList().asMap().entries.map((e) {
            final d      = e.value;
            final isLast = e.key == entries.take(5).length - 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
                  if (!isLast) Container(width: 1, height: 28, color: AppColors.border),
                ]),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${d['day_number']}-р өдөр',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
                  Text(d['work_done'] as String? ?? '',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                ])),
              ]),
            );
          }).toList(),
        );
      },
    );
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
