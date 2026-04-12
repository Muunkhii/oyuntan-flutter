// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled    = true;
  bool _emailEnabled   = true;
  bool _darkMode       = false;
  bool _mnLang         = true;
  bool _locationEnabled = true;
  String _fontSize     = 'Дунд';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled    = p.getBool('push_notif')    ?? true;
      _emailEnabled   = p.getBool('email_notif')   ?? true;
      _darkMode       = p.getBool('dark_mode')     ?? false;
      _mnLang         = p.getBool('mn_lang')       ?? true;
      _locationEnabled = p.getBool('location')     ?? true;
      _fontSize       = p.getString('font_size')   ?? 'Дунд';
    });
  }

  Future<void> _save(String key, dynamic value) async {
    final p = await SharedPreferences.getInstance();
    if (value is bool)   await p.setBool(key, value);
    if (value is String) await p.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Тохиргоо'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Мэдэгдэл ──────────────────────────────────
          const _GroupTitle('Мэдэгдэл'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.notifications_active_outlined,
              iconColor: AppColors.primary,
              iconBg: AppColors.primaryLight,
              label: 'Push мэдэгдэл',
              sub: 'Шинэ өргөдөл, хариулт',
              value: _pushEnabled,
              onChanged: (v) {
                setState(() => _pushEnabled = v);
                _save('push_notif', v);
              },
            ),
            const Divider(height: 1, indent: 66),
            _SwitchTile(
              icon: Icons.email_outlined,
              iconColor: AppColors.teal,
              iconBg: AppColors.tealLight,
              label: 'Имэйл мэдэгдэл',
              sub: 'Дадлагын мэдэгдлүүд',
              value: _emailEnabled,
              onChanged: (v) {
                setState(() => _emailEnabled = v);
                _save('email_notif', v);
              },
            ),
          ]),

          const SizedBox(height: 16),

          // ── Дүрслэл ───────────────────────────────────
          const _GroupTitle('Дүрслэл'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.dark_mode_outlined,
              iconColor: AppColors.textPrimary,
              iconBg: AppColors.border,
              label: 'Харанхуй горим',
              sub: 'Нүдэнд тааламжтай',
              value: _darkMode,
              onChanged: (v) {
                setState(() => _darkMode = v);
                _save('dark_mode', v);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Дараагийн нэвтрэлтээс хэрэгжинэ'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const Divider(height: 1, indent: 66),
            _SelectTile(
              icon: Icons.text_fields_outlined,
              iconColor: AppColors.purple,
              iconBg: AppColors.purpleLight,
              label: 'Фонтын хэмжээ',
              value: _fontSize,
              options: const ['Жижиг', 'Дунд', 'Том'],
              onChanged: (v) {
                setState(() => _fontSize = v);
                _save('font_size', v);
              },
            ),
          ]),

          const SizedBox(height: 16),

          // ── Хэл & байршил ─────────────────────────────
          const _GroupTitle('Хэл & Нууцлал'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.language_outlined,
              iconColor: AppColors.amber,
              iconBg: AppColors.amberLight,
              label: 'Монгол хэл',
              sub: _mnLang ? 'Монгол' : 'English',
              value: _mnLang,
              onChanged: (v) {
                setState(() => _mnLang = v);
                _save('mn_lang', v);
              },
            ),
            const Divider(height: 1, indent: 66),
            _SwitchTile(
              icon: Icons.location_on_outlined,
              iconColor: AppColors.coral,
              iconBg: AppColors.coralLight,
              label: 'Байршил',
              sub: 'Ойролцоо дадлага олох',
              value: _locationEnabled,
              onChanged: (v) {
                setState(() => _locationEnabled = v);
                _save('location', v);
              },
            ),
          ]),

          const SizedBox(height: 16),

          // ── Кэш & хадгалалт ───────────────────────────
          const _GroupTitle('Кэш & Хадгалалт'),
          _SettingsCard(children: [
            _ActionTile(
              icon: Icons.cleaning_services_outlined,
              iconColor: AppColors.primary,
              iconBg: AppColors.primaryLight,
              label: 'Кэш цэвэрлэх',
              sub: 'Апп-н түр хадгалалт',
              onTap: () => _clearCache(context),
            ),
            const Divider(height: 1, indent: 66),
            _ActionTile(
              icon: Icons.history_rounded,
              iconColor: AppColors.textSecondary,
              iconBg: AppColors.border,
              label: 'Хайлтын түүх арилгах',
              sub: 'Хайлтын бүртгэл',
              onTap: () => _clearHistory(context),
              isLast: true,
            ),
          ]),

          const SizedBox(height: 16),

          // ── Тухай ─────────────────────────────────────
          const _GroupTitle('Тухай'),
          _SettingsCard(children: [
            _ActionTile(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.teal,
              iconBg: AppColors.tealLight,
              label: 'Апп-н тухай',
              sub: 'Оюунтан v1.0.0',
              onTap: () => _showAbout(context),
            ),
            const Divider(height: 1, indent: 66),
            _ActionTile(
              icon: Icons.privacy_tip_outlined,
              iconColor: AppColors.purple,
              iconBg: AppColors.purpleLight,
              label: 'Нууцлалын бодлого',
              sub: 'Хэрхэн хамгаалагддаг',
              onTap: () => _showPrivacy(context),
            ),
            const Divider(height: 1, indent: 66),
            _ActionTile(
              icon: Icons.support_agent_outlined,
              iconColor: AppColors.amber,
              iconBg: AppColors.amberLight,
              label: 'Тусламж & Дэмжлэг',
              sub: 'support@oyuntan.mn',
              onTap: () {},
              isLast: true,
            ),
          ]),

          const SizedBox(height: 16),

          // ── Гарах ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: _ActionTile(
              icon: Icons.logout_rounded,
              iconColor: AppColors.red,
              iconBg: AppColors.redLight,
              label: 'Гарах',
              sub: 'Аккаунтаас гарах',
              onTap: () => _confirmLogout(context, auth),
              isLast: true,
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text('Оюунтан Платформ © 2025',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textTertiary)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Кэш цэвэрлэх',
            style: TextStyle(fontSize: 16)),
        content: const Text('Апп-н кэшийг цэвэрлэхийг зөвшөөрнө үү?',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Болих')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Кэш амжилттай цэвэрлэгдлээ'),
                  backgroundColor: AppColors.teal,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: const Text('Цэвэрлэх')),
        ],
      ),
    );
  }

  void _clearHistory(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Хайлтын түүх арилгагдлаа'),
      backgroundColor: AppColors.teal,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.work_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Оюунтан', style: TextStyle(fontSize: 16)),
            Text('v1.0.0',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ]),
        content: const Text(
          'Оюунтан нь оюутан болон компанийг холбодог карьерын '
          'платформ юм. Дадлага хайх, CV бүтээх, ажлын туршлага '
          'хуримтлуулах боломжийг нэг газарт олгодог.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ойлголоо')),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Нууцлалын бодлого',
            style: TextStyle(fontSize: 16)),
        content: const SingleChildScrollView(
          child: Text(
            '• Таны мэдээллийг гуравдагч этгээдэд дамжуулахгүй\n'
            '• Нэвтрэлтийн мэдээллийг шифрлэж хадгалдаг\n'
            '• Firebase аюулгүй байдлын дүрэм ашигладаг\n'
            '• Та хүссэн үедээ аккаунтаа устгуулж болно\n'
            '• Байршлын мэдээлэл зөвхөн тохиргоотой үед авагдана',
            style: TextStyle(fontSize: 12, height: 1.7),
          ),
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Хаах')),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Гарах', style: TextStyle(fontSize: 16)),
        content: const Text('Та гарахдаа итгэлтэй байна уу?',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Болих')),
          ElevatedButton(
              onPressed: () { Navigator.pop(context); auth.logout(); },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red),
              child: const Text('Гарах')),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────
class _GroupTitle extends StatelessWidget {
  final String text;
  const _GroupTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: AppColors.textTertiary, letterSpacing: 0.8)),
  );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 0.8),
    ),
    child: Column(children: children),
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.label, required this.sub,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        Text(sub,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ])),
      Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primaryMid,
      ),
    ]),
  );
}

class _SelectTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _SelectTile({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.label, required this.value,
    required this.options, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary))),
      DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        style: const TextStyle(
            fontSize: 12, color: AppColors.primary,
            fontWeight: FontWeight.w600),
        items: options.map((o) => DropdownMenuItem(
          value: o,
          child: Text(o),
        )).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, sub;
  final VoidCallback onTap;
  final bool isLast;
  const _ActionTile({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.label, required this.sub, required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          Text(sub,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ])),
        const Icon(Icons.chevron_right_rounded,
            size: 20, color: AppColors.textTertiary),
      ]),
    ),
  );
}
