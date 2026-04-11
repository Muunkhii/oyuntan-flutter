// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushEnabled  = true;
  bool _emailEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled  = p.getBool('push_notif')  ?? true;
      _emailEnabled = p.getBool('email_notif') ?? true;
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('push_notif',  _pushEnabled);
    await p.setBool('email_notif', _emailEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final profile   = auth.profile ?? {};
    final isStudent = auth.isStudent;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        automaticallyImplyLeading: false,
        title: const Text('Профайл'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + name
          Center(
            child: Column(children: [
              _Avatar(name: auth.displayName),
              const SizedBox(height: 12),
              Text(auth.displayName.isEmpty ? '—' : auth.displayName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(isStudent ? 'Оюутан' : 'Компани',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(height: 24),

          // Profile info
          if (isStudent) ..._studentInfo(profile)
          else           ..._companyInfo(profile),
          const SizedBox(height: 24),

          // Settings
          const SectionLabel('Тохиргоо'),
          _ToggleRow('Push мэдэгдэл', _pushEnabled, (v) {
            setState(() => _pushEnabled = v);
            _savePrefs();
          }),
          _ToggleRow('Имэйл мэдэгдэл', _emailEnabled, (v) {
            setState(() => _emailEnabled = v);
            _savePrefs();
          }),
          const SizedBox(height: 16),

          // Account actions
          const SectionLabel('Бүртгэл'),
          _ActionRow('Нууц үг солих',
              Icons.lock_outline, () => _showChangePassword(context)),
          _ActionRow('Профайл засах',
              Icons.edit_outlined, () => _showEditProfile(context, auth, profile, isStudent)),
          if (isStudent)
            _ActionRow('CV Maker', Icons.description_outlined,
                () => context.push('/cv')),
          const SizedBox(height: 8),

          // Logout
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, auth),
            icon: const Icon(Icons.logout, size: 18, color: AppColors.red),
            label: const Text('Гарах',
                style: TextStyle(color: AppColors.red, fontSize: 14)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.red, width: 0.5),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _studentInfo(Map<String, dynamic> p) => [
    const SectionLabel('Хувийн мэдээлэл'),
    _InfoRow('Их сургууль', p['university'] as String? ?? '—'),
    _InfoRow('Мэргэжил',    p['major']      as String? ?? '—'),
    _InfoRow('Курс',        '${p['year'] ?? '—'}-р курс'),
    _InfoRow('Имэйл',       p['email']      as String? ?? '—'),
    if ((p['bio'] as String? ?? '').isNotEmpty) ...[
      const SizedBox(height: 16),
      const SectionLabel('Товч танилцуулга'),
      Text(p['bio'] as String,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
    ],
    if ((p['skills'] as List?)?.isNotEmpty == true) ...[
      const SizedBox(height: 16),
      const SectionLabel('Ур чадвар'),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: (p['skills'] as List).cast<String>().map((s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5)),
          child: Text(s, style: const TextStyle(fontSize: 12)),
        )).toList(),
      ),
    ],
  ];

  List<Widget> _companyInfo(Map<String, dynamic> p) => [
    const SectionLabel('Компанийн мэдээлэл'),
    _InfoRow('Нэр',    p['name']        as String? ?? '—'),
    _InfoRow('Салбар', p['industry']    as String? ?? '—'),
    _InfoRow('Хэмжээ', p['size']        as String? ?? '—'),
    _InfoRow('Имэйл',  p['email']       as String? ?? '—'),
    if ((p['description'] as String? ?? '').isNotEmpty) ...[
      const SizedBox(height: 16),
      const SectionLabel('Тухай'),
      Text(p['description'] as String,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
    ],
  ];

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Гарах', style: TextStyle(fontSize: 16)),
        content: const Text('Та гарахдаа итгэлтэй байна уу?',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Болих')),
          ElevatedButton(
              onPressed: () { Navigator.pop(context); auth.logout(); },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
              child: const Text('Гарах')),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Нууц үг солих',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            const Text('Шинэ нууц үг',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: newCtrl,
              obscureText: obscure,
              decoration: InputDecoration(
                hintText: '6+ тэмдэгт',
                suffixIcon: IconButton(
                  icon: Icon(obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                      size: 18, color: AppColors.textTertiary),
                  onPressed: () => setSt(() => obscure = !obscure),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Баталгаажуулах',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
                controller: confCtrl,
                obscureText: obscure,
                decoration: const InputDecoration(hintText: 'Дахин оруулах')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (newCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Нууц үг 6-аас дээш тэмдэгттэй байх ёстой'),
                    backgroundColor: AppColors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                if (newCtrl.text != confCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Нууц үг таарахгүй байна'),
                    backgroundColor: AppColors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                try {
                  await AuthService().changePassword(newCtrl.text);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Нууц үг амжилттай солигдлоо'),
                      backgroundColor: AppColors.teal,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Алдаа: ${e.toString()}'),
                      backgroundColor: AppColors.red,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
              child: const Text('Хадгалах'),
            ),
          ]),
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, AuthProvider auth,
      Map<String, dynamic> profile, bool isStudent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditProfileSheet(auth: auth, profile: profile, isStudent: isStudent),
    );
  }
}

// ── Widgets ───────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});
  @override
  Widget build(BuildContext context) {
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.purpleLight,
      child: Text(initials.isEmpty ? '?' : initials,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.purple)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary))),
      Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.black,
      ),
    ]),
  );
}

class _ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionRow(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
      ]),
    ),
  );
}

// ── Edit Profile Sheet ────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final AuthProvider auth;
  final Map<String, dynamic> profile;
  final bool isStudent;
  const _EditProfileSheet({required this.auth, required this.profile, required this.isStudent});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final Map<String, TextEditingController> _ctrls;
  final _skillCtrl = TextEditingController();
  late List<String> _skills;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    if (widget.isStudent) {
      _ctrls = {
        'firstName':  TextEditingController(text: p['firstName']  as String? ?? ''),
        'lastName':   TextEditingController(text: p['lastName']   as String? ?? ''),
        'university': TextEditingController(text: p['university'] as String? ?? ''),
        'major':      TextEditingController(text: p['major']      as String? ?? ''),
        'year':       TextEditingController(text: '${p['year'] ?? ''}'),
        'bio':        TextEditingController(text: p['bio']        as String? ?? ''),
      };
      _skills = List<String>.from((p['skills'] as List?) ?? []);
    } else {
      _ctrls = {
        'name':        TextEditingController(text: p['name']        as String? ?? ''),
        'industry':    TextEditingController(text: p['industry']    as String? ?? ''),
        'size':        TextEditingController(text: p['size']        as String? ?? ''),
        'description': TextEditingController(text: p['description'] as String? ?? ''),
        'website':     TextEditingController(text: p['website']     as String? ?? ''),
      };
      _skills = [];
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  void _addSkill(String s) {
    final sk = s.trim();
    if (sk.isNotEmpty && !_skills.contains(sk)) setState(() => _skills.add(sk));
    _skillCtrl.clear();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = <String, dynamic>{
      for (final e in _ctrls.entries) e.key: e.value.text.trim(),
    };
    if (widget.isStudent) {
      data['year'] = int.tryParse(data['year'] as String? ?? '') ?? 1;
      data['skills'] = List<String>.from(_skills);
    }
    final ok = await widget.auth.updateProfile(data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Профайл шинэчлэгдлээ'),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.auth.error ?? 'Алдаа гарлаа'),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _field(String label, String key, {TextInputType? type, int maxLines = 1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrls[key],
          keyboardType: type,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: label),
        ),
        const SizedBox(height: 12),
      ]);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.isStudent ? 'Профайл засах' : 'Компани мэдээлэл засах',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),

          if (widget.isStudent) ...[
            _field('Нэр', 'firstName'),
            _field('Овог', 'lastName'),
            _field('Их сургууль', 'university'),
            _field('Мэргэжил', 'major'),
            _field('Курс', 'year', type: TextInputType.number),
            _field('Товч танилцуулга', 'bio', maxLines: 3),
            const Text('Ур чадвар',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _skillCtrl,
                  decoration: const InputDecoration(hintText: 'React, Figma...'),
                  onSubmitted: _addSkill,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => _addSkill(_skillCtrl.text),
                icon: const Icon(Icons.add_circle_outline, color: AppColors.black),
              ),
            ]),
            if (_skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: _skills.map((s) => Chip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _skills.remove(s)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
            const SizedBox(height: 12),
          ] else ...[
            _field('Компанийн нэр', 'name'),
            _field('Салбар', 'industry'),
            _field('Ажилтны тоо', 'size'),
            _field('Вебсайт', 'website'),
            _field('Компанийн тухай', 'description', maxLines: 3),
          ],

          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                : const Text('Хадгалах'),
          ),
        ]),
      ),
    );
  }
}
