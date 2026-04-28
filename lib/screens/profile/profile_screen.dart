// lib/screens/profile/profile_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';

// ── REVIEW SCREEN ─────────────────────────────────────────────
class ReviewScreen extends StatefulWidget {
  final String internshipId;
  const ReviewScreen({super.key, required this.internshipId});
  @override State<ReviewScreen> createState() => _RState();
}
class _RState extends State<ReviewScreen> {
  final _scores  = <String, int>{'env': 0, 'mentor': 0, 'learn': 0, 'relation': 0};
  bool? _wouldReturn;
  final _comment = TextEditingController();
  bool _saving = false, _done = false;

  static const _criteria = [
    ('env',      'Ажлын орчин ба хамт олон'),
    ('mentor',   'Менторийн дэмжлэг'),
    ('learn',    'Суралцах боломж'),
    ('relation', 'Харилцаа'),
  ];

  @override Widget build(BuildContext c) {
    if (_done) return Scaffold(body: SafeArea(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 64, height: 64,
        decoration: const BoxDecoration(color: AppColors.greenLight, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 32, color: AppColors.green)),
      const SizedBox(height: 16),
      const Text('Үнэлгээ илгээгдлээ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Таны сэтгэгдэл бусад оюутнуудад тусална', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.muted)),
      const SizedBox(height: 24),
      TextButton(onPressed: () => c.go('/home'), child: const Text('Нүүр хуудас руу →')),
    ]))));

    return Scaffold(
      appBar: AppBar(title: const Text('Компани үнэлэх')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.check_circle_outline, color: AppColors.green, size: 20),
            SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Дадлага дууслаа!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green)),
              Text('Компанид үнэлгээ өгнө үү', style: TextStyle(fontSize: 11, color: AppColors.green)),
            ])),
          ])),
        const SizedBox(height: 20),
        ..._criteria.map((cr) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cr.$2, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 8),
            Row(children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _scores[cr.$1] = i + 1),
              child: Padding(padding: const EdgeInsets.only(right: 6),
                child: Icon(i < (_scores[cr.$1] ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 30, color: i < (_scores[cr.$1] ?? 0) ? const Color(0xFFF59E0B) : AppColors.faint)),
            ))),
          ])),
          const SizedBox(height: 10),
        ])),
        const SectionLabel('Дахин энэ компанид дадлага хийх уу?'),
        Row(children: [
          Expanded(child: _ynBtn('Тийм',  _wouldReturn == true,  () => setState(() => _wouldReturn = true))),
          const SizedBox(width: 10),
          Expanded(child: _ynBtn('Үгүй', _wouldReturn == false, () => setState(() => _wouldReturn = false))),
        ]),
        const SizedBox(height: 20),
        const SectionLabel('Ерөнхий сэтгэгдэл'),
        TextField(controller: _comment, maxLines: 4, decoration: const InputDecoration(hintText: 'Дадлагын туршлагаа дэлгэрэнгүй бичнэ үү...')),
        const SizedBox(height: 28),
        PrimaryButton(label: 'Үнэлгээ илгээх', loading: _saving, onTap: _submit),
        const SizedBox(height: 30),
      ])),
    );
  }

  Widget _ynBtn(String l, bool on, VoidCallback t) => GestureDetector(onTap: t, child: AnimatedContainer(
    duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: on ? AppColors.primary : AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: on ? AppColors.primary : AppColors.border, width: on ? 1.5 : 0.5)),
    child: Text(l, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: on ? AppColors.white : AppColors.muted)),
  ));

  Future<void> _submit() async {
    if (_scores.values.any((v) => v == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Бүх үнэлгээг дүүргэнэ үү'), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
      return;
    }
    if (_wouldReturn == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Дахин хийх эсэхийг сонгоно уу'), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _saving = true);
    try {
      final intern = await InternshipService().getInternship(widget.internshipId);
      final companyId = intern['company_id'] as String? ?? '';
      await ReviewService().submit(
        internshipId: widget.internshipId,
        companyId: companyId,
        env: _scores['env']!,
        mentor: _scores['mentor']!,
        learn: _scores['learn']!,
        relation: _scores['relation']!,
        wouldReturn: _wouldReturn!,
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      );
      setState(() => _done = true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override void dispose() { _comment.dispose(); super.dispose(); }
}

// ─────────────────────────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();
    final mn     = locale.isMN;

    final name  = auth.displayName.isEmpty ? (mn ? 'Хэрэглэгч' : 'User') : auth.displayName;
    final email = auth.profile?['email'] as String? ?? '';
    final sub   = auth.isStudent
      ? '${auth.profile?['university'] ?? ''}'
      : '${auth.profile?['industry'] ?? ''}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, scrolledUnderElevation: 0, centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          onPressed: () => context.go(auth.isCompany ? '/company/home' : '/home'),
        ),
        title: Text(mn ? 'Миний профайл' : 'My Profile',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.text),
            onPressed: () => _showSettingsSheet(context, auth, locale),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // ── Header ──────────────────────────────────────────
          Container(
            width: double.infinity, color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Column(children: [
              _AvatarPicker(name: name, colorIndex: auth.isCompany ? 2 : 0, uid: auth.uid)
                .animate().scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 14),
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 3),
              if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.faint)),
              ],
              const SizedBox(height: 18),
              SizedBox(width: 160, child: ElevatedButton(
                onPressed: () => _showEditProfile(context, auth),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(0, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(mn ? 'Профайл засах' : 'Edit Profile', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              )),
            ]),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 10),

          _MenuSection(items: [
            if (auth.isStudent) _MenuItem(icon: Icons.article_outlined, iconColor: AppColors.primary, iconBg: AppColors.primaryLight, label: 'CV Maker', onTap: () => context.push('/cv')),
            _MenuItem(icon: Icons.work_history_outlined, iconColor: AppColors.green, iconBg: AppColors.greenLight, label: mn ? 'Дадлагийн түүх' : 'Internship History', onTap: () => context.push('/internships')),
            if (auth.isStudent) _MenuItem(icon: Icons.calendar_month_outlined, iconColor: AppColors.amber, iconBg: AppColors.amberLight, label: mn ? 'Хичээл хуваарь' : 'Class Schedule', onTap: () => context.push('/schedule')),
          ]).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 10),

          _MenuSection(items: [
            _MenuItem(icon: Icons.language_rounded, iconColor: AppColors.purple, iconBg: AppColors.purpleLight, label: mn ? 'Хэл' : 'Language', trailing: _LangBadge(isMN: mn), onTap: () => _showLangSheet(context, locale)),
            _MenuItem(icon: Icons.lock_outline_rounded, iconColor: AppColors.muted, iconBg: AppColors.bg, label: mn ? 'Нууц үг солих' : 'Change Password', onTap: () => _showChangePassword(context, auth, mn)),
            _MenuItem(icon: Icons.help_outline_rounded, iconColor: AppColors.primary, iconBg: AppColors.primaryLight, label: mn ? 'Тусламж' : 'Help & Support', onTap: () => _showHelp(context, mn)),
          ]).animate().fadeIn(delay: 180.ms),

          const SizedBox(height: 10),

          _MenuSection(items: [
            _MenuItem(icon: Icons.logout_rounded, iconColor: AppColors.red, iconBg: AppColors.redLight, label: mn ? 'Гарах' : 'Log Out', labelColor: AppColors.red, showArrow: false, onTap: () => _confirmLogout(context, auth, mn)),
          ]).animate().fadeIn(delay: 260.ms),

          const SizedBox(height: 24),
          Text(mn ? 'Апп хувилбар 1.0.0' : 'App version 1.0.0', style: const TextStyle(fontSize: 11, color: AppColors.faint)),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  void _showLangSheet(BuildContext ctx, LocaleProvider locale) {
    showModalBottomSheet(context: ctx, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Icon(Icons.language_rounded, size: 36, color: AppColors.primary),
        const SizedBox(height: 10),
        const Text('Хэл сонгох / Choose Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Consumer<LocaleProvider>(builder: (_, loc, __) => Column(children: [
          _LangOption(flag: '🇲🇳', name: 'Монгол', code: 'МН', selected: loc.isMN, onTap: () { loc.set(true); Navigator.pop(sheetCtx); }),
          const SizedBox(height: 10),
          _LangOption(flag: '🇬🇧', name: 'English', code: 'EN', selected: !loc.isMN, onTap: () { loc.set(false); Navigator.pop(sheetCtx); }),
        ])),
        const SizedBox(height: 16),
      ])));
  }

  void _showEditProfile(BuildContext ctx, AuthProvider auth) {
    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditProfileSheet(auth: auth));
  }

  void _showSettingsSheet(BuildContext ctx, AuthProvider auth, LocaleProvider locale) {
    showModalBottomSheet(context: ctx, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Consumer<LocaleProvider>(builder: (_, loc, __) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(children: [
          const Text('Тохиргоо', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const Spacer(),
          _LangBadge(isMN: loc.isMN),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () { loc.toggle(); Navigator.pop(sheetCtx); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
              child: Text(loc.isMN ? 'EN болгох' : 'MN болгох',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary))),
          ),
        ]),
        const SizedBox(height: 20),
      ]))));
  }

  void _showChangePassword(BuildContext ctx, AuthProvider auth, bool mn) {
    final newPw = TextEditingController();
    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(builder: (_, setState) {
        bool saving = false;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(mn ? 'Нууц үг солих' : 'Change Password', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            FieldLabel(mn ? 'Шинэ нууц үг' : 'New password'),
            TextField(controller: newPw, obscureText: true,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_reset_rounded, size: 18, color: AppColors.faint))),
            const SizedBox(height: 20),
            PrimaryButton(label: mn ? 'Солих' : 'Update', loading: saving, onTap: () async {
              if (newPw.text.length < 6) return;
              setState(() => saving = true);
              final ok = await auth.changePassword(newPw.text);
              if (sheetCtx.mounted) {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(ok ? (mn ? 'Нууц үг шинэчлэгдлээ ✓' : 'Password updated ✓') : (auth.error ?? 'Алдаа')),
                  backgroundColor: ok ? AppColors.green : AppColors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            }),
          ]),
        );
      }),
    );
  }

  void _showHelp(BuildContext ctx, bool mn) => showModalBottomSheet(context: ctx,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 20),
      const Icon(Icons.help_outline_rounded, size: 40, color: AppColors.primary),
      const SizedBox(height: 12),
      Text(mn ? 'Тусламж' : 'Help & Support', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text(mn ? 'Асуудал гарвал support@oyuntan.mn руу имэйл илгээнэ үү.' : 'For issues, email support@oyuntan.mn.',
        style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.6), textAlign: TextAlign.center),
      const SizedBox(height: 24),
    ])));

  void _confirmLogout(BuildContext ctx, AuthProvider auth, bool mn) => showModalBottomSheet(context: ctx,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 20),
      Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.redLight, shape: BoxShape.circle),
        child: const Icon(Icons.logout_rounded, color: AppColors.red, size: 28)),
      const SizedBox(height: 14),
      Text(mn ? 'Гарах уу?' : 'Log out?', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(mn ? 'Та апп-аас гарах гэж байна.' : 'You are about to log out.',
        style: const TextStyle(fontSize: 13, color: AppColors.muted)),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: Text(mn ? 'Болих' : 'Cancel'))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(
          onPressed: () async { Navigator.pop(ctx); await auth.logout(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text(mn ? 'Гарах' : 'Log out'),
        )),
      ]),
    ])));
}

// ── Menu section ──────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
    child: Column(children: items.asMap().entries.map((e) => Column(children: [
      e.value,
      if (e.key != items.length - 1) const Divider(height: 1, indent: 56, endIndent: 16),
    ])).toList()),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.iconColor, required this.iconBg, required this.label, this.labelColor, this.trailing, this.showArrow = true, required this.onTap});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: iconColor)),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor ?? AppColors.text))),
        if (trailing != null) trailing!,
        if (showArrow) ...[const SizedBox(width: 6), const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faint)],
      ]),
    ),
  );
}

class _LangBadge extends StatelessWidget {
  final bool isMN;
  const _LangBadge({required this.isMN});
  @override Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
    child: Text(isMN ? '🇲🇳 МН' : '🇬🇧 EN', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
  );
}

class _LangOption extends StatelessWidget {
  final String flag, name, code;
  final bool selected;
  final VoidCallback onTap;
  const _LangOption({required this.flag, required this.name, required this.code, required this.selected, required this.onTap});
  @override Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: selected ? AppColors.primaryLight : AppColors.white,
        borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 0.5)),
      child: Row(children: [
        Text(flag, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? AppColors.primaryDark : AppColors.text)),
        const Spacer(),
        Text(code, style: TextStyle(fontSize: 12, color: selected ? AppColors.primary : AppColors.faint, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, size: 20, color: selected ? AppColors.primary : AppColors.faint),
      ]),
    ),
  );
}

// ── Edit Profile Sheet ─────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final AuthProvider auth;
  const _EditProfileSheet({required this.auth});
  @override State<_EditProfileSheet> createState() => _EditProfileSheetState();
}
class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _phone, _name;
  bool _saving = false;

  @override void initState() {
    super.initState();
    final p = widget.auth.profile ?? {};
    _phone = TextEditingController(text: p['phone'] as String? ?? '');
    _name  = TextEditingController(text: widget.auth.displayName);
  }

  @override Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 20),
      const Text('Профайл засах', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      const FieldLabel('Нэр'),
      TextField(controller: _name, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline, size: 18, color: AppColors.faint))),
      const FieldLabel('Утасны дугаар'),
      TextField(controller: _phone, keyboardType: TextInputType.phone,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined, size: 18, color: AppColors.faint), hintText: '+976...')),
      const SizedBox(height: 20),
      PrimaryButton(label: 'Хадгалах', loading: _saving, onTap: () async {
        setState(() => _saving = true);
        try {
          final auth = widget.auth;
          final uid  = auth.uid;
          final path = auth.isStudent ? '/students/$uid' : '/companies/$uid';
          final data = auth.isStudent
              ? {'firstName': _name.text.trim(), 'phone': _phone.text.trim()}
              : {'name': _name.text.trim(), 'phone': _phone.text.trim()};
          await ApiClient.put(path, data);
          await auth.refreshProfile();
          if (ctx.mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: const Text('Профайл шинэчлэгдлээ ✓'),
              backgroundColor: AppColors.green, behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ));
          }
        } catch (_) {}
        finally { if (mounted) setState(() => _saving = false); }
      }),
    ]),
  );

  @override void dispose() { _phone.dispose(); _name.dispose(); super.dispose(); }
}

// ── NOTIFICATION SCREEN ───────────────────────────────────────
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override State<NotificationScreen> createState() => _NotifState();
}
class _NotifState extends State<NotificationScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override void initState() { super.initState(); _load(); }
  void _load() {
    final uid = context.read<AuthProvider>().uid;
    setState(() { _future = NotificationService().getNotifications(uid); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мэдэгдэл'),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationService().markAllRead();
              _load();
            },
            child: const Text('Бүгдийг уншсан', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (c, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
          final notifs = snap.data ?? [];
          if (notifs.isEmpty) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_none_outlined, size: 48, color: AppColors.faint),
              SizedBox(height: 12),
              Text('Мэдэгдэл байхгүй', style: TextStyle(color: AppColors.muted)),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifs.length,
              itemBuilder: (c, i) {
                final d    = notifs[i];
                final type = d['type'] as String? ?? '';
                final isNew = !(d['read'] as bool? ?? false);
                return Padding(padding: const EdgeInsets.only(bottom: 8), child: GestureDetector(
                  onTap: () async {
                    await NotificationService().markRead(d['id'] as String);
                    _load();
                  },
                  child: AppCard(color: isNew ? AppColors.primaryLight : AppColors.white,
                    child: Row(children: [
                      Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                        child: Icon(_typeIcon(type), size: 18, color: AppColors.white)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_typeTitle(type), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(_typeSub(type),   style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      ])),
                      if (isNew) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    ]),
                  ),
                ));
              },
            ),
          );
        },
      ),
    );
  }

  IconData _typeIcon(String t)  => switch(t) { 'new_application' => Icons.person_add_outlined, 'application_accepted' => Icons.check_circle_outline, _ => Icons.notifications_outlined };
  String   _typeTitle(String t) => switch(t) { 'new_application' => 'Шинэ CV хүсэлт', 'application_accepted' => 'Хүсэлт хүлээн авлаа', _ => 'Мэдэгдэл' };
  String   _typeSub(String t)   => switch(t) { 'new_application' => 'Таны зарт шинэ оюутан хүсэлт илгээлээ', 'application_accepted' => 'Компани таны хүсэлтийг хүлээн авлаа', _ => '' };
}

// ── Avatar Picker ─────────────────────────────────────────────
class _AvatarPicker extends StatefulWidget {
  final String name;
  final int colorIndex;
  final String uid;
  const _AvatarPicker({required this.name, required this.colorIndex, required this.uid});
  @override State<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<_AvatarPicker> {
  Uint8List? _bytes;
  String get _prefKey => 'avatar_image_b64_${widget.uid}';

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final b64 = prefs.getString(_prefKey);
    if (b64 != null && mounted) {
      setState(() => _bytes = base64Decode(b64));
    }
  }

  Future<void> _pick() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, base64Encode(bytes));
    if (mounted) setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _pick,
    child: Stack(children: [
      _bytes != null
          ? CircleAvatar(radius: 42, backgroundImage: MemoryImage(_bytes!))
          : AvatarCircle(name: widget.name, size: 84, colorIndex: widget.colorIndex),
      Positioned(
        right: 0, bottom: 0,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2)),
          child: const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
        ),
      ),
    ]),
  );
}
