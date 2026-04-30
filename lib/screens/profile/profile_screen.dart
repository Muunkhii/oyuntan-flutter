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

// ignore_for_file: use_build_context_synchronously

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
    if (_done) {
      return Scaffold(body: SafeArea(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
    }

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
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.red)); }
    } finally {
      if (mounted) { setState(() => _saving = false); }
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
          if (auth.isCompany)
            Container(
              color: Colors.white,
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    _CoverPhotoPicker(uid: auth.uid),
                    Positioned(
                      bottom: -44,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12)]),
                        child: _AvatarPicker(name: name, colorIndex: 2, uid: auth.uid, isCompany: true)
                          .animate().scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.elasticOut),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 52),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: Column(children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                    const SizedBox(height: 3),
                    if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.faint)),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(width: 200, child: ElevatedButton.icon(
                      onPressed: () => _showEditProfile(context, auth),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(0, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      label: Text(mn ? 'Профайл засах' : 'Edit Profile', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    )),
                  ]),
                ),
              ]),
            ).animate().fadeIn(duration: 400.ms)
          else
            Container(
              width: double.infinity, color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(children: [
                _AvatarPicker(name: name, colorIndex: 0, uid: auth.uid, isCompany: false)
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
                SizedBox(width: 200, child: ElevatedButton.icon(
                  onPressed: () => context.push('/cv'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(0, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  label: Text(mn ? 'Профайл засах' : 'Edit Profile', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                )),
              ]),
            ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 10),

          _MenuSection(items: [
            if (auth.isStudent) _MenuItem(icon: Icons.person_pin_outlined, iconColor: AppColors.primary, iconBg: AppColors.primaryLight, label: mn ? 'Дэлгэрэнгүй профайл / CV' : 'Full Profile / CV', onTap: () => context.push('/cv')),
            _MenuItem(icon: Icons.work_history_outlined, iconColor: AppColors.green, iconBg: AppColors.greenLight, label: mn ? 'Дадлагийн түүх' : 'Internship History', onTap: () => context.push(auth.isCompany ? '/company/interns' : '/internships')),
            if (auth.isStudent) _MenuItem(icon: Icons.calendar_month_outlined, iconColor: AppColors.amber, iconBg: AppColors.amberLight, label: mn ? 'Хичээл хуваарь' : 'Class Schedule', onTap: () => context.push('/schedule')),
            if (auth.isCompany) _MenuItem(icon: Icons.quiz_outlined, iconColor: AppColors.amber, iconBg: AppColors.amberLight, label: mn ? 'Мэргэжлийн шалгалт' : 'Professional Assessment', onTap: () => _showAssessmentEditor(context, auth)),
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

  void _showAssessmentEditor(BuildContext ctx, AuthProvider auth) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AssessmentEditorSheet(companyId: auth.uid),
    );
  }

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
  late final TextEditingController _name, _phone, _desc, _location, _website, _employeeCount, _history, _foundedYear;
  bool _saving = false;

  @override void initState() {
    super.initState();
    final p = widget.auth.profile ?? {};
    _name          = TextEditingController(text: widget.auth.displayName);
    _phone         = TextEditingController(text: p['phone']          as String? ?? '');
    _desc          = TextEditingController(text: p['description']    as String? ?? '');
    _location      = TextEditingController(text: p['location']       as String? ?? '');
    _website       = TextEditingController(text: p['website']        as String? ?? '');
    final ec = p['employee_count'];
    _employeeCount = TextEditingController(text: ec != null && ec != 0 ? ec.toString() : '');
    _history       = TextEditingController(text: p['history']        as String? ?? '');
    final fy = p['founded_year'];
    _foundedYear   = TextEditingController(text: fy != null && fy != 0 ? fy.toString() : '');
  }

  @override Widget build(BuildContext ctx) {
    final isCompany = widget.auth.isCompany;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text(isCompany ? 'Компани засах' : 'Профайл засах',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),

        FieldLabel(isCompany ? 'Компанийн нэр' : 'Нэр'),
        TextField(controller: _name,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.business_outlined, size: 18, color: AppColors.faint))),

        const FieldLabel('Утасны дугаар'),
        TextField(controller: _phone, keyboardType: TextInputType.phone,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined, size: 18, color: AppColors.faint), hintText: '+976...')),

        if (isCompany) ...[
          const FieldLabel('Компанийн танилцуулга'),
          TextField(controller: _desc, maxLines: 4,
            decoration: const InputDecoration(hintText: 'Компани болон дадлагын хөтөлбөрийн тухай...')),

          const FieldLabel('Байршил'),
          TextField(controller: _location,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.location_on_outlined, size: 18, color: AppColors.faint), hintText: 'Улаанбаатар, Монгол')),

          const FieldLabel('Вэбсайт'),
          TextField(controller: _website, keyboardType: TextInputType.url,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.language_outlined, size: 18, color: AppColors.faint), hintText: 'https://...')),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FieldLabel('Ажилчдын тоо'),
              TextField(controller: _employeeCount, keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.people_outline_rounded, size: 18, color: AppColors.faint), hintText: '150')),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FieldLabel('Үүсгэн байгуулагдсан он'),
              TextField(controller: _foundedYear, keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.faint), hintText: '2015')),
            ])),
          ]),

          const FieldLabel('Компанийн намтар'),
          TextField(controller: _history, maxLines: 4,
            decoration: const InputDecoration(hintText: 'Компани хэзээ, хэрхэн үүсгэгдсэн, үйл ажиллагааны чиглэл...')),
        ],

        const SizedBox(height: 24),
        PrimaryButton(label: 'Хадгалах', loading: _saving, onTap: _save),
      ])),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final auth = widget.auth;
      final uid  = auth.uid;
      final Map<String, dynamic> data;
      if (auth.isStudent) {
        data = {'firstName': _name.text.trim(), 'phone': _phone.text.trim()};
      } else {
        data = {
          'name':        _name.text.trim(),
          'phone':       _phone.text.trim(),
          'description': _desc.text.trim(),
          'location':    _location.text.trim(),
          'website':     _website.text.trim(),
          if (_employeeCount.text.trim().isNotEmpty)
            'employeeCount': int.tryParse(_employeeCount.text.trim()) ?? 0,
          if (_history.text.trim().isNotEmpty)
            'history': _history.text.trim(),
          if (_foundedYear.text.trim().isNotEmpty)
            'foundedYear': int.tryParse(_foundedYear.text.trim()) ?? 0,
        };
      }
      await ApiClient.put(auth.isStudent ? '/students/$uid' : '/companies/$uid', data);
      await auth.refreshProfile();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Профайл шинэчлэгдлээ ✓'),
          backgroundColor: AppColors.green, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override void dispose() {
    for (final c in [_name, _phone, _desc, _location, _website, _employeeCount, _history, _foundedYear]) { c.dispose(); }
    super.dispose();
  }
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
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
          }
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
  final bool isCompany;
  const _AvatarPicker({required this.name, required this.colorIndex, required this.uid, required this.isCompany});
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
      return;
    }
    // Try fetching from server if not cached locally
    try {
      final endpoint = widget.isCompany
          ? '/companies/${widget.uid}'
          : '/students/${widget.uid}';
      final data = await ApiClient.get(endpoint) as Map<String, dynamic>?;
      final photo = data?['photo'] as String?;
      if (photo != null && photo.isNotEmpty && mounted) {
        final decoded = base64Decode(photo);
        await prefs.setString(_prefKey, photo);
        setState(() => _bytes = decoded);
      }
    } catch (_) {}
  }

  Future<void> _pick() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    final b64   = base64Encode(bytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, b64);
    if (mounted) setState(() => _bytes = bytes);
    // Sync photo to server so other users can see it
    final endpoint = widget.isCompany
        ? '/companies/${widget.uid}'
        : '/students/${widget.uid}';
    try { await ApiClient.put(endpoint, {'photo': b64}); } catch (_) {}
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

// ── Cover Photo Picker ────────────────────────────────────────
class _CoverPhotoPicker extends StatefulWidget {
  final String uid;
  const _CoverPhotoPicker({required this.uid});
  @override State<_CoverPhotoPicker> createState() => _CoverPhotoPickerState();
}

class _CoverPhotoPickerState extends State<_CoverPhotoPicker> {
  Uint8List? _bytes;
  String get _prefKey => 'cover_b64_${widget.uid}';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final b64 = prefs.getString(_prefKey);
    if (b64 != null && mounted) {
      setState(() => _bytes = base64Decode(b64));
      return;
    }
    try {
      final data = await ApiClient.get('/companies/${widget.uid}') as Map<String, dynamic>?;
      final cover = data?['cover_photo'] as String?;
      if (cover != null && cover.isNotEmpty && mounted) {
        await prefs.setString(_prefKey, cover);
        setState(() => _bytes = base64Decode(cover));
      }
    } catch (_) {}
  }

  Future<void> _pick() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 75, maxWidth: 1200);
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    final b64 = base64Encode(bytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, b64);
    if (mounted) setState(() => _bytes = bytes);
    try { await ApiClient.put('/companies/${widget.uid}', {'coverPhoto': b64}); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _pick,
    child: Stack(children: [
      Container(
        width: double.infinity, height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          gradient: _bytes == null
              ? const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          image: _bytes != null
              ? DecorationImage(image: MemoryImage(_bytes!), fit: BoxFit.cover)
              : null,
        ),
      ),
      Positioned(
        right: 12, bottom: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.camera_alt_outlined, size: 13, color: Colors.white),
            SizedBox(width: 5),
            Text('Арын зураг', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    ]),
  );
}

// ── Assessment Editor Sheet ───────────────────────────────────
class _AssessmentEditorSheet extends StatefulWidget {
  final String companyId;
  const _AssessmentEditorSheet({required this.companyId});
  @override State<_AssessmentEditorSheet> createState() => _AssessmentEditorSheetState();
}

class _AssessmentEditorSheetState extends State<_AssessmentEditorSheet> {
  final List<TextEditingController> _controllers = [];
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final qs = await AssessmentService().getCompanyQuestions(widget.companyId);
    if (!mounted) return;
    setState(() {
      for (final q in qs) {
        _controllers.add(TextEditingController(text: q['question'] as String? ?? ''));
      }
      if (_controllers.isEmpty) _controllers.add(TextEditingController());
      _loading = false;
    });
  }

  void _addQuestion() {
    if (_controllers.length >= 10) return;
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeQuestion(int i) {
    if (_controllers.length <= 1) return;
    _controllers[i].dispose();
    setState(() => _controllers.removeAt(i));
  }

  Future<void> _save() async {
    final questions = _controllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .map((t) => <String, dynamic>{'question': t, 'type': 'text'})
        .toList();
    setState(() => _saving = true);
    try {
      await AssessmentService().saveCompanyQuestions(widget.companyId, questions);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Шалгалт хадгалагдлаа ✓'),
          backgroundColor: AppColors.teal, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'Алдаа гарлаа'),
          backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(children: [
        // ── Handle ──────────────────────────────────────────
        const SizedBox(height: 12),
        Center(child: Container(width: 44, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        // ── Header ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.quiz_outlined, color: AppColors.amber, size: 22)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Мэргэжлийн шалгалт',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('Оюутнуудад асуух асуултуудаа бэлдэнэ үү (max 10)',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ])),
          ]),
        ),
        const Divider(height: 24),
        // ── List ────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
              : ListView(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, kb + 16),
                  children: [
                    ..._controllers.asMap().entries.map((e) {
                      final i = e.key;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 0.5)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              width: 24, height: 24,
                              decoration: const BoxDecoration(
                                color: AppColors.primary, shape: BoxShape.circle),
                              child: Center(child: Text('${i + 1}',
                                style: const TextStyle(
                                  fontSize: 11, color: Colors.white,
                                  fontWeight: FontWeight.w700)))),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Асуулт',
                              style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: AppColors.muted))),
                            GestureDetector(
                              onTap: () => _removeQuestion(i),
                              child: const Icon(Icons.close_rounded,
                                size: 18, color: AppColors.muted)),
                          ]),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: e.value,
                            maxLines: null,
                            minLines: 2,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: 'Асуултаа энд бичнэ үү...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.border, width: 0.5)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.border, width: 0.5)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            ),
                          ),
                        ]),
                      );
                    }),
                    const SizedBox(height: 4),
                    if (_controllers.length < 10)
                      GestureDetector(
                        onTap: _addQuestion,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 1.5),
                            borderRadius: BorderRadius.circular(12)),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                              SizedBox(width: 6),
                              Text('Асуулт нэмэх',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                            ]),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight,
                        borderRadius: BorderRadius.circular(10)),
                      child: const Row(children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.amber),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          'Оюутнуудад дүн харагдахгүй. Зөвхөн та үзэх боломжтой.',
                          style: TextStyle(fontSize: 11, color: AppColors.amber))),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
        ),
        // ── Buttons ─────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
          child: Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Болих'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                  : const Text('Хадгалах'))),
          ]),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }
}
