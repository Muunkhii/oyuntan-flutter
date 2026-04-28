// lib/screens/main_shell.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  final bool isCompany;
  const MainShell({super.key, required this.child, required this.isCompany});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _unread = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadUnread();
    // Хагас минут тутамд шинэчлэх
    _timer = Timer.periodic(const Duration(seconds: 90), (_) => _loadUnread());
  }

  Future<void> _loadUnread() async {
    try {
      final count = await NotificationService().getUnreadCount();
      if (mounted) setState(() => _unread = count);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    const studentItems = [
      _NavItem('/home',          Icons.home_outlined,          Icons.home,          'Нүүр'),
      _NavItem('/notifications', Icons.notifications_outlined, Icons.notifications, 'Мэдэгдэл'),
      _NavItem('/internships',   Icons.work_outline,           Icons.work,          'Дадлага'),
      _NavItem('/profile',       Icons.person_outline,         Icons.person,        'Профайл'),
    ];
    const companyItems = [
      _NavItem('/company/home',    Icons.home_outlined,          Icons.home,          'Нүүр'),
      _NavItem('/company/notif',   Icons.notifications_outlined, Icons.notifications, 'Мэдэгдэл'),
      _NavItem('/company/interns', Icons.work_outline,           Icons.work,          'Дадлага'),
      _NavItem('/company/profile', Icons.person_outline,         Icons.person,        'Профайл'),
    ];

    final items = widget.isCompany ? companyItems : studentItems;
    final idx   = items.indexWhere((i) => location.startsWith(i.path)).clamp(0, items.length - 1);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) => context.go(items[i].path),
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          items: items.asMap().entries.map((entry) {
            final i    = entry.key;
            final item = entry.value;
            final showBadge = i == 1 && _unread > 0;
            return BottomNavigationBarItem(
              icon:       _NavIcon(icon: item.icon,       badgeCount: showBadge ? _unread : 0),
              activeIcon: _NavIcon(icon: item.activeIcon, badgeCount: showBadge ? _unread : 0),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  const _NavIcon({required this.icon, required this.badgeCount});

  @override
  Widget build(BuildContext context) => Badge(
    isLabelVisible: badgeCount > 0,
    label: Text('$badgeCount', style: const TextStyle(fontSize: 9)),
    child: Icon(icon, size: 22),
  );
}

class _NavItem {
  final String path, label;
  final IconData icon, activeIcon;
  const _NavItem(this.path, this.icon, this.activeIcon, this.label);
}
