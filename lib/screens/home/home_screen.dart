// lib/screens/home/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _categoryIdx = 0;
  late Future<List<Map<String, dynamic>>> _feedFuture;

  static const _categories = ['Бүх', 'IT', 'Санхүү', 'Маркетинг', 'Хэвлэл'];

  @override
  void initState() {
    super.initState();
    _feedFuture = InternshipService().getFeed();
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final mn    = context.watch<LocaleProvider>().isMN;
    final h     = DateTime.now().hour;
    final greet = h < 12 ? (mn ? 'Өглөөний мэнд' : 'Good morning')
                : h < 17 ? (mn ? 'Өдрийн мэнд'   : 'Good afternoon')
                :           (mn ? 'Оройн мэнд'    : 'Good evening');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ──────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3730A3), Color(0xFF5B4FE8)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // greeting row
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(greet,
                          style: const TextStyle(fontSize: 12, color: Color(0xAAFFFFFF))),
                        const SizedBox(height: 2),
                        Text(
                          auth.displayName.isEmpty
                              ? (mn ? 'Сайн байна уу' : 'Hello')
                              : auth.displayName,
                          style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ])),
                      GestureDetector(
                        onTap: () => context.go('/notifications'),
                        child: Stack(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                          ),
                          Positioned(right: 8, top: 8,
                            child: Container(width: 8, height: 8,
                              decoration: const BoxDecoration(color: Color(0xFFFF4444), shape: BoxShape.circle))),
                        ]),
                      ),
                    ]),

                    const SizedBox(height: 18),

                    // search bar
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                      ),
                      child: Row(children: [
                        const SizedBox(width: 14),
                        const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: mn ? 'Дадлага хайх...' : 'Search internships...',
                              hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(7),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 14),

                    // category chips
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final on = i == _categoryIdx;
                          return GestureDetector(
                            onTap: () => setState(() => _categoryIdx = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: on ? Colors.white : Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: on ? Colors.transparent : Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _categories[i],
                                style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: on ? AppColors.primary : Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 22),

                // ── Featured internship banners ────────────────
                SectionLabel(mn ? 'Онцлох дадлага' : 'Featured', action: mn ? 'Бүгд ›' : 'All ›'),
                const _FeaturedBanner(),
                const SizedBox(height: 22),

                // ── Internship feed cards ──────────────────────
                SectionLabel(mn ? 'Сүүлийн нэмэлт' : 'Recently added', action: mn ? 'Бүгд ›' : 'All ›'),
              ]),
            ),
          ),

          // horizontal scroll cards
          SliverToBoxAdapter(
            child: SizedBox(
              height: 168,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _feedFuture,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)));
                  }
                  final posts = snap.data ?? [];
                  if (posts.isEmpty) {
                    return Center(
                      child: Text(mn ? 'Дадлага байхгүй байна' : 'No internships yet',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13)));
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: posts.length,
                    itemBuilder: (_, i) => _InternCard(data: posts[i]),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── CV shortcut ────────────────────────────────
                _CvBanner(),
                const SizedBox(height: 22),

                // ── News ──────────────────────────────────────
                SectionLabel(mn ? 'Өнөөдрийн мэдээ' : 'Today\'s news', action: mn ? 'Бүгд ›' : 'All ›'),
                const _NewsItem('AI дадлагын байр нэмэгдлээ', 'Технологи', Icons.trending_up_rounded, AppColors.green),
                const _NewsItem('Frontend developer эрэлт өсчээ', 'Програм хангамж', Icons.code_rounded, AppColors.primary),
                const _NewsItem('Оюутнуудад зориулсан шинэ дадлага', 'Карьер', Icons.work_outline_rounded, AppColors.purple),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Featured Banner Carousel ───────────────────────────────────
class _FeaturedBanner extends StatefulWidget {
  const _FeaturedBanner();
  @override State<_FeaturedBanner> createState() => _FeaturedBannerState();
}
class _FeaturedBannerState extends State<_FeaturedBanner> {
  final _ctrl = PageController(viewportFraction: 0.90);
  int _page = 0;
  Timer? _timer;

  static const _banners = [
    (company: 'Datacom LLC',      role: 'Frontend Developer дадлага',  days: '30 хоног',  color: Color(0xFF5B4FE8), icon: Icons.laptop_mac_outlined),
    (company: 'Mobicom Mongolia', role: 'Маркетинг зөвлөх дадлага',    days: '60 хоног',  color: Color(0xFF06B6D4), icon: Icons.bar_chart_rounded),
    (company: 'МонФудс',          role: 'Бизнесийн шинжилгээ',         days: '45 хоног',  color: Color(0xFF7C3AED), icon: Icons.analytics_outlined),
    (company: 'MegaBank',         role: 'Санхүүгийн дадлага',          days: '90 хоног',  color: Color(0xFFD97706), icon: Icons.account_balance_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_ctrl.hasClients) return;
      final next = (_page + 1) % _banners.length;
      _ctrl.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext ctx) => Column(children: [
    SizedBox(
      height: 112,
      child: PageView.builder(
        controller: _ctrl,
        onPageChanged: (i) => setState(() => _page = i),
        itemCount: _banners.length,
        itemBuilder: (_, i) {
          final b = _banners[i];
          final darker = Color.fromARGB(
            255,
            (b.color.r * 255 * 0.65).round().clamp(0, 255),
            (b.color.g * 255 * 0.65).round().clamp(0, 255),
            (b.color.b * 255 * 0.65).round().clamp(0, 255),
          );
          return AnimatedScale(
            scale: _page == i ? 1.0 : 0.95,
            duration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [b.color, darker],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: b.color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 5))],
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(b.days, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  Text(b.role, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(b.company, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ])),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(b.icon, color: Colors.white, size: 26),
                ),
              ]),
            ),
          );
        },
      ),
    ),
    const SizedBox(height: 10),
    Row(mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_banners.length, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: _page == i ? 22 : 6, height: 6,
        decoration: BoxDecoration(
          color: _page == i ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(3),
        ),
      )),
    ),
  ]);

  @override
  void dispose() { _timer?.cancel(); _ctrl.dispose(); super.dispose(); }
}

// ── Internship Card (horizontal scroll) ───────────────────────
class _InternCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _InternCard({required this.data});

  static const _colors = [
    Color(0xFF5B4FE8), Color(0xFF06B6D4), Color(0xFF7C3AED),
    Color(0xFF16A34A), Color(0xFFD97706),
  ];

  @override
  Widget build(BuildContext ctx) {
    final title    = data['title']        as String? ?? '';
    final company  = data['company_name'] as String? ?? '';
    final location = data['location']     as String? ?? '';
    final days     = (data['duration_days'] as num?)?.toInt() ?? 0;
    final id       = data['id']?.toString() ?? '';
    final idx      = id.isEmpty ? 0 : id.codeUnitAt(0) % _colors.length;
    final color    = _colors[idx];

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 152,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.work_outline_rounded, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(company, style: const TextStyle(fontSize: 10, color: AppColors.muted),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 10, color: AppColors.faint),
            const SizedBox(width: 2),
            Expanded(child: Text(location.isEmpty ? '—' : location,
              style: const TextStyle(fontSize: 10, color: AppColors.faint),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$days хоног', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

// ── CV Banner ──────────────────────────────────────────────────
class _CvBanner extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: () => ctx.go('/cv'),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primaryLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.article_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CV Maker', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
          SizedBox(height: 2),
          Text('Мэргэжлийн CV-ээ хялбархан үүсгэнэ үү',
            style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
          child: const Text('Нээх', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ]),
    ),
  );
}

// ── News Item ──────────────────────────────────────────────────
class _NewsItem extends StatelessWidget {
  final String title, tag; final IconData icon; final Color color;
  const _NewsItem(this.title, this.tag, this.icon, this.color);
  @override Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(tag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ])),
      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint),
    ]),
  );
}
