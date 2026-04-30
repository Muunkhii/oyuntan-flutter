// lib/screens/internship/internship_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../messages/messages_screen.dart';

class InternshipScreen extends StatefulWidget {
  const InternshipScreen({super.key});
  @override State<InternshipScreen> createState() => _IState();
}

class _IState extends State<InternshipScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
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
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Зарууд'),
            Tab(text: 'Хүсэлтүүд'),
            Tab(text: 'Дадлага'),
          ],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        const _FeedTab(),
        const _MyApplicationsTab(),
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
  final _search = TextEditingController();
  String _query = '';
  String _filter = 'all'; // all | paid | short | long
  Set<String> _bookmarks = {};

  @override void initState() {
    super.initState();
    _load();
    _loadBookmarks();
  }

  @override void dispose() { _search.dispose(); super.dispose(); }

  void _load() { setState(() { _future = InternshipService().getFeed(); }); }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('bookmarks') ?? [];
    if (mounted) setState(() => _bookmarks = saved.toSet());
  }

  Future<void> _toggleBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_bookmarks.contains(id)) {
        _bookmarks.remove(id);
      } else {
        _bookmarks.add(id);
      }
    });
    await prefs.setStringList('bookmarks', _bookmarks.toList());
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> posts) {
    var result = posts.where((d) {
      if (_query.isEmpty) return true;
      final title   = (d['title']        as String? ?? '').toLowerCase();
      final company = (d['company_name'] as String? ?? '').toLowerCase();
      final loc     = (d['location']     as String? ?? '').toLowerCase();
      return title.contains(_query) || company.contains(_query) || loc.contains(_query);
    }).toList();
    if (_filter == 'paid') {
      result = result.where((d) => (d['salary'] as String?)?.isNotEmpty == true).toList();
    } else if (_filter == 'short') {
      result = result.where((d) => (d['duration_days'] as num? ?? 999) <= 30).toList();
    } else if (_filter == 'long') {
      result = result.where((d) => (d['duration_days'] as num? ?? 0) > 30).toList();
    } else if (_filter == 'saved') {
      result = result.where((d) => _bookmarks.contains(d['id'] as String? ?? '')).toList();
    }
    return result;
  }

  void _showPostDetail(Map<String, dynamic> d) {
    final isCompany = context.read<AuthProvider>().isCompany;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostDetailSheet(post: d, onApply: () => _showApplySheet(d), isCompany: isCompany),
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
    return Column(children: [
      // ── Search bar ───────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Зар, компани, байршил хайх...',
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
            suffixIcon: _query.isNotEmpty
                ? GestureDetector(onTap: () { _search.clear(); setState(() => _query = ''); },
                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted))
                : null,
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ),
      // ── Filter chips ─────────────────────────────────────
      SizedBox(height: 38, child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: [
          _FilterChip('Бүгд',    'all',   _filter, (v) => setState(() => _filter = v)),
          _FilterChip('Цалинтай','paid',  _filter, (v) => setState(() => _filter = v)),
          _FilterChip('≤30 хоног','short',_filter, (v) => setState(() => _filter = v)),
          _FilterChip('>30 хоног','long', _filter, (v) => setState(() => _filter = v)),
          _FilterChip('Хадгалсан','saved',_filter, (v) => setState(() => _filter = v)),
        ],
      )),
      // ── List ─────────────────────────────────────────────
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (c, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
          }
          final filtered = _applyFilter(snap.data ?? []);
          if (filtered.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.search_off_rounded, size: 44, color: AppColors.faint),
              const SizedBox(height: 10),
              Text(_query.isNotEmpty ? 'Хайлтын үр дүн олдсонгүй' : 'Зар байхгүй байна',
                style: const TextStyle(color: AppColors.muted)),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: filtered.length,
              itemBuilder: (c, i) {
                final d    = filtered[i];
                final id   = d['id'] as String? ?? '';
                final saved = _bookmarks.contains(id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () {
                      InternshipService().trackView(id);
                      _showPostDetail(d);
                    },
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(d['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                        GestureDetector(
                          onTap: () => _toggleBookmark(id),
                          child: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 20, color: saved ? AppColors.primary : AppColors.faint),
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
                      Row(children: [
                        if ((d['salary'] as String?)?.isNotEmpty == true) ...[
                          const Icon(Icons.payments_outlined, size: 13, color: AppColors.green),
                          const SizedBox(width: 4),
                          Text(d['salary'] as String, style: const TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w500)),
                        ],
                        const Spacer(),
                        if ((d['view_count'] as int? ?? 0) > 0) ...[
                          const Icon(Icons.visibility_outlined, size: 12, color: AppColors.faint),
                          const SizedBox(width: 3),
                          Text('${d['view_count']}', style: const TextStyle(fontSize: 10, color: AppColors.faint)),
                          const SizedBox(width: 10),
                        ],
                        const Text('Дэлгэрэнгүй', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 3),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                      ]),
                    ]),
                  ).animate().fadeIn(delay: Duration(milliseconds: i * 50)),
                );
              },
            ),
          );
        },
      )),
    ]);
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value, current;
  final void Function(String) onTap;
  const _FilterChip(this.label, this.value, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final on = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: on ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? AppColors.primary : AppColors.border, width: on ? 1.5 : 0.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: on ? Colors.white : AppColors.muted)),
      ),
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
                    if (status == 'active' && done >= total)
                      Expanded(child: ElevatedButton(
                        onPressed: () => c.push('/review/$id'),
                        child: const Text('Үнэлэх'),
                      ))
                    else if (status == 'completed')
                      Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, elevation: 0),
                        onPressed: () => _showCertificate(c, d),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.workspace_premium_rounded, size: 14),
                          SizedBox(width: 5),
                          Text('Гэрчилгээ'),
                        ]),
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

  void _showCertificate(BuildContext ctx, Map<String, dynamic> d) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CertificateSheet(internship: d),
    );
  }
}

// ── Миний хүсэлтүүд ──────────────────────────────────────────
class _MyApplicationsTab extends StatefulWidget {
  const _MyApplicationsTab();
  @override State<_MyApplicationsTab> createState() => _MyApplicationsTabState();
}
class _MyApplicationsTabState extends State<_MyApplicationsTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override void initState() { super.initState(); _load(); }
  void _load() {
    final uid = context.read<AuthProvider>().uid;
    setState(() { _future = InternshipService().getStudentApplications(uid); });
  }

  Color _statusColor(String s) => switch (s) {
    'accepted'  => AppColors.green,
    'rejected'  => AppColors.red,
    _           => AppColors.amber,
  };
  Color _statusBg(String s) => switch (s) {
    'accepted'  => AppColors.greenLight,
    'rejected'  => AppColors.redLight,
    _           => AppColors.amberLight,
  };
  String _statusLabel(String s) => switch (s) {
    'accepted'  => 'Зөвшөөрөгдсөн',
    'rejected'  => 'Татгалзсан',
    _           => 'Хүлээгдэж байна',
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
        }
        final apps = snap.data ?? [];
        if (apps.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.inbox_outlined, size: 48, color: AppColors.faint),
            const SizedBox(height: 12),
            const Text('Хүсэлт илгээгээгүй байна', style: TextStyle(color: AppColors.muted)),
          ]));
        }
        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (ctx, i) {
              final d      = apps[i];
              final status = d['status'] as String? ?? 'pending';
              final photo  = d['company_photo'] as String?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Company avatar
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                        image: (photo != null && photo.isNotEmpty)
                            ? DecorationImage(image: MemoryImage(base64Decode(photo)), fit: BoxFit.cover)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: (photo == null || photo.isEmpty)
                          ? Text((d['company_name'] as String? ?? '?')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryDark))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['post_title'] as String? ?? 'Дадлага',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(d['company_name'] as String? ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusBg(status),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(_statusLabel(status),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: _statusColor(status))),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.faint),
                    const SizedBox(width: 5),
                    Text(_formatDate(d['created_at'] as String?),
                      style: const TextStyle(fontSize: 11, color: AppColors.faint)),
                    const Spacer(),
                    if (status == 'pending')
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: AppColors.amber),
                        const SizedBox(width: 4),
                        const Text('Хүлээж байна', style: TextStyle(fontSize: 11, color: AppColors.amber)),
                      ])
                    else if (status == 'accepted')
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.check_circle_outline, size: 12, color: AppColors.green),
                        const SizedBox(width: 4),
                        const Text('Дадлага эхэлсэн', style: TextStyle(fontSize: 11, color: AppColors.green)),
                      ])
                    else
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cancel_outlined, size: 12, color: AppColors.red),
                        const SizedBox(width: 4),
                        const Text('Татгалзсан', style: TextStyle(fontSize: 11, color: AppColors.red)),
                      ]),
                  ]),
                ])),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
            },
          ),
        );
      },
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}/${dt.month.toString().padLeft(2,'0')}/${dt.day.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }
}

// ── Certificate Sheet ─────────────────────────────────────────
class _CertificateSheet extends StatelessWidget {
  final Map<String, dynamic> internship;
  const _CertificateSheet({required this.internship});

  @override
  Widget build(BuildContext context) {
    final title   = internship['title']        as String? ?? 'Дадлага';
    final company = internship['company_name'] as String? ?? '';
    final days    = internship['duration_days'] as int?   ?? 0;
    final end     = internship['end_date']     as String?;
    String endStr = '';
    if (end != null) {
      try {
        final dt = DateTime.parse(end).toLocal();
        endStr = '${dt.year}/${dt.month.toString().padLeft(2,'0')}/${dt.day.toString().padLeft(2,'0')}';
      } catch (_) {}
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 44, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 28),
        // Gold badge
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.35), blurRadius: 16)]),
          child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text('ДАДЛАГЫН ГЭРЧИЛГЭЭ',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
            color: AppColors.muted, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        // Decorative border card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [const Color(0xFFFFFBEB), Colors.white],
              begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: Column(children: [
            const Text('Энэхүү гэрчилгээгээр', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 10),
            Consumer<AuthProvider>(
              builder: (_, auth, __) => Text(auth.displayName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
            ),
            const SizedBox(height: 8),
            Text('$company компанид', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
              textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('чиглэлээр $days хоногийн дадлага амжилттай хийж гүйцэтгэсэн.',
              style: const TextStyle(fontSize: 12, color: AppColors.muted), textAlign: TextAlign.center),
            if (endStr.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(endStr,
                style: const TextStyle(fontSize: 12, color: AppColors.faint, fontWeight: FontWeight.w500)),
            ],
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, size: 16),
          label: const Text('Хаах'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.bg, foregroundColor: AppColors.text,
            elevation: 0, minimumSize: const Size(0, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )),
        const SizedBox(height: 8),
      ]),
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
  final bool isCompany;
  const _PostDetailSheet({required this.post, required this.onApply, this.isCompany = false});
  @override State<_PostDetailSheet> createState() => _PostDetailSheetState();
}
class _PostDetailSheetState extends State<_PostDetailSheet> {
  late Future<Map<String, dynamic>> _future;
  late Future<String?> _photoFuture;

  @override void initState() {
    super.initState();
    _future = ApiClient.get('/posts/${widget.post['id']}').then((r) => r as Map<String, dynamic>);
    final cid = widget.post['company_id'] as String? ?? '';
    _photoFuture = cid.isNotEmpty
        ? ApiClient.get('/companies/$cid')
            .then((r) => (r as Map<String, dynamic>?)?['photo'] as String?)
            .catchError((_) => null as String?)
        : Future.value(null);
  }

  void _showCompanyProfile(Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompanyProfileSheet(postData: d),
    );
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
          if (!widget.isCompany)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () {
                      final cid   = widget.post['company_id']   as String? ?? '';
                      final cname = widget.post['company_name'] as String? ?? 'Компани';
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatScreen(otherUid: cid, otherName: cname)));
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: const Text('Мессеж'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    onPressed: () { Navigator.pop(context); widget.onApply(); },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
                    child: const Text('Хүсэлт илгээх'),
                  )),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> d, ScrollController ctrl) {
    final skills   = (d['required_skills'] as List?)?.cast<String>() ?? [];
    final avgScore = _parseDouble(d['avg_score']);
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // ── Company card (tappable → full profile) ──────────────
        GestureDetector(
          onTap: () => _showCompanyProfile(d),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FutureBuilder<String?>(
                  future: _photoFuture,
                  builder: (_, snap) {
                    final photo = snap.data;
                    if (photo != null && photo.isNotEmpty) {
                      try {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(base64Decode(photo),
                            width: 52, height: 52, fit: BoxFit.cover));
                      } catch (_) {}
                    }
                    if (d['logo_url'] != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(d['logo_url'] as String, width: 52, height: 52, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _CompanyAvatar(size: 52, name: d['company_name'] as String?)));
                    }
                    return _CompanyAvatar(size: 52, name: d['company_name'] as String?);
                  },
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['company_name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  if (d['industry'] != null)
                    Text(d['industry'] as String, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  if (avgScore != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      ...List.generate(5, (i) => Icon(
                        i < avgScore.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 14, color: i < avgScore.round() ? Colors.amber : AppColors.faint)),
                      const SizedBox(width: 5),
                      Text('${avgScore.toStringAsFixed(1)} (${d['review_count'] ?? 0})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
                    ]),
                  ],
                ])),
              ]),
              if (d['company_location'] != null || d['website'] != null || (d['employee_count'] != null && d['employee_count'] != 0)) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 14, runSpacing: 4, children: [
                  if (d['company_location'] != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Text(d['company_location'] as String, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ]),
                  if (d['website'] != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.language_outlined, size: 12, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Text(d['website'] as String, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                    ]),
                  if (d['employee_count'] != null && d['employee_count'] != 0)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.people_outline_rounded, size: 12, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Text('${d['employee_count']} ажилтан', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ]),
                ]),
              ],
              if ((d['company_description'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(d['company_description'] as String,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.5)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.business_outlined, size: 13, color: AppColors.primary),
                const SizedBox(width: 5),
                const Text('Компанийн дэлгэрэнгүй мэдээлэл харах',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
              ]),
            ]),
          ),
        ),
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
class _PortfolioItem {
  final TextEditingController name = TextEditingController();
  final TextEditingController url  = TextEditingController();
  void dispose() { name.dispose(); url.dispose(); }
}

class _ApplySheetState extends State<_ApplySheet> {
  final _msgCtrl = TextEditingController();
  bool _loading = false;
  bool _done = false;
  late Future<Map<String, dynamic>?> _cvFuture;
  late String _uid;
  List<Map<String, dynamic>> _questions    = [];
  List<TextEditingController> _answerCtrls = [];
  final List<_PortfolioItem> _portfolio    = [];

  @override void initState() {
    super.initState();
    _uid = context.read<AuthProvider>().uid;
    _cvFuture = CVService().get(_uid);
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final cid = widget.post['company_id'] as String? ?? '';
    if (cid.isEmpty) return;
    final qs = await AssessmentService().getCompanyQuestions(cid);
    if (!mounted) return;
    setState(() {
      _questions   = qs;
      _answerCtrls = qs.map((_) => TextEditingController()).toList();
    });
  }

  void _addPortfolio() {
    if (_portfolio.length >= 5) return;
    setState(() => _portfolio.add(_PortfolioItem()));
  }

  void _removePortfolio(int i) {
    _portfolio[i].dispose();
    setState(() => _portfolio.removeAt(i));
  }

  @override void dispose() {
    _msgCtrl.dispose();
    for (final c in _answerCtrls) { c.dispose(); }
    for (final p in _portfolio)   { p.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final portfolioData = _portfolio
          .map((p) => {'name': p.name.text.trim(), 'url': p.url.text.trim()})
          .where((p) => (p['name'] as String).isNotEmpty || (p['url'] as String).isNotEmpty)
          .toList();
      final res = await InternshipService().apply(
        postId:     widget.post['id']         as String,
        companyId:  widget.post['company_id'] as String? ?? '',
        message:   _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
        portfolio: portfolioData.isEmpty        ? null : portfolioData,
      );
      if (_questions.isNotEmpty) {
        final appId   = res['id'] as String? ?? '';
        final cid     = widget.post['company_id'] as String? ?? '';
        final answers = <Map<String, dynamic>>[];
        for (var i = 0; i < _questions.length; i++) {
          final ans = _answerCtrls[i].text.trim();
          if (ans.isNotEmpty) answers.add({'question': _questions[i]['question'], 'answer': ans});
        }
        if (answers.isNotEmpty && appId.isNotEmpty) {
          await AssessmentService().submitAnswers(applicationId: appId, companyId: cid, answers: answers);
        }
      }
      if (mounted) setState(() { _done = true; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating));
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
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Компанид хэлэхийг хүсэж буй зүйлс...'),
            ),

            // ── Portfolio links ──────────────────────────────
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Бүтээлийн холбоосууд (заавал биш)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('GitHub, Google Docs, Figma, portfolio site...',
                  style: TextStyle(fontSize: 11, color: AppColors.faint)),
              ])),
              if (_portfolio.length < 5)
                GestureDetector(
                  onTap: _addPortfolio,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 3),
                      Text('Нэмэх', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ]),
                  ),
                ),
            ]),
            if (_portfolio.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._portfolio.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5)),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: TextField(
                      controller: e.value.name,
                      decoration: const InputDecoration(
                        hintText: 'Бүтээлийн нэр', isDense: true,
                        border: InputBorder.none, contentPadding: EdgeInsets.zero),
                    )),
                    GestureDetector(
                      onTap: () => _removePortfolio(e.key),
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted)),
                  ]),
                  const Divider(height: 12),
                  TextField(
                    controller: e.value.url,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.link_rounded, size: 15, color: AppColors.primary),
                      hintText: 'https://github.com/...', isDense: true,
                      border: InputBorder.none, contentPadding: EdgeInsets.zero),
                  ),
                ]),
              )),
            ] else ...[
              const SizedBox(height: 6),
              const Text('GitHub репо, Google Docs, Figma эсвэл бусад бүтээлийн холбоосыг нэмж болно',
                style: TextStyle(fontSize: 11, color: AppColors.faint)),
            ],

            if (_questions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amberLight, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.3))),
                child: const Row(children: [
                  Icon(Icons.quiz_outlined, size: 16, color: AppColors.amber),
                  SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Мэргэжлийн шалгалт',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.amber)),
                    Text('Таны хариултыг зөвхөн компани харах боломжтой',
                      style: TextStyle(fontSize: 11, color: AppColors.amber)),
                  ])),
                ]),
              ),
              const SizedBox(height: 14),
              ..._questions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: Center(child: Text('${e.key + 1}',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.value['question'] as String? ?? '',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  ]),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _answerCtrls[e.key],
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Хариулт...'),
                  ),
                ]),
              )),
            ],
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
  final bool circle;
  const _CompanyAvatar({this.size = 48, this.name, this.circle = false});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(10)),
    alignment: Alignment.center,
    child: Text(
      name?.isNotEmpty == true ? name![0].toUpperCase() : '?',
      style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
    ),
  );
}

// ── Company Profile Sheet ────��────────────────────────────────
class _CompanyProfileSheet extends StatefulWidget {
  final Map<String, dynamic> postData;
  const _CompanyProfileSheet({required this.postData});
  @override State<_CompanyProfileSheet> createState() => _CompanyProfileSheetState();
}
class _CompanyProfileSheetState extends State<_CompanyProfileSheet> {
  late Future<List<Map<String, dynamic>>> _reviewsFuture;
  late Future<List<Map<String, dynamic>>> _postsFuture;
  late Future<Map<String, dynamic>?> _companyFuture;

  @override void initState() {
    super.initState();
    final cid = widget.postData['company_id'] as String? ?? '';
    _reviewsFuture = ReviewService().getCompanyReviews(cid);
    _postsFuture   = InternshipService().getCompanyPosts(cid);
    _companyFuture = ApiClient.get('/companies/$cid')
        .then((v) => v as Map<String, dynamic>?)
        .catchError((_) => null as Map<String, dynamic>?);
  }

  @override
  Widget build(BuildContext context) {
    final d        = widget.postData;
    final avgScore = _parseDouble(d['avg_score']);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(2))),
          Expanded(child: ListView(
            controller: ctrl,
            padding: EdgeInsets.zero,
            children: [
              // ── Hero header ───────────────────────────────
              FutureBuilder<Map<String, dynamic>?>(
                future: _companyFuture,
                builder: (_, snap) {
                  final c = snap.data;
                  final photo       = c?['photo']         as String?;
                  final coverPhoto  = c?['cover_photo']   as String?;
                  final phone       = c?['phone']         as String? ?? '';
                  final email       = c?['email']         as String? ?? '';
                  final history     = (c?['history'] as String?)?.isNotEmpty == true
                      ? c!['history'] as String
                      : (d['history'] as String?)?.isNotEmpty == true ? d['history'] as String : '';
                  final empCount    = c?['employee_count'] ?? d['employee_count'];
                  final foundedYear = c?['founded_year'];
                  final website     = (c?['website'] as String?)?.isNotEmpty == true
                      ? c!['website'] as String
                      : (d['website'] as String?)?.isNotEmpty == true ? d['website'] as String : '';
                  final location    = (c?['location'] as String?)?.isNotEmpty == true
                      ? c!['location'] as String
                      : (d['company_location'] as String?)?.isNotEmpty == true
                          ? d['company_location'] as String : '';
                  final desc        = (c?['description'] as String?)?.isNotEmpty == true
                      ? c!['description'] as String
                      : (d['company_description'] as String?)?.isNotEmpty == true
                          ? d['company_description'] as String : '';

                  Uint8List? coverBytes;
                  if (coverPhoto != null && coverPhoto.isNotEmpty) {
                    try { coverBytes = base64Decode(coverPhoto); } catch (_) {}
                  }

                  Widget avatar;
                  if (photo != null && photo.isNotEmpty) {
                    try {
                      avatar = CircleAvatar(radius: 44, backgroundImage: MemoryImage(base64Decode(photo)));
                    } catch (_) {
                      avatar = _CompanyAvatar(size: 88, name: d['company_name'] as String?, circle: true);
                    }
                  } else if (d['logo_url'] != null) {
                    avatar = CircleAvatar(radius: 44,
                      backgroundImage: NetworkImage(d['logo_url'] as String),
                      onBackgroundImageError: (_, __) {});
                  } else {
                    avatar = _CompanyAvatar(size: 88, name: d['company_name'] as String?, circle: true);
                  }

                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Hero gradient block
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        gradient: coverBytes == null
                            ? const LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight)
                            : null,
                        image: coverBytes != null
                            ? DecorationImage(
                                image: MemoryImage(coverBytes),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.55), BlendMode.darken))
                            : null,
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20)),
                            child: Text(d['industry'] as String? ?? 'Компани',
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500))),
                        ]),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16)]),
                          child: avatar),
                        const SizedBox(height: 14),
                        Text(d['company_name'] ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                          textAlign: TextAlign.center),
                        if (avgScore != null) ...[
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            ...List.generate(5, (i) => Icon(
                              i < avgScore.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 16, color: i < avgScore.round() ? Colors.amber : Colors.white38)),
                            const SizedBox(width: 6),
                            Text('${avgScore.toStringAsFixed(1)}  ·  ${d['review_count'] ?? 0} үнэлгээ',
                              style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          ]),
                        ],
                      ]),
                    ),

                    // ── Stats row ──────────────────────────────
                    Container(
                      color: const Color(0xFF0F172A),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                        child: Wrap(spacing: 10, runSpacing: 10, children: [
                          if (empCount != null && empCount != 0)
                            _StatChip(Icons.people_outline_rounded, '$empCount ажилтан',
                              color: AppColors.primaryLight, textColor: AppColors.primaryDark),
                          if (foundedYear != null && foundedYear != 0)
                            _StatChip(Icons.calendar_today_outlined, '$foundedYear оноос',
                              color: const Color(0xFFE8F5E9), textColor: AppColors.green),
                          if (location.isNotEmpty)
                            _StatChip(Icons.location_on_outlined, location,
                              color: AppColors.amberLight, textColor: const Color(0xFFB45309)),
                          if (website.isNotEmpty)
                            _StatChip(Icons.language_outlined, website,
                              color: AppColors.bg, textColor: AppColors.primary),
                        ]),
                      ),
                    ),

                    // ── Body content ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        // Description
                        if (desc.isNotEmpty) ...[
                          _SectionTitle('Компанийн тухай'),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.bg, borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border, width: 0.5)),
                            child: Text(desc,
                              style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.7)),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Contact
                        if (phone.isNotEmpty || email.isNotEmpty) ...[
                          _SectionTitle('Холбоо барих'),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.bg, borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border, width: 0.5)),
                            child: Column(children: [
                              if (phone.isNotEmpty)
                                _ContactRow(Icons.phone_outlined, phone),
                              if (email.isNotEmpty)
                                _ContactRow(Icons.email_outlined, email),
                            ]),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // History
                        if (history.isNotEmpty) ...[
                          _SectionTitle('Компанийн намтар'),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primaryLight, Colors.white],
                                begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
                            child: Text(history,
                              style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.7)),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ]),
                    ),
                  ]);
                },
              ),

              // ── Reviews ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SectionTitle('Оюутнуудын сэтгэгдэл'),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _reviewsFuture,
                    builder: (c, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)));
                      }
                      final reviews = snap.data ?? [];
                      if (reviews.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                          child: const Row(children: [
                            Icon(Icons.reviews_outlined, color: AppColors.faint, size: 20),
                            SizedBox(width: 10),
                            Text('Оюутнуудын үнэлгээ байхгүй байна',
                              style: TextStyle(fontSize: 12, color: AppColors.muted)),
                          ]));
                      }
                      return Column(children: reviews.take(5).map((r) => _ReviewCard(r)).toList());
                    },
                  ),
                  const SizedBox(height: 20),
                ]),
              ),

              // ── Active posts ──────────────────────────────
              const SizedBox(height: 20),
              const Text('Нээлттэй дадлагын зарууд',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _postsFuture,
                builder: (c, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary)));
                  }
                  final posts = snap.data ?? [];
                  if (posts.isEmpty) {
                    return const Text('Нээлттэй зар байхгүй байна',
                      style: TextStyle(fontSize: 12, color: AppColors.faint));
                  }
                  return Column(
                    children: posts.map((p) => _PostMiniCard(p)).toList());
                },
              ),
              const SizedBox(height: 40),
            ],
          )),
        ]),
      ),
    );
  }
}

// ���─ Review card ───────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard(this.review);
  @override
  Widget build(BuildContext context) {
    final scores = [
      (review['env_score']      as num?)?.toDouble() ?? 0,
      (review['mentor_score']   as num?)?.toDouble() ?? 0,
      (review['learn_score']    as num?)?.toDouble() ?? 0,
      (review['relation_score'] as num?)?.toDouble() ?? 0,
    ];
    final avg         = scores.reduce((a, b) => a + b) / scores.length;
    final comment     = review['comment']     as String? ?? '';
    final wouldReturn = review['would_return'] as bool?   ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ...List.generate(5, (i) => Icon(
            i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14, color: i < avg.round() ? Colors.amber : AppColors.faint)),
          const SizedBox(width: 6),
          Text(avg.toStringAsFixed(1),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (wouldReturn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.greenLight, borderRadius: BorderRadius.circular(6)),
              child: const Text('Дахин хийнэ',
                style: TextStyle(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w500)),
            ),
        ]),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(comment,
            style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5)),
        ],
        const SizedBox(height: 8),
        Row(children: [
          _ScoreDot('Орчин',    scores[0]),
          const SizedBox(width: 10),
          _ScoreDot('Ментор',   scores[1]),
          const SizedBox(width: 10),
          _ScoreDot('Суралцах', scores[2]),
          const SizedBox(width: 10),
          _ScoreDot('Харилцаа', scores[3]),
        ]),
      ]),
    );
  }
}

class _ScoreDot extends StatelessWidget {
  final String label;
  final double score;
  const _ScoreDot(this.label, this.score);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(score.toStringAsFixed(0),
      style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: score >= 4 ? AppColors.green : score >= 3 ? AppColors.amber : AppColors.red)),
    Text(label, style: const TextStyle(fontSize: 9, color: AppColors.faint)),
  ]);
}

// ── Post mini card ─────────────────────────────────────────────
class _PostMiniCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _PostMiniCard(this.post);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(post['title'] ?? '',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('${post['location'] ?? ''}  ·  ${post['duration_days'] ?? 0} хоног',
          style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
        child: const Text('Дадлага',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
      ),
    ]),
  );
}

// ── Contact row ────────────────────────────────────────────────
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _ContactRow(this.icon, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 15, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(value,
        style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500))),
    ]),
  );
}

// ── Stat chip (colored pill) ───────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final Color    textColor;
  const _StatChip(this.icon, this.label, {required this.color, required this.textColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: textColor),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
    ]),
  );
}

// ── Helpers ────────────────────────────────────────────────────
double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

// ── Section title ──────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 3, height: 16,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
    ]),
  );
}
