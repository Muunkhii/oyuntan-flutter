// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/home_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid  = auth.user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Blue header ─────────────────────────────
            SliverToBoxAdapter(child: _DashboardHeader(auth: auth, uid: uid)),

            // ── Stats row ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _StatsRow(uid: uid),
              ),
            ),

            // ── Weather & Calendar ───────────────────────
            const SliverToBoxAdapter(child: WeatherDateHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _CalendarStrip(),
              ),
            ),

            // ── Sponsored Ads (Firebase) ─────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _SponsoredAdsSection(),
              ),
            ),

            // ── Active internship banner ─────────────────
            SliverToBoxAdapter(child: _ActiveInternshipCard(uid: uid)),

            // ── My Applications ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _SectionHeader(
                  title: 'Миний өргөдлүүд',
                  onMore: () => context.go('/internships'),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _ApplicationsList(uid: uid)),

            // ── Quick actions ────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _QuickActions(),
              ),
            ),

            // ── Chatbot ──────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: _ChatBotCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard Header (blue gradient) ─────────────────────
class _DashboardHeader extends StatelessWidget {
  final AuthProvider auth;
  final String uid;
  const _DashboardHeader({required this.auth, required this.uid});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Өглөөний мэнд';
    if (h < 17) return 'Өдрийн мэнд';
    return 'Оройн мэнд';
  }

  @override
  Widget build(BuildContext context) {
    final name = auth.displayName.isEmpty ? 'Оюутан' : auth.displayName;
    final profile = auth.profile;
    final major = profile?['major'] as String? ?? '';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'О',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_greeting,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75))),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    if (major.isNotEmpty)
                      Text(major,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7))),
                  ]),
                ]),
                Row(children: [
                  _HeaderIconBtn(
                    icon: Icons.search_rounded,
                    onTap: () => context.go('/internships'),
                  ),
                  const SizedBox(width: 8),
                  StreamBuilder<int>(
                    stream: uid.isEmpty
                        ? Stream.value(0)
                        : NotificationService().unreadCount(uid),
                    builder: (_, snap) {
                      final count = snap.data ?? 0;
                      return Stack(children: [
                        _HeaderIconBtn(
                          icon: Icons.notifications_outlined,
                          onTap: () => context.push('/notifications'),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 6, top: 6,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFBBF24),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ]);
                    },
                  ),
                ]),
              ],
            ),

            const SizedBox(height: 20),

            // Progress card
            _ProfileProgressCard(uid: uid, profile: profile),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _ProfileProgressCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic>? profile;
  const _ProfileProgressCard({required this.uid, required this.profile});

  double _calcCompletion(Map<String, dynamic>? p) {
    if (p == null) return 0;
    final fields = ['firstName', 'lastName', 'email', 'major', 'university',
                    'phone', 'bio', 'skills', 'gpa'];
    int filled = 0;
    for (final f in fields) {
      final v = p[f];
      if (v != null && v.toString().isNotEmpty) filled++;
    }
    return filled / fields.length;
  }

  @override
  Widget build(BuildContext context) {
    final pct = _calcCompletion(profile);
    final pctInt = (pct * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Профайлын дүүргэлт',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                pctInt >= 80
                    ? 'Маш сайн! Компаниудад харагдаж байна'
                    : 'Профайлаа бүрэн бөглөснөөр илүү олон боломж нээгдэнэ',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.4),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Text('$pctInt%',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Профайл засах',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ),
      ]),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final String uid;
  const _StatsRow({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: DB.applications.where('studentId', isEqualTo: uid).snapshots(),
      builder: (_, appSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: DB.internships.where('studentId', isEqualTo: uid).snapshots(),
          builder: (_, intSnap) {
            final apps     = appSnap.data?.docs ?? [];
            final interns  = intSnap.data?.docs ?? [];
            final pending  = apps.where((d) => d['status'] == 'pending').length;
            final active   = interns.where((d) => d['status'] == 'active').length;
            final done     = interns.where((d) => d['status'] == 'completed').length;

            return Transform.translate(
              offset: const Offset(0, -20),
              child: Row(children: [
                Expanded(child: _StatCard(
                  icon: Icons.send_rounded,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primaryLight,
                  label: 'Хүсэлт',
                  value: '${apps.length}',
                  sub: '$pending хүлээгдэж байна',
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(
                  icon: Icons.work_rounded,
                  iconColor: AppColors.teal,
                  iconBg: AppColors.tealLight,
                  label: 'Идэвхтэй',
                  value: '$active',
                  sub: 'дадлага',
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.success,
                  iconBg: AppColors.successLight,
                  label: 'Дууссан',
                  value: '$done',
                  sub: 'дадлага',
                )),
              ]),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, value, sub;
  const _StatCard({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.label, required this.value, required this.sub,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: iconColor),
      ),
      const SizedBox(height: 8),
      Text(value,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      Text(label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
      Text(sub,
          style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
    ]),
  );
}

// ── Active Internship Card ────────────────────────────────
class _ActiveInternshipCard extends StatelessWidget {
  final String uid;
  const _ActiveInternshipCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: InternTrackingService().getStudentActiveInternship(uid),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox();
        final internship = docs.first;
        final data       = internship.data() as Map<String, dynamic>;
        final completed  = (data['completedDays'] as num?)?.toInt() ?? 0;
        final total      = (data['durationDays']  as num?)?.toInt() ?? 1;
        final progress   = (completed / total).clamp(0.0, 1.0);
        final companyId  = data['companyId'] as String? ?? '';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: FutureBuilder<DocumentSnapshot>(
            future: DB.companies.doc(companyId).get(),
            builder: (_, cSnap) {
              final cData = cSnap.data?.data() as Map<String, dynamic>? ?? {};
              final cName = cData['name'] as String? ?? 'Компани';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('● Идэвхтэй дадлага',
                          style: TextStyle(fontSize: 10, color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    Text('$completed/$total өдөр',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8))),
                  ]),
                  const SizedBox(height: 8),
                  Text(cName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFBBF24)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/diary/${internship.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_note_rounded,
                                  size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Тэмдэглэл',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (progress >= 1.0) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/review/${internship.id}'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 16, color: Color(0xFF0D9488)),
                                SizedBox(width: 6),
                                Text('Үнэлгээ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF0D9488),
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ── Section header ────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;
  const _SectionHeader({required this.title, this.onMore});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
      if (onMore != null)
        GestureDetector(
          onTap: onMore,
          child: const Text('Бүгдийг харах',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ),
    ],
  );
}

// ── Applications list ─────────────────────────────────────
class _ApplicationsList extends StatelessWidget {
  final String uid;
  const _ApplicationsList({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return const SizedBox();
    }
    return StreamBuilder<QuerySnapshot>(
      stream: DB.applications
          .where('studentId', isEqualTo: uid)
          .limit(5)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Column(children: [
                Container(
                  width: 52, height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.work_outline_rounded,
                      size: 26, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                const Text('Дадлага хайж эхэлнэ үү',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Боломжит дадлагуудыг харж өргөдөл илгээгээрэй',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.go('/internships'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Дадлага хайх',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ]),
            ),
          );
        }

        // Sort by createdAt descending (client-side to avoid index requirement)
        final sorted = List<QueryDocumentSnapshot>.from(docs)..sort((a, b) {
          final at = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bt = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bt.compareTo(at);
        });

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              children: sorted.asMap().entries.map((entry) {
                final i   = entry.key;
                final doc = entry.value;
                final data = doc.data() as Map<String, dynamic>;
                return _ApplicationRow(
                  data: data,
                  isLast: i == sorted.length - 1,
                  onTap: () => context.go('/internships'),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ApplicationRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLast;
  final VoidCallback onTap;
  const _ApplicationRow(
      {required this.data, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status   = data['status'] as String? ?? 'pending';
    final postId   = data['postId'] as String? ?? '';
    final companyId = data['companyId'] as String? ?? '';

    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        DB.posts.doc(postId).get(),
        DB.companies.doc(companyId).get(),
      ]),
      builder: (_, snap) {
        final post    = snap.data?[0].data() as Map<String, dynamic>? ?? {};
        final company = snap.data?[1].data() as Map<String, dynamic>? ?? {};
        final title   = post['title'] as String? ?? 'Дадлагын байр';
        final cName   = company['name'] as String? ?? '';

        return GestureDetector(
          onTap: onTap,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      cName.isNotEmpty ? cName[0].toUpperCase() : 'К',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(cName,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                )),
                const SizedBox(width: 8),
                _StatusBadge(status: status),
              ]),
            ),
            if (!isLast)
              const Divider(height: 1, indent: 14, endIndent: 14),
          ]),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    late String label;
    switch (status) {
      case 'accepted':
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = 'Зөвшөөрсөн';
      case 'rejected':
        bg = AppColors.redLight;
        fg = AppColors.red;
        label = 'Татгалзсан';
      default:
        bg = AppColors.amberLight;
        fg = AppColors.amber;
        label = 'Хүлээгдэж буй';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionHeader(title: 'Хурдан үйлдэл'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _QuickCard(
          icon: Icons.search_rounded,
          label: 'Дадлага\nхайх',
          color: AppColors.primary,
          bg: AppColors.primaryLight,
          onTap: () => context.go('/internships'),
        )),
        const SizedBox(width: 10),
        Expanded(child: _QuickCard(
          icon: Icons.notifications_outlined,
          label: 'Мэдэгдэл\nхарах',
          color: AppColors.amber,
          bg: AppColors.amberLight,
          onTap: () => context.push('/notifications'),
        )),
        const SizedBox(width: 10),
        Expanded(child: _QuickCard(
          icon: Icons.person_outline_rounded,
          label: 'Профайл\nтохиргоо',
          color: AppColors.purple,
          bg: AppColors.purpleLight,
          onTap: () => context.go('/profile'),
        )),
        const SizedBox(width: 10),
        Expanded(child: _QuickCard(
          icon: Icons.edit_note_rounded,
          label: 'Дадлагын\nтэмдэглэл',
          color: AppColors.teal,
          bg: AppColors.tealLight,
          onTap: () => context.go('/internships'),
        )),
      ]),
    ]);
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bg;
  final VoidCallback onTap;
  const _QuickCard({
    required this.icon, required this.label,
    required this.color, required this.bg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, height: 1.3)),
      ]),
    ),
  );
}

// ── Chatbot ───────────────────────────────────────────────
class _ChatBotCard extends StatefulWidget {
  const _ChatBotCard();
  @override
  State<_ChatBotCard> createState() => _ChatBotCardState();
}

class _ChatBotCardState extends State<_ChatBotCard> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _expanded = false;
  final List<_Msg> _msgs = [
    const _Msg('Сайн байна уу! Дадлага болон карьерын асуудалд туслах боломжтой. Юу асуумаар байна? 😊', false),
  ];

  static const _responses = {
    'дадлага':  'Дадлагын талаар асуусан юм байна. Дадлага → Компани хэсгээс боломжит дадлагуудыг үзэж, өргөдөл илгээж болно.',
    'өргөдөл':  'Өргөдөл илгээхийн тулд Дадлага хэсэгт ороод, таалагдсан компанийн зарт "Өргөдөл илгээх" товч дарна уу.',
    'cv':       'CV болон профайлаа Профайл хэсгээс бүрэн бөглөхийг зөвлөж байна. Ур чадвараа тодорхой бичих нь компанид таатай харагдана.',
    'freelance':'Freelance ажлыг Дадлага → Freelance хэсгээс хайж болно. Орчуулга, дизайн, код бичих зэрэг ангилал байна.',
    'хэрхэн':   'Эхлэх бол: 1) Профайл бүрэн бөглөх 2) Дадлага хайх 3) Өргөдөл илгээх 4) Дадлагын явцаа бүртгэх.',
    'мэдэгдэл': 'Мэдэгдлийг доод цэснээс "Мэдэгдэл" хэсгийг сонгож харна уу.',
    'тусламж':  'Дэлгэрэнгүй тусламж авах бол support@oyuntan.mn руу хандана уу.',
    'профайл':  'Профайлаа Профайл табаас засж болно. Зураг, ур чадвар, GPA бичих нь компанид илүү таатай харагдана.',
  };

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _msgs.add(_Msg(text, true));
      _ctrl.clear();
      _expanded = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final reply = _getReply(text.toLowerCase());
      setState(() => _msgs.add(_Msg(reply, false)));
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      });
    });
  }

  String _getReply(String text) {
    for (final kv in _responses.entries) {
      if (text.contains(kv.key)) return kv.value;
    }
    return 'Ойлголоо! Дадлага, CV, өргөдөл, freelance, мэдэгдэл, профайл гэх мэт асуултад хариулж чадна.';
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI туслагч',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text('Дадлага, карьерын асуулт',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('● Онлайн',
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      color: AppColors.success)),
            ),
          ]),
        ),
      ),

      if (_expanded) ...[
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            SizedBox(
              height: 180,
              child: ListView.builder(
                controller: _scroll,
                itemCount: _msgs.length,
                itemBuilder: (_, i) {
                  final m = _msgs[i];
                  return Align(
                    alignment: m.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.68),
                      decoration: BoxDecoration(
                        color: m.isUser
                            ? AppColors.primary
                            : AppColors.bg,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft:
                              Radius.circular(m.isUser ? 12 : 2),
                          bottomRight:
                              Radius.circular(m.isUser ? 2 : 12),
                        ),
                        border: m.isUser
                            ? null
                            : Border.all(
                                color: AppColors.border, width: 0.8),
                      ),
                      child: Text(m.text,
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: m.isUser
                                  ? Colors.white
                                  : AppColors.textPrimary)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Асуултаа бичих...',
                    hintStyle: TextStyle(fontSize: 12),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.send_rounded,
                      size: 18, color: Colors.white),
                ),
              ),
            ]),
          ]),
        ),
      ] else ...[
        // Collapsed: show quick prompts
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              'Дадлага хэрхэн хайх?',
              'CV зөвлөмж',
              'Өргөдөл илгээх',
            ].map((q) => GestureDetector(
              onTap: () {
                _ctrl.text = q;
                _send();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primaryMid, width: 0.8),
                ),
                child: Text(q,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            )).toList(),
          ),
        ),
      ],
    ]),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }
}

class _Msg {
  final String text;
  final bool isUser;
  const _Msg(this.text, this.isUser);
}

// ── Calendar Strip ────────────────────────────────────────
class _CalendarStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final today  = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days   = List.generate(7, (i) => monday.add(Duration(days: i)));
    const labels = ['Да', 'Мя', 'Лх', 'Пү', 'Ба', 'Бя', 'Ня'];
    return Row(
      children: days.asMap().entries.map((e) {
        final isToday = e.value.day == today.day &&
            e.value.month == today.month;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday ? AppColors.primary : AppColors.border,
                width: 0.8,
              ),
            ),
            child: Column(children: [
              Text(labels[e.key],
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textTertiary)),
              const SizedBox(height: 3),
              Text('${e.value.day}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isToday ? Colors.white : AppColors.textPrimary)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Sponsored Ads Section (Firebase + static fallback) ────
class _SponsoredAdsSection extends StatelessWidget {
  const _SponsoredAdsSection();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Онцлох зар',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          GestureDetector(
            onTap: () => _showPlaceAdDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryMid, width: 0.8),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, size: 13, color: AppColors.primary),
                SizedBox(width: 4),
                Text('Зар байрлуулах',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ]),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      StreamBuilder<QuerySnapshot>(
        stream: DB.posts
            .where('isSponsored', isEqualTo: true)
            .where('isActive', isEqualTo: true)
            .limit(5)
            .snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          // Use static fallback if no sponsored posts yet
          if (docs.isEmpty) {
            return _StaticAdCarousel();
          }
          return _FirebaseAdCarousel(docs: docs);
        },
      ),
    ]);
  }

  void _showPlaceAdDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _PlaceAdSheet(),
    );
  }
}

// ── Static fallback carousel ──────────────────────────────
class _StaticAdCarousel extends StatefulWidget {
  @override
  State<_StaticAdCarousel> createState() => _StaticAdCarouselState();
}

class _StaticAdCarouselState extends State<_StaticAdCarousel> {
  final _ctrl = PageController();
  int _page = 0;

  static const _ads = [
    _AdData('Frontend дадлага 2025', 'Datacom LLC · 30 хоног · Цалинтай',
        AppColors.primary, AppColors.primaryLight, Icons.code_rounded),
    _AdData('Маркетинг хөтөлбөр', 'Mobicom · 60 хоног · Улаанбаатар',
        AppColors.teal, AppColors.tealLight, Icons.campaign_rounded),
    _AdData('Санхүүгийн дадлага', 'Монгол банк · 45 хоног',
        AppColors.amber, AppColors.amberLight, Icons.account_balance_rounded),
    _AdData('Лого дизайн · Freelance', 'StartUp Mongolia · ₮150,000',
        AppColors.purple, AppColors.purpleLight, Icons.design_services_rounded),
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted) return;
    final next = (_page + 1) % _ads.length;
    _ctrl.animateToPage(next,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 96,
        child: PageView.builder(
          controller: _ctrl,
          itemCount: _ads.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => _AdCard(ad: _ads[i]),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_ads.length, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _page == i ? 16 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: _page == i ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
        )),
      ),
    ]);
  }
}

class _AdData {
  final String title, sub;
  final Color color, bg;
  final IconData icon;
  const _AdData(this.title, this.sub, this.color, this.bg, this.icon);
}

class _AdCard extends StatelessWidget {
  final _AdData ad;
  const _AdCard({required this.ad});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 1),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: ad.bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
          color: ad.color.withValues(alpha: 0.25), width: 0.8),
    ),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: ad.color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(ad.icon, size: 22, color: ad.color),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ad.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Онцлох',
                  style: TextStyle(
                      fontSize: 8, fontWeight: FontWeight.w700,
                      color: ad.color)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(ad.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: ad.color)),
          Text(ad.sub,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  color: ad.color.withValues(alpha: 0.75))),
        ],
      )),
      Icon(Icons.chevron_right_rounded,
          color: ad.color.withValues(alpha: 0.5), size: 20),
    ]),
  );
}

// ── Firebase Ad Carousel ──────────────────────────────────
class _FirebaseAdCarousel extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  const _FirebaseAdCarousel({required this.docs});
  @override
  State<_FirebaseAdCarousel> createState() => _FirebaseAdCarouselState();
}

class _FirebaseAdCarouselState extends State<_FirebaseAdCarousel> {
  final _ctrl = PageController();
  int _page = 0;

  static const _colors = [
    AppColors.primary, AppColors.teal, AppColors.purple,
    AppColors.amber, AppColors.coral,
  ];
  static const _bgs = [
    AppColors.primaryLight, AppColors.tealLight, AppColors.purpleLight,
    AppColors.amberLight, AppColors.coralLight,
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted) return;
    final next = (_page + 1) % widget.docs.length;
    _ctrl.animateToPage(next,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 96,
        child: PageView.builder(
          controller: _ctrl,
          itemCount: widget.docs.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final data     = widget.docs[i].data() as Map<String, dynamic>;
            final title    = data['title']       as String? ?? '';
            final company  = data['companyName'] as String? ?? '';
            final duration = data['durationDays'] as int? ?? 0;
            final salary   = data['salary']      as String? ?? '';
            final color    = _colors[i % _colors.length];
            final bg       = _bgs[i % _bgs.length];
            final sub      = [
              if (company.isNotEmpty) company,
              if (duration > 0) '$duration хоног',
              if (salary.isNotEmpty) salary,
            ].join(' · ');

            return _AdCard(
              ad: _AdData(title, sub, color, bg,
                  Icons.work_rounded),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.docs.length, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _page == i ? 16 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: _page == i ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
        )),
      ),
    ]);
  }
}

// ── Place Ad Sheet ────────────────────────────────────────
class _PlaceAdSheet extends StatefulWidget {
  const _PlaceAdSheet();
  @override
  State<_PlaceAdSheet> createState() => _PlaceAdSheetState();
}

class _PlaceAdSheetState extends State<_PlaceAdSheet> {
  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _plan = '7 хоног · ₮50,000';
  bool _submitting = false;

  static const _plans = [
    '7 хоног · ₮50,000',
    '14 хоног · ₮90,000',
    '30 хоног · ₮150,000',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await DB.posts.add({
        'title':       _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'contact':     _contactCtrl.text.trim(),
        'adPlan':      _plan,
        'isSponsored': false, // Admin approves → sets to true
        'isActive':    false,
        'type':        'sponsored_request',
        'createdAt':   FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Зарын хүсэлт илгээгдлээ. Баталгаажуулсны дараа нийтлэгдэнэ.'),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.campaign_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Зар байрлуулах',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              Text('Оюутнуудад дадлага, ажлын байраа сурталчилна уу',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 20),

          // Title
          const Text('Зарын гарчиг *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
                hintText: 'Frontend дадлага 2025...'),
          ),
          const SizedBox(height: 14),

          // Description
          const Text('Дэлгэрэнгүй тайлбар',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Дадлагын нөхцөл, шаардлага...'),
          ),
          const SizedBox(height: 14),

          // Contact
          const Text('Холбоо барих',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _contactCtrl,
            decoration: const InputDecoration(
                hintText: 'Утас эсвэл имэйл'),
          ),
          const SizedBox(height: 14),

          // Plan
          const Text('Байрлуулах хугацаа',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _plans.map((p) {
              final selected = _plan == p;
              return GestureDetector(
                onTap: () => setState(() => _plan = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary : AppColors.border,
                      width: selected ? 1.5 : 0.8,
                    ),
                  ),
                  child: Text(p,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white : AppColors.textPrimary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Info note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Хүсэлтийг илгээсний дараа админ баталгаажуулж нийтлэнэ',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.amber, height: 1.4),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text('Хүсэлт илгээх'),
          ),
        ]),
      ),
    );
  }
}
