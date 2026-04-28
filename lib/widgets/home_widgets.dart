// lib/widgets/home_widgets.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/weather_service.dart';

// ── Weather + Date Header ─────────────────────────────
class WeatherDateHeader extends StatefulWidget {
  const WeatherDateHeader({super.key});
  @override
  State<WeatherDateHeader> createState() => _WeatherDateHeaderState();
}

class _WeatherDateHeaderState extends State<WeatherDateHeader> {
  WeatherResult? _weather;
  bool _loading = true;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  static const _mnMonths = [
    '', 'Нэгдүгээр', 'Хоёрдугаар', 'Гуравдугаар', 'Дөрөвдүгээр',
    'Тавдугаар', 'Зургаадугаар', 'Долоодугаар', 'Наймдугаар',
    'Есдүгээр', 'Аравдугаар', 'Арваннэгдүгээр', 'Арвандöрвөдүгээр',
  ];
  static const _mnWeekdays = ['Да', 'Мя', 'Лх', 'Пү', 'Ба', 'Бя', 'Ня'];

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _clockTimer = Timer.periodic(const Duration(seconds: 30),
        (_) => setState(() => _now = DateTime.now()));
  }

  Future<void> _fetchWeather() async {
    final w = await WeatherService().fetchUlaanbaatar();
    if (mounted) setState(() { _weather = w; _loading = false; });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final month   = _mnMonths[_now.month];
    final weekday = _mnWeekdays[_now.weekday - 1];
    final timeStr = DateFormat('HH:mm').format(_now);
    final dateStr = '${_now.year} оны $month сарын ${_now.day}, $weekday';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(children: [
        // Date + time
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(dateStr,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(timeStr,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ])),

        // Divider
        Container(width: 0.5, height: 36, color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 12)),

        // Weather
        if (_loading)
          const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textTertiary))
        else if (_weather == null)
          const Text('—', style: TextStyle(fontSize: 12, color: AppColors.textTertiary))
        else
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              Text(_weather!.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text('${_weather!.temp.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500)),
            ]),
            Text('Улаанбаатар · ${_weather!.condition}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ]),
      ]),
    );
  }
}

// ── Ad Carousel ───────────────────────────────────────
class AdCarousel extends StatefulWidget {
  final List<AdItem> ads;
  const AdCarousel({super.key, required this.ads});
  @override
  State<AdCarousel> createState() => _AdCarouselState();
}

class AdItem {
  final String title, subtitle, tag;
  final Color bg, fg;
  const AdItem({
    required this.title, required this.subtitle,
    required this.tag, this.bg = AppColors.purpleLight, this.fg = AppColors.purple,
  });
}

class _AdCarouselState extends State<AdCarousel> {
  final _ctrl  = PageController();
  int  _page   = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.ads.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        final next = (_page + 1) % widget.ads.length;
        _ctrl.animateToPage(next,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 88,
        child: PageView.builder(
          controller: _ctrl,
          itemCount: widget.ads.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final ad = widget.ads[i];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ad.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: ad.fg.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(ad.tag,
                        style: TextStyle(fontSize: 9, color: ad.fg,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4),
                  Text(ad.title,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: ad.fg),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(ad.subtitle,
                      style: TextStyle(fontSize: 11, color: ad.fg.withValues(alpha: 0.7)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Icon(Icons.chevron_right, color: ad.fg.withValues(alpha: 0.5)),
              ]),
            );
          },
        ),
      ),
      // Dot indicators
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.ads.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width:  _page == i ? 14 : 5,
            height: 5,
            decoration: BoxDecoration(
              color: _page == i ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ))),
    ]);
  }
}

// ── AppTag ────────────────────────────────────────────
class AppTag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  const AppTag(this.label, {super.key, required this.bg, required this.textColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
  );
}

// Default ads for student home
const studentAds = [
  AdItem(
    tag: 'Шинэ',
    title: 'Datacom LLC · Frontend дадлага 2025',
    subtitle: '30 хоног · Улаанбаатар · Цалинтай',
    bg: AppColors.blueLight, fg: AppColors.blue,
  ),
  AdItem(
    tag: 'Онцлох',
    title: 'Mobicom · Маркетинг хөтөлбөр',
    subtitle: '60 хоног · Улаанбаатар + Онлайн',
    bg: AppColors.tealLight, fg: AppColors.teal,
  ),
  AdItem(
    tag: 'Хугацаа дуусах',
    title: 'Монгол банк · Санхүүгийн дадлага',
    subtitle: '45 хоног · Нарийн бичгийн газар',
    bg: AppColors.amberLight, fg: Color(0xFF854F0B),
  ),
  AdItem(
    tag: 'Freelance',
    title: 'StartUp Mongolia · Лого дизайн',
    subtitle: '₮150,000 · 7 хоног',
    bg: AppColors.purpleLight, fg: AppColors.purple,
  ),
];

// Default ads for company home
const companyAds = [
  AdItem(
    tag: 'Зөвлөмж',
    title: 'Профайл бүрэн бөглөсөн компани',
    subtitle: '3 дахин их өргөдөл хүлээн авдаг',
    bg: AppColors.tealLight, fg: AppColors.teal,
  ),
  AdItem(
    tag: 'Мэдээ',
    title: '2025 оны дадлагын улирал эхэллээ',
    subtitle: 'Зараа хурдан нийтлэн хамгийн сайн нэр дэвшигчийг олоорой',
    bg: AppColors.blueLight, fg: AppColors.blue,
  ),
  AdItem(
    tag: 'Шинэ функц',
    title: 'CV Swipe — AI тохирол шалгалт',
    subtitle: 'Оюутны ур чадварт тохирсон байдлыг шалгана',
    bg: AppColors.purpleLight, fg: AppColors.purple,
  ),
];
