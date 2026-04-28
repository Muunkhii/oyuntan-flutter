// lib/screens/notifications/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _load();
    NotificationService().markAllRead();
  }

  void _load() {
    final uid = context.read<AuthProvider>().uid;
    setState(() { _future = NotificationService().getNotifications(uid); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        automaticallyImplyLeading: false,
        title: const Text('Мэдэгдэл'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2));
          }
          final notifs = snap.data ?? [];
          if (notifs.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (_, i) => _NotifTile(
                data: notifs[i],
                onTap: () async {
                  await NotificationService().markRead(notifs[i]['id'] as String);
                  _load();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _NotifTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? '';
    final read = data['read'] as bool? ?? false;
    final createdAt = data['created_at'] as String?;
    final date = createdAt != null ? DateTime.tryParse(createdAt) : null;

    final (icon, bg, fg, title, sub) = _resolve(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: read ? Colors.transparent : AppColors.blueLight.withValues(alpha: 0.35),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (date != null) ...[
              const SizedBox(height: 4),
              Text(DateFormat('MM/dd HH:mm').format(date),
                  style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
            ],
          ])),
          if (!read) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle)),
        ]),
      ),
    );
  }

  (IconData, Color, Color, String, String) _resolve(String type) => switch (type) {
    'new_application'    => (Icons.person_add_outlined, AppColors.tealLight, AppColors.teal, 'Шинэ өргөдөл ирлээ', 'Оюутан таны зарт өргөдөл илгээлээ'),
    'application_accepted' => (Icons.check_circle_outline, AppColors.tealLight, AppColors.teal, 'Өргөдөл хүлээн авагдлаа', 'Компани таны өргөдлийг зөвшөөрлөө. Дадлага эхэллээ!'),
    'application_rejected' => (Icons.cancel_outlined, AppColors.redLight, AppColors.red, 'Өргөдөл татгалзагдлаа', 'Энэ удаа болсонгүй. Өөр дадлага хайж үзээрэй.'),
    _ => (Icons.notifications_outlined, AppColors.purpleLight, AppColors.purple, 'Мэдэгдэл', ''),
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 64, height: 64,
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(32)),
        child: const Icon(Icons.notifications_none_outlined, size: 32, color: AppColors.textTertiary)),
      const SizedBox(height: 16),
      const Text('Мэдэгдэл байхгүй байна', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      const Text('Шинэ үйлдэл гарахад энд харагдана',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]),
  );
}
