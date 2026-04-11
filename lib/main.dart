// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_student_screen.dart';
import 'screens/auth/register_company_screen.dart';
import 'screens/auth/psych_test_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/company_home_screen.dart';
import 'screens/internship/internship_screen.dart';
import 'screens/internship/swipe_screen.dart';
import 'screens/internship/company_interns_screen.dart';
import 'screens/diary/diary_screen.dart';
import 'screens/review/review_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const OyuntanApp());
}

class OyuntanApp extends StatelessWidget {
  const OyuntanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) => MaterialApp.router(
          title: 'Оюунтан',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _buildRouter(auth),
        ),
      ),
    );
  }

  GoRouter _buildRouter(AuthProvider auth) => GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final onAuth   = state.matchedLocation.startsWith('/login') ||
                       state.matchedLocation.startsWith('/register') ||
                       state.matchedLocation.startsWith('/psych');
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth)  return auth.isCompany ? '/company' : '/home';
      return null;
    },
    refreshListenable: auth,
    routes: [
      // ── Auth ──────────────────────────────────────────────
      GoRoute(path: '/login',            builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register/student', builder: (_, __) => const RegisterStudentScreen()),
      GoRoute(path: '/register/company', builder: (_, __) => const RegisterCompanyScreen()),
      GoRoute(path: '/psych-test',
          builder: (_, s) => PsychTestScreen(studentData: s.extra as Map<String, dynamic>)),

      // ── Оюутан Shell (bottom nav: 4 items) ───────────────
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child, isCompany: false),
        routes: [
          GoRoute(path: '/home',          builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationScreen()),
          GoRoute(path: '/internships',   builder: (_, __) => const InternshipScreen()),
          GoRoute(path: '/profile',       builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Компани Shell (bottom nav: 4 items) ──────────────
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child, isCompany: true),
        routes: [
          GoRoute(path: '/company',                 builder: (_, __) => const CompanyHomeScreen()),
          GoRoute(path: '/company/notifications',   builder: (_, __) => const NotificationScreen()),
          GoRoute(path: '/company/interns',         builder: (_, __) => const CompanyInternsScreen()),
          GoRoute(path: '/company/profile',         builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Standalone ────────────────────────────────────────
      GoRoute(path: '/company/swipe/:postId',
          builder: (_, s) => SwipeScreen(postId: s.pathParameters['postId']!)),
      GoRoute(path: '/diary/:internshipId',
          builder: (_, s) => DiaryScreen(internshipId: s.pathParameters['internshipId']!)),
      GoRoute(path: '/review/:internshipId',
          builder: (_, s) => ReviewScreen(internshipId: s.pathParameters['internshipId']!)),
    ],
  );
}
