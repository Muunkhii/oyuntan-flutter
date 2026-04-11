// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/home_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.displayName;
    final h    = DateTime.now().hour;
    final greeting =
        h < 12 ? 'Өглөөний мэнд' : h < 17 ? 'Өдрийн мэнд' : 'Оройн мэнд';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.bg,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(greeting,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400)),
                    Text(name.isEmpty ? 'Оюутан' : name,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                  ]),
                  Row(children: [
                    _LangToggle(),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 22),
                      onPressed: () => context.push('/notifications'),
                    ),
                  ]),
                ]),
          ),

          SliverToBoxAdapter(
            child: Column(children: [
              const WeatherDateHeader(),
              const SizedBox(height: 8),
              const AdCarousel(ads: studentAds),
            ]),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _CalendarStrip(),
                const SizedBox(height: 20),

                // News
                const SectionLabel('Өнөөдрийн мэдээ'),
                const _NewsItem('AI дадлагын байр нэмэгдлээ', 'Технологи'),
                const _NewsItem('Frontend developer эрэлт өсчээ', 'Програм хангамж'),
                const _NewsItem('React 19 гарлаа', 'Програм хангамж'),
                const SizedBox(height: 20),

                // Chatbot
                const _ChatBotCard(),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _LangToggle extends StatefulWidget {
  @override
  State<_LangToggle> createState() => _LangToggleState();
}
class _LangToggleState extends State<_LangToggle> {
  bool _mn = true;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _mn = !_mn),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 0.5),
          borderRadius: BorderRadius.circular(20)),
      child: Text(_mn ? 'МН' : 'EN',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    ),
  );
}

class _CalendarStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final today  = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days   = List.generate(7, (i) => monday.add(Duration(days: i)));
    final labels = ['Да', 'Мя', 'Лх', 'Пү', 'Ба', 'Бя', 'Ня'];
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
              color: isToday ? AppColors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              Text(labels[e.key],
                  style: TextStyle(
                      fontSize: 9,
                      color: isToday ? Colors.white54 : AppColors.textTertiary)),
              const SizedBox(height: 3),
              Text('${e.value.day}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isToday ? AppColors.white : AppColors.textPrimary)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}


class _NewsItem extends StatelessWidget {
  final String title, tag;
  const _NewsItem(this.title, this.tag);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tag,
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
      const SizedBox(height: 3),
      Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      const Divider(),
    ]),
  );
}

// ── Chatbot ───────────────────────────────────────────
class _ChatBotCard extends StatefulWidget {
  const _ChatBotCard();
  @override
  State<_ChatBotCard> createState() => _ChatBotCardState();
}

class _ChatBotCardState extends State<_ChatBotCard> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [
    _Msg('Сайн байна уу! Дадлага болон карьерын асуудалд туслах боломжтой. Юу асуумаар байна? 😊', false),
  ];

  static const _responses = {
    'дадлага': 'Дадлагын талаар асуусан юм байна. Дадлага → Компани хэсгээс боломжит дадлагуудыг үзэж, өргөдөл илгээж болно.',
    'өргөдөл': 'Өргөдөл илгээхийн тулд Дадлага хэсэгт ороод, таалагдсан компанийн зарт "Өргөдөл илгээх" товч дарна уу.',
    'cv': 'CV болон профайлаа Профайл хэсгээс бүрэн бөглөхийг зөвлөж байна. Ур чадвараа тодорхой бичих нь компанид таатай харагдана.',
    'freelance': 'Freelance ажлыг Дадлага → Freelance хэсгээс хайж болно. Орчуулга, дизайн, код бичих зэрэг ангилал байна.',
    'хэрхэн': 'Эхлэх бол: 1) Профайл бүрэн бөглөх 2) Дадлага хайх 3) Өргөдөл илгээх 4) Дадлагын явцаа бүртгэх.',
    'мэдэгдэл': 'Мэдэгдлийг доод цэснээс "Мэдэгдэл" хэсгийг сонгож харна уу.',
    'тусламж': 'Дэлгэрэнгүй тусламж авах бол support@oyuntan.mn руу хандана уу.',
  };

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _msgs.add(_Msg(text, true));
      _ctrl.clear();
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
    return 'Ойлголоо! Дадлага, CV, өргөдөл, freelance, мэдэгдэл гэх мэт асуултад хариулж чадна.';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Туслагч чатбот',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: AppColors.textSecondary)),
      const SizedBox(height: 10),
      SizedBox(
        height: 160,
        child: ListView.builder(
          controller: _scroll,
          itemCount: _msgs.length,
          itemBuilder: (_, i) {
            final m = _msgs[i];
            return Align(
              alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65),
                decoration: BoxDecoration(
                  color: m.isUser ? AppColors.black : AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(m.isUser ? 12 : 2),
                    bottomRight: Radius.circular(m.isUser ? 2 : 12),
                  ),
                  border: m.isUser
                      ? null
                      : Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Text(m.text,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: m.isUser ? AppColors.white : AppColors.textPrimary)),
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
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.send_rounded, size: 16, color: AppColors.white),
          ),
        ),
      ]),
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
