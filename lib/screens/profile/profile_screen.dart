// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/home_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final profile   = auth.profile ?? {};
    final isStudent = auth.isStudent;
    final name      = auth.displayName.isEmpty ? 'Хэрэглэгч' : auth.displayName;
    final email     = profile['email'] as String? ?? '';
    final photoUrl  = profile['photoUrl'] as String?;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(
                name: name,
                email: email,
                photoUrl: photoUrl,
                isStudent: isStudent,
                auth: auth,
                profile: profile,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppColors.white,
                child: TabBar(
                  controller: _tab,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textTertiary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Профайл'),
                    Tab(text: 'Засах'),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: Colors.white, size: 22),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _ViewTab(profile: profile, isStudent: isStudent, auth: auth),
            _EditTab(auth: auth, profile: profile, isStudent: isStudent),
          ],
        ),
      ),
    );
  }
}

// ── Profile Header ────────────────────────────────────────
class _ProfileHeader extends StatefulWidget {
  final String name, email;
  final String? photoUrl;
  final bool isStudent;
  final AuthProvider auth;
  final Map<String, dynamic> profile;
  const _ProfileHeader({
    required this.name, required this.email, required this.photoUrl,
    required this.isStudent, required this.auth, required this.profile,
  });
  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _uploading = false;
  double _uploadProgress = 0;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final xFile  = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800);
    if (xFile == null) return;
    if (!mounted) return;

    setState(() { _uploading = true; _uploadProgress = 0; });

    try {
      final uid = widget.auth.user?.uid ?? '';
      if (uid.isEmpty) throw Exception('Нэвтрээгүй байна');

      // Read bytes (works on all platforms — no dart:io needed)
      final bytes = await xFile.readAsBytes();

      final ref = FirebaseStorage.instance
          .ref('avatars/$uid.jpg');

      // Upload with progress tracking
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((snap) {
        if (!mounted) return;
        final progress = snap.bytesTransferred / snap.totalBytes;
        setState(() => _uploadProgress = progress);
      });

      await uploadTask;
      final url = await ref.getDownloadURL();
      await widget.auth.updateProfile({'photoUrl': url});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Профайл зураг шинэчлэгдлээ ✓'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'unauthorized'       => 'Firebase Storage зөвшөөрөл байхгүй. Rules шалгана уу.',
        'canceled'           => 'Upload цуцлагдлаа',
        'storage/unauthorized' => 'Storage Rules зөвшөөрдөггүй байна',
        _                    => 'Firebase алдаа: ${e.message}',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Алдаа: $e'),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ));
    } finally {
      if (mounted) setState(() { _uploading = false; _uploadProgress = 0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(children: [
            // Avatar with edit button
            Stack(children: [
              GestureDetector(
                onTap: _uploading ? null : _pickAndUpload,
                child: SizedBox(
                  width: 80, height: 80,
                  child: Stack(alignment: Alignment.center, children: [
                    // Progress ring
                    if (_uploading)
                      SizedBox(
                        width: 80, height: 80,
                        child: CircularProgressIndicator(
                          value: _uploadProgress > 0 ? _uploadProgress : null,
                          color: Colors.white,
                          strokeWidth: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    // Avatar circle
                    Container(
                      width: _uploading ? 64 : 76,
                      height: _uploading ? 64 : 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white,
                            width: _uploading ? 0 : 2.5),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: ClipOval(
                        child: _uploading
                            ? Center(
                                child: Text(
                                  '${(_uploadProgress * 100).toInt()}%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700),
                                ),
                              )
                            : widget.photoUrl != null
                                ? Image.network(
                                    widget.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _AvatarInitials(name: widget.name),
                                  )
                                : _AvatarInitials(name: widget.name),
                      ),
                    ),
                  ]),
                ),
              ),
              // Edit pencil icon
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _uploading ? null : _pickAndUpload,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: const Icon(Icons.edit,
                        size: 13, color: AppColors.primary),
                  ),
                ),
              ),
            ]),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(widget.email,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.isStudent ? 'Оюутан' : 'Компани',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ),
              ],
            )),
          ]),
        ),
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  final String name;
  const _AvatarInitials({required this.name});
  @override
  Widget build(BuildContext context) {
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
    return Center(
      child: Text(initials.isEmpty ? '?' : initials,
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }
}

// ── View Tab ──────────────────────────────────────────────
class _ViewTab extends StatelessWidget {
  final Map<String, dynamic> profile;
  final bool isStudent;
  final AuthProvider auth;
  const _ViewTab(
      {required this.profile, required this.isStudent, required this.auth});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Weather & calendar
        const WeatherDateHeader(),
        const SizedBox(height: 4),
        _CalendarStrip(),
        const SizedBox(height: 16),

        // Info card
        _InfoCard(children: [
          if (isStudent) ...[
            _InfoRow(Icons.school_outlined, 'Их сургууль',
                profile['university'] as String? ?? '—'),
            _InfoRow(Icons.book_outlined, 'Мэргэжил',
                profile['major'] as String? ?? '—'),
            _InfoRow(Icons.grade_outlined, 'Курс',
                '${profile['year'] ?? '—'}-р курс'),
            _InfoRow(Icons.email_outlined, 'Имэйл',
                profile['email'] as String? ?? '—'),
            if ((profile['gpa'] as String? ?? '').isNotEmpty)
              _InfoRow(Icons.star_outline_rounded, 'GPA',
                  profile['gpa'] as String),
          ] else ...[
            _InfoRow(Icons.business_outlined, 'Компани',
                profile['name'] as String? ?? '—'),
            _InfoRow(Icons.category_outlined, 'Салбар',
                profile['industry'] as String? ?? '—'),
            _InfoRow(Icons.people_outline, 'Ажилтан',
                profile['size'] as String? ?? '—'),
            _InfoRow(Icons.email_outlined, 'Имэйл',
                profile['email'] as String? ?? '—'),
          ],
        ]),

        if ((profile['bio'] as String? ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionTitle('Товч танилцуулга'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Text(profile['bio'] as String,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6)),
          ),
        ],

        if ((profile['skills'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          const _SectionTitle('Ур чадвар'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: (profile['skills'] as List).cast<String>().map((s) =>
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primaryMid, width: 0.8),
                  ),
                  child: Text(s,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500)),
                )).toList(),
          ),
        ],

        const SizedBox(height: 24),

        // Quick actions
        const _SectionTitle('Хурдан үйлдэл'),
        const SizedBox(height: 10),
        _ActionList(isStudent: isStudent, auth: auth),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 0.8),
    ),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textTertiary,
                fontWeight: FontWeight.w500)),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ])),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}

class _ActionList extends StatelessWidget {
  final bool isStudent;
  final AuthProvider auth;
  const _ActionList({required this.isStudent, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(children: [
        if (isStudent)
          _ActionTile(
            icon: Icons.description_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.primaryLight,
            label: 'CV Maker',
            sub: 'PDF татаж авах боломжтой',
            onTap: () => context.push('/cv'),
          ),
        _ActionTile(
          icon: Icons.notifications_outlined,
          iconColor: AppColors.amber,
          iconBg: AppColors.amberLight,
          label: 'Мэдэгдлийн тохиргоо',
          sub: 'Push, имэйл мэдэгдэл',
          onTap: () => context.push('/settings'),
        ),
        _ActionTile(
          icon: Icons.lock_outline_rounded,
          iconColor: AppColors.purple,
          iconBg: AppColors.purpleLight,
          label: 'Нууц үг солих',
          sub: 'Аккаунт аюулгүй байдал',
          onTap: () => _showChangePassword(context),
        ),
        _ActionTile(
          icon: Icons.settings_outlined,
          iconColor: AppColors.teal,
          iconBg: AppColors.tealLight,
          label: 'Апп тохиргоо',
          sub: 'Дүрслэл, хэл, нууцлал',
          onTap: () => context.push('/settings'),
          isLast: true,
        ),
      ]),
    );
  }

  void _showChangePassword(BuildContext context) {
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    bool obscure = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Нууц үг солих',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 20),
            const Text('Шинэ нууц үг',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
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
            const SizedBox(height: 12),
            const Text('Баталгаажуулах',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
                controller: confCtrl,
                obscureText: obscure,
                decoration: const InputDecoration(hintText: 'Дахин оруулах')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (newCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Нууц үг 6+ тэмдэгттэй байна'),
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
                      content: Text('Алдаа: $e'),
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
  Widget build(BuildContext context) => Column(children: [
    InkWell(
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
    ),
    if (!isLast)
      const Divider(height: 1, indent: 66),
  ]);
}

// ── Calendar strip (reused from home) ────────────────────
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
                      color: isToday
                          ? Colors.white
                          : AppColors.textPrimary)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Edit Tab ──────────────────────────────────────────────
class _EditTab extends StatefulWidget {
  final AuthProvider auth;
  final Map<String, dynamic> profile;
  final bool isStudent;
  const _EditTab(
      {required this.auth, required this.profile, required this.isStudent});
  @override
  State<_EditTab> createState() => _EditTabState();
}

class _EditTabState extends State<_EditTab> {
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
        'phone':      TextEditingController(text: p['phone']      as String? ?? ''),
        'gpa':        TextEditingController(text: p['gpa']        as String? ?? ''),
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
        'phone':       TextEditingController(text: p['phone']       as String? ?? ''),
      };
      _skills = [];
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) { c.dispose(); }
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
      data['year']   = int.tryParse(data['year'] as String? ?? '') ?? 1;
      data['skills'] = List<String>.from(_skills);
    }
    final ok = await widget.auth.updateProfile(data);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Профайл шинэчлэгдлээ ✓' : (widget.auth.error ?? 'Алдаа')),
      backgroundColor: ok ? AppColors.teal : AppColors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _field(String label, String key,
      {TextInputType? type, int maxLines = 1, String? hint}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrls[key],
          keyboardType: type,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint ?? label),
        ),
        const SizedBox(height: 14),
      ]);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryMid, width: 0.8),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded,
                size: 18, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Профайлаа бүрэн бөглөсөн оюутан 3 дахин илүү боломж авдаг',
                style: TextStyle(
                    fontSize: 12, color: AppColors.primary, height: 1.4),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        if (widget.isStudent) ...[
          _field('Нэр', 'firstName', hint: 'Жишээ: Мөнхбаяр'),
          _field('Овог', 'lastName', hint: 'Жишээ: Баяр'),
          _field('Их сургууль', 'university', hint: 'МУИС, ШУТИС...'),
          _field('Мэргэжил', 'major', hint: 'Програм хангамж, Дизайн...'),
          _field('Курс', 'year',
              type: TextInputType.number, hint: '1, 2, 3, 4...'),
          _field('Утас', 'phone',
              type: TextInputType.phone, hint: '+976 xxxxxxxx'),
          _field('GPA', 'gpa', hint: '3.5'),
          _field('Товч танилцуулга', 'bio', maxLines: 4,
              hint: 'Өөрийн талаар товч бичих...'),

          // Skills
          const Text('Ур чадвар',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _skillCtrl,
                decoration: const InputDecoration(
                    hintText: 'React, Flutter, Figma...'),
                onSubmitted: _addSkill,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _addSkill(_skillCtrl.text),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ]),
          if (_skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: _skills.map((s) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primaryMid, width: 0.8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(s,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _skills.remove(s)),
                    child: const Icon(Icons.close_rounded,
                        size: 13, color: AppColors.primary),
                  ),
                ]),
              )).toList(),
            ),
          ],
          const SizedBox(height: 20),
        ] else ...[
          _field('Компанийн нэр', 'name'),
          _field('Салбар', 'industry', hint: 'IT, Санхүү, Маркетинг...'),
          _field('Ажилтны тоо', 'size', hint: '10-50, 50-200...'),
          _field('Утас', 'phone', type: TextInputType.phone),
          _field('Вебсайт', 'website', hint: 'https://...'),
          _field('Компанийн тухай', 'description', maxLines: 4),
        ],

        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : const Text('Хадгалах'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _confirmLogout(context, widget.auth),
          icon: const Icon(Icons.logout_rounded,
              size: 18, color: AppColors.red),
          label: const Text('Гарах',
              style: TextStyle(
                  color: AppColors.red, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.red),
            foregroundColor: AppColors.red,
          ),
        ),
        const SizedBox(height: 30),
        const Center(
          child: Text('Оюунтан v1.0.0',
              style: TextStyle(
                  fontSize: 11, color: AppColors.textTertiary)),
        ),
        const SizedBox(height: 8),
      ],
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
