// lib/screens/internship/internship_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class InternshipScreen extends StatefulWidget {
  const InternshipScreen({super.key});
  @override
  State<InternshipScreen> createState() => _InternshipScreenState();
}

class _InternshipScreenState extends State<InternshipScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        automaticallyImplyLeading: false,
        title: const Text('Дадлага хайх'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _SegmentedTabBar(controller: _tab),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _CompanyTab(),
          _FreelanceTab(),
        ],
      ),
    );
  }
}

// ── Segment Tab Bar ───────────────────────────────────
class _SegmentedTabBar extends StatelessWidget {
  final TabController controller;
  const _SegmentedTabBar({required this.controller});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
    child: AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          _SegBtn('Компани', 0, controller),
          _SegBtn('Freelance', 1, controller),
        ]),
      ),
    ),
  );
}

class _SegBtn extends StatelessWidget {
  final String label;
  final int idx;
  final TabController ctrl;
  const _SegBtn(this.label, this.idx, this.ctrl);

  @override
  Widget build(BuildContext context) {
    final active = ctrl.index == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.animateTo(idx),
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
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
              )),
        ),
      ),
    );
  }
}

// ── Company Tab ───────────────────────────────────────
class _CompanyTab extends StatelessWidget {
  const _CompanyTab();

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid ?? '';

    return CustomScrollView(slivers: [
      // Active internship banner
      SliverToBoxAdapter(child: _ActiveInternshipBanner(uid: uid)),

      // Posts list
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Нээлттэй зарууд',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary, letterSpacing: 0.5)),
        ),
      ),
      StreamBuilder<QuerySnapshot>(
        stream: InternshipService().getAllPosts(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2)),
            );
          }
          final posts = snap.data?.docs ?? [];
          if (posts.isEmpty) {
            return const SliverFillRemaining(child: _EmptyPosts());
          }
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PostCard(doc: posts[i], uid: uid),
                ),
                childCount: posts.length,
              ),
            ),
          );
        },
      ),
    ]);
  }
}

// ── Active Internship Banner ──────────────────────────
class _ActiveInternshipBanner extends StatelessWidget {
  final String uid;
  const _ActiveInternshipBanner({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: InternTrackingService().getStudentActiveInternship(uid),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox();
        final internship = docs.first;
        final data      = internship.data() as Map<String, dynamic>;
        final completed = (data['completedDays'] as num?)?.toInt() ?? 0;
        final total     = (data['durationDays']  as num?)?.toInt() ?? 1;
        final progress  = (completed / total).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('Идэвхтэй дадлага',
                      style: TextStyle(fontSize: 10, color: AppColors.teal,
                          fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                Text('$completed/$total өдөр',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppColors.bg,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/diary/${internship.id}'),
                    icon: const Icon(Icons.edit_note_outlined, size: 16),
                    label: const Text('Тэмдэглэл'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        textStyle: const TextStyle(fontSize: 12)),
                  ),
                ),
                if (progress >= 1.0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/review/${internship.id}'),
                      icon: const Icon(Icons.star_outline, size: 16),
                      label: const Text('Үнэлгээ'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          textStyle: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ]),
            ]),
          ),
        );
      },
    );
  }
}

// ── Post Card ─────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String uid;
  const _PostCard({required this.doc, required this.uid});

  @override
  Widget build(BuildContext context) {
    final data     = doc.data() as Map<String, dynamic>;
    final title    = data['title']       as String? ?? '';
    final desc     = data['description'] as String? ?? '';
    final duration = (data['durationDays'] as num?)?.toInt() ?? 0;
    final count    = (data['applicantCount'] as num?)?.toInt() ?? 0;
    final location = data['location']   as String? ?? 'Улаанбаатар';
    final salary   = data['salary']     as String? ?? '';
    final companyId = data['companyId'] as String? ?? '';
    final skills   = (data['skills']    as List?)?.cast<String>() ?? [];

    return FutureBuilder<DocumentSnapshot>(
      future: DB.companies.doc(companyId).get(),
      builder: (_, snap) {
        final c = snap.data?.data() as Map<String, dynamic>? ?? {};
        final companyName = c['name'] as String? ?? '';
        final avgScore    = (c['avgScore'] as num?)?.toDouble() ?? 0.0;

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: AppColors.purpleLight,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.business, color: AppColors.purple, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(companyName,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ])),
              if (avgScore > 0) _StarRating(avgScore),
            ]),
            const SizedBox(height: 8),

            // Meta row
            Wrap(spacing: 8, children: [
              _MetaChip(Icons.calendar_today_outlined, '$duration өдөр'),
              _MetaChip(Icons.people_outline, '$count хүсэлт'),
              if (location.isNotEmpty)
                _MetaChip(Icons.location_on_outlined, location),
              if (salary.isNotEmpty)
                _MetaChip(Icons.attach_money_outlined, salary),
            ]),

            if (desc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(desc,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
            ],

            if (skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 4,
                children: skills.take(4).map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(s,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary)),
                )).toList(),
              ),
            ],

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _apply(context, doc.id, companyId),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  textStyle: const TextStyle(fontSize: 13)),
              child: const Text('Өргөдөл илгээх'),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _apply(BuildContext context, String postId, String companyId) async {
    // Capture messenger before async gap
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Өргөдөл илгээх', style: TextStyle(fontSize: 16)),
        content: const Text('Энэ дадлагад өргөдөл илгээхдээ итгэлтэй байна уу?',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Болих')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Илгээх')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await InternshipService().apply(
        postId: postId,
        studentId: uid,
        companyId: companyId,
      );
      messenger.showSnackBar(const SnackBar(
        content: Text('Өргөдөл амжилттай илгээгдлээ'),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

class _StarRating extends StatelessWidget {
  final double score;
  const _StarRating(this.score);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.star_rounded, size: 13, color: AppColors.amber),
    const SizedBox(width: 2),
    Text(score.toStringAsFixed(1),
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]);
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 11, color: AppColors.textTertiary),
    const SizedBox(width: 3),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]);
}

// ── Freelance Tab ─────────────────────────────────────
class _FreelanceTab extends StatefulWidget {
  const _FreelanceTab();
  @override
  State<_FreelanceTab> createState() => _FreelanceTabState();
}

class _FreelanceTabState extends State<_FreelanceTab> {
  String? _selected;

  static const _categories = [
    ('Орчуулга',    Icons.translate_outlined),
    ('Дизайн',      Icons.design_services_outlined),
    ('Код бичих',   Icons.code_outlined),
    ('Бичих',       Icons.edit_outlined),
    ('Видео',       Icons.videocam_outlined),
    ('Маркетинг',   Icons.campaign_outlined),
    ('Зөвлөх',      Icons.support_agent_outlined),
    ('Бусад',       Icons.more_horiz_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionLabel('Ангилал сонгох'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _categories.map((cat) {
            final active = _selected == cat.$1;
            return GestureDetector(
              onTap: () => setState(() =>
                  _selected = active ? null : cat.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.black : AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: active ? AppColors.black : AppColors.border,
                      width: 0.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(cat.$2,
                      size: 14,
                      color: active ? AppColors.white : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(cat.$1,
                      style: TextStyle(
                          fontSize: 12,
                          color: active ? AppColors.white : AppColors.textSecondary,
                          fontWeight: active ? FontWeight.w500 : FontWeight.w400)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Freelance зарууд'),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: DB.freelance
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (_, snap) {
            var docs = snap.data?.docs ?? [];
            if (_selected != null) {
              docs = docs
                  .where((d) => d['category'] == _selected)
                  .toList();
            }
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(children: [
                    const Icon(Icons.work_off_outlined,
                        size: 32, color: AppColors.textTertiary),
                    const SizedBox(height: 8),
                    Text(_selected != null
                        ? '$_selected ангилалд зар байхгүй байна'
                        : 'Freelance зар байхгүй байна',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ]),
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(d['title'] as String? ?? '',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500))),
                        AppTag(d['category'] as String? ?? 'Freelance',
                            bg: AppColors.purpleLight,
                            textColor: AppColors.purple),
                      ]),
                      const SizedBox(height: 4),
                      Text(d['description'] as String? ?? '',
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(children: [
                        if ((d['budget'] as String? ?? '').isNotEmpty)
                          _MetaChip(Icons.attach_money_outlined,
                              d['budget'] as String),
                        const SizedBox(width: 12),
                        if ((d['deadline'] as String? ?? '').isNotEmpty)
                          _MetaChip(Icons.schedule_outlined,
                              d['deadline'] as String),
                      ]),
                    ]),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyPosts extends StatelessWidget {
  const _EmptyPosts();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 64, height: 64,
        decoration:
            BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(32)),
        child: const Icon(Icons.work_outline, size: 32, color: AppColors.textTertiary),
      ),
      const SizedBox(height: 16),
      const Text('Дадлагын зар байхгүй байна',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      const Text('Дараа дахин шалгаарай',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]),
  );
}
