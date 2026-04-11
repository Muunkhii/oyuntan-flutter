// lib/screens/internship/company_interns_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class CompanyInternsScreen extends StatelessWidget {
  const CompanyInternsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        automaticallyImplyLeading: false,
        title: const Text('Дадлагажигчид'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: InternTrackingService().getCompanyInternships(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2));
          }
          final docs = snap.data?.docs ?? [];
          final active    = docs.where((d) => d['status'] == 'active').toList();
          final completed = docs.where((d) => d['status'] == 'completed').toList();

          if (docs.isEmpty) {
            return const _EmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                const SectionLabel('Одоо дадлага хийж байгаа'),
                ...active.map((doc) => _InternCard(doc: doc, isActive: true)),
                const SizedBox(height: 8),
              ],
              if (completed.isNotEmpty) ...[
                const SectionLabel('Дадлага дууссан'),
                ...completed.map((doc) => _InternCard(doc: doc, isActive: false)),
              ],
              // Pending posts → CV swipe link
              const SizedBox(height: 16),
              _PendingPostsSection(uid: uid),
            ],
          );
        },
      ),
    );
  }
}

class _InternCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final bool isActive;
  const _InternCard({required this.doc, required this.isActive});
  @override
  State<_InternCard> createState() => _InternCardState();
}

class _InternCardState extends State<_InternCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data     = widget.doc.data() as Map<String, dynamic>;
    final studentId   = data['studentId'] as String? ?? '';
    final completed   = (data['completedDays'] as num?)?.toInt() ?? 0;
    final total       = (data['durationDays']  as num?)?.toInt() ?? 1;
    final progress    = (completed / total).clamp(0.0, 1.0);

    return FutureBuilder<DocumentSnapshot>(
      future: DB.students.doc(studentId).get(),
      builder: (_, snap) {
        final s = snap.data?.data() as Map<String, dynamic>? ?? {};
        final name       = '${s['lastName'] ?? ''}.${s['firstName'] ?? ''}';
        final university = s['university'] as String? ?? '';
        final major      = s['major'] as String? ?? '';

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Avatar(name: name),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text('$university · $major',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              if (!widget.isActive)
                AppTag('Амжилттай', bg: AppColors.tealLight, textColor: AppColors.teal)
              else
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(_expanded ? 'Хаах' : 'Дэлгэрэнгүй',
                      style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                ),
            ]),

            if (widget.isActive) ...[
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('$completed / $total өдөр',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text('${(progress * 100).round()}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppColors.bg,
                  color: AppColors.teal,
                ),
              ),
            ],

            // Timeline (expanded)
            if (_expanded && widget.isActive) ...[
              const SizedBox(height: 14),
              _DiaryTimeline(internshipId: widget.doc.id, completed: completed),
            ],
          ]),
        );
      },
    );
  }
}

class _DiaryTimeline extends StatelessWidget {
  final String internshipId;
  final int completed;
  const _DiaryTimeline({required this.internshipId, required this.completed});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: DB.diary
          .where('internshipId', isEqualTo: internshipId)
          .orderBy('dayNumber')
          .snapshots(),
      builder: (_, snap) {
        final entries = snap.data?.docs ?? [];
        if (entries.isEmpty) {
          return const Text('Тэмдэглэл байхгүй байна',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary));
        }
        return Column(
          children: entries.take(5).map((e) {
            final d = e.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.teal, shape: BoxShape.circle),
                  ),
                  if (entries.last != e)
                    Container(width: 1, height: 30, color: AppColors.border),
                ]),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${d['dayNumber']}-р өдөр',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  Text(d['workDone'] as String? ?? '',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ])),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}

// CV Swipe-руу хандах хэсэг
class _PendingPostsSection extends StatelessWidget {
  final String uid;
  const _PendingPostsSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: InternshipService().getCompanyPosts(uid),
      builder: (_, snap) {
        final posts = snap.data?.docs ?? [];
        final withApplicants = posts
            .where((d) => ((d['applicantCount'] as num?)?.toInt() ?? 0) > 0)
            .toList();
        if (withApplicants.isEmpty) return const SizedBox();

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionLabel('CV Хянах'),
          ...withApplicants.map((doc) {
            final data   = doc.data() as Map<String, dynamic>;
            final count  = (data['applicantCount'] as num?)?.toInt() ?? 0;
            return AppCard(
              padding: const EdgeInsets.all(14),
              onTap: () => context.push('/company/swipe/${doc.id}'),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data['title'] as String? ?? '',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('$count өргөдөл хүлээж байна',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ])),
                const Icon(Icons.swipe_right_outlined, size: 20, color: AppColors.teal),
                const SizedBox(width: 4),
                const Text('CV харах', style: TextStyle(fontSize: 11, color: AppColors.teal)),
              ]),
            );
          }),
        ]);
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  static const _bgs = [AppColors.blueLight, AppColors.tealLight,
      AppColors.purpleLight, AppColors.coralLight];
  static const _fgs = [AppColors.blue, AppColors.teal, AppColors.purple, AppColors.coral];

  @override
  Widget build(BuildContext context) {
    final i = name.isNotEmpty ? name.codeUnitAt(0) % 4 : 0;
    final initials = name.length >= 2 ? name.substring(0, 2) : name;
    return CircleAvatar(
      radius: 20,
      backgroundColor: _bgs[i],
      child: Text(initials,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _fgs[i])),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 64, height: 64,
        decoration:
            BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(32)),
        child: const Icon(Icons.people_outline, size: 32, color: AppColors.textTertiary),
      ),
      const SizedBox(height: 16),
      const Text('Дадлагажигч байхгүй байна',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      const Text('Зар нийтэлж оюутан ажилд авна уу',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]),
  );
}
