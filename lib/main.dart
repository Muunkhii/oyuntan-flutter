// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/auth/start_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screens.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/company_home_screen.dart';
import 'screens/internship/internship_screen.dart';
import 'screens/internship/company_interns_screen.dart';
import 'screens/diary/diary_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/cv/cv_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OyuntanApp());
}

class OyuntanApp extends StatefulWidget {
  const OyuntanApp({super.key});
  @override State<OyuntanApp> createState() => _OyuntanAppState();
}

class _OyuntanAppState extends State<OyuntanApp> {
  late final AuthProvider   _auth;
  late final LocaleProvider _locale;
  late final GoRouter       _router;

  @override
  void initState() {
    super.initState();
    _auth   = AuthProvider();
    _locale = LocaleProvider();
    _router = _buildRouter();
  }

  GoRouter _buildRouter() => GoRouter(
    initialLocation: '/start',
    refreshListenable: _auth,
    redirect: (ctx, state) {
      final loggedIn = _auth.isLoggedIn;
      final loc      = state.matchedLocation;
      final onAuth   = loc == '/start'             ||
                       loc.startsWith('/login')    ||
                       loc.startsWith('/register') ||
                       loc == '/psych-test'        ||
                       loc == '/welcome';
      if (!loggedIn && !onAuth) return '/start';
      if (loggedIn && (loc == '/start' || loc.startsWith('/login'))) {
        return _auth.isCompany ? '/company/home' : '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/start',            builder: (_, __) => const StartScreen()),
      GoRoute(path: '/login/student',    builder: (_, __) => const LoginScreen(isCompany: false)),
      GoRoute(path: '/login/company',    builder: (_, __) => const LoginScreen(isCompany: true)),
      GoRoute(path: '/register/student', builder: (_, __) => const RegisterStudentScreen()),
      GoRoute(path: '/register/company', builder: (_, __) => const RegisterCompanyScreen()),
      GoRoute(path: '/psych-test',       builder: (_, __) => const PsychTestScreen()),
      GoRoute(
        path: '/welcome',
        builder: (_, state) {
          final type = state.uri.queryParameters['type'] ?? 'student';
          return WelcomeScreen(isCompany: type == 'company');
        },
      ),

      // ── Student shell ──────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => StudentShell(child: child),
        routes: [
          GoRoute(path: '/home',          builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationScreen()),
          GoRoute(path: '/internships',   builder: (_, __) => const InternshipScreen()),
          GoRoute(path: '/cv',            builder: (_, __) => const CVScreen()),
          GoRoute(path: '/schedule',      builder: (_, __) => const ScheduleScreen()),
          GoRoute(path: '/profile',       builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Company shell ──────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => CompanyShell(child: child),
        routes: [
          GoRoute(path: '/company/home',    builder: (_, __) => const CompanyHomeScreen()),
          GoRoute(path: '/company/notif',   builder: (_, __) => const NotificationScreen()),
          GoRoute(path: '/company/interns', builder: (_, __) => const CompanyInternsScreen()),
          GoRoute(path: '/company/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      GoRoute(path: '/diary/:id',           builder: (_, s) => DiaryScreen(internshipId: s.pathParameters['id']!)),
      GoRoute(path: '/review/:id',          builder: (_, s) => ReviewScreen(internshipId: s.pathParameters['id']!)),
      GoRoute(path: '/company/swipe/:id',   builder: (_, s) => SwipeScreen(postId: s.pathParameters['id']!)),
      GoRoute(path: '/company/post/create', builder: (_, __) => const CreatePostScreen()),
    ],
  );

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _auth),
      ChangeNotifierProvider.value(value: _locale),
    ],
    child: MaterialApp.router(
      title: 'Оюунтан',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    ),
  );

  @override void dispose() { _auth.dispose(); _locale.dispose(); super.dispose(); }
}

// ── Student Shell ──────────────────────────────────────────────
class StudentShell extends StatelessWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final mn  = context.watch<LocaleProvider>().isMN;
    final tabs = [
      (p: '/home',        i: Icons.home_outlined,           a: Icons.home_rounded,           l: mn ? 'Нүүр'    : 'Home'),
      (p: '/internships', i: Icons.work_outline,            a: Icons.work_rounded,           l: mn ? 'Дадлага' : 'Intern'),
      (p: '/schedule',    i: Icons.calendar_today_outlined, a: Icons.calendar_today_rounded, l: mn ? 'Хуваарь' : 'Schedule'),
      (p: '/profile',     i: Icons.person_outline,          a: Icons.person_rounded,         l: mn ? 'Профайл' : 'Profile'),
    ];
    final idx = tabs.indexWhere((t) => loc.startsWith(t.p)).clamp(0, tabs.length - 1);
    return Scaffold(
      body: child,
      bottomNavigationBar: _BubbleNavBar(tabs: tabs, current: idx, onTap: (i) => context.go(tabs[i].p)),
    );
  }
}

// ── Company Shell ──────────────────────────────────────────────
class CompanyShell extends StatelessWidget {
  final Widget child;
  const CompanyShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final mn  = context.watch<LocaleProvider>().isMN;
    final tabs = [
      (p: '/company/home',    i: Icons.home_outlined,  a: Icons.home_rounded,    l: mn ? 'Нүүр'    : 'Home'),
      (p: '/company/interns', i: Icons.work_outline,   a: Icons.work_rounded,    l: mn ? 'Дадлага' : 'Interns'),
      (p: '/company/profile', i: Icons.person_outline, a: Icons.person_rounded,  l: mn ? 'Профайл' : 'Profile'),
    ];
    final idx = tabs.indexWhere((t) => loc.startsWith(t.p)).clamp(0, tabs.length - 1);
    return Scaffold(
      body: child,
      bottomNavigationBar: _BubbleNavBar(tabs: tabs, current: idx, onTap: (i) => context.go(tabs[i].p)),
    );
  }
}

// ── Bubble Nav Bar ─────────────────────────────────────────────
// Active tab expands into a colored pill with label.
// Inactive tabs show only the icon.
class _BubbleNavBar extends StatelessWidget {
  final List<({String p, IconData i, IconData a, String l})> tabs;
  final int current;
  final void Function(int) onTap;

  const _BubbleNavBar({required this.tabs, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, -3)),
      ],
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: tabs.asMap().entries.map((e) {
            final on = current == e.key;
            return Expanded(
              flex: on ? 2 : 1,
              child: GestureDetector(
                onTap: () => onTap(e.key),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: on ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        on ? e.value.a : e.value.i,
                        size: 20,
                        color: on ? Colors.white : AppColors.faint,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: on
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              const SizedBox(width: 7),
                              Text(e.value.l,
                                style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                                )),
                            ])
                          : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
}
