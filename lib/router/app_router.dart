import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/animated_page_route.dart';
import '../screens/splash_screen.dart';
import '../screens/landing_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/oauth_callback_screen.dart';
import '../screens/student/student_main_navigation.dart';
import '../screens/student/event_details_screen.dart';
import '../screens/student/student_tickets_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_event_form_screen.dart';
import '../screens/admin/admin_participants_screen.dart';
import '../screens/admin/admin_banner_customizer_screen.dart';
import '../screens/admin/admin_staff_management_screen.dart';
import '../screens/admin/admin_user_directory_screen.dart';
import '../screens/staff/organizer_dashboard_screen.dart';
import '../screens/staff/coordinator_dashboard_screen.dart';
import '../screens/staff/tech_provider_screen.dart';
import '../screens/staff/qr_scanner_screen.dart';
import '../screens/offline_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final isSplash = state.uri.path == '/splash';
      final isLanding = state.uri.path == '/landing';
      final isAuth = state.uri.path == '/auth' || state.uri.path == '/role-selection';
      final isCallback = state.uri.path == '/login-callback';
      final isOffline = state.uri.path == '/offline';

      // Don't interrupt splash, landing, OAuth callback, or offline screen
      if (isSplash || isLanding || isCallback || isOffline) return null;

      // If user is not logged in and trying to access protected routes, redirect to /auth
      if (!authProvider.isLoggedIn && !isAuth) {
        return '/auth';
      }

      // If user is logged in and trying to access /auth or /role-selection, redirect to their home route
      if (authProvider.isLoggedIn && isAuth) {
        return authProvider.homeRoute;
      }

      // Role-Based Access Control (RBAC) URL redirects
      if (authProvider.isLoggedIn) {
        final role = authProvider.role;
        final subRole = authProvider.subRole;

        // Non-admin trying to access /admin routes
        if (state.uri.path.startsWith('/admin') && role != 'admin') {
          return authProvider.homeRoute;
        }

        // Staff route protection
        if (state.uri.path.startsWith('/staff/organizer') && subRole != 'organizer' && role != 'admin') {
          return authProvider.homeRoute;
        }
        if (state.uri.path.startsWith('/staff/coordinator') && subRole != 'coordinator' && role != 'admin') {
          return authProvider.homeRoute;
        }
        if (state.uri.path.startsWith('/staff/tech') && subRole != 'tech_provider' && role != 'admin') {
          return authProvider.homeRoute;
        }
        if (state.uri.path.startsWith('/staff/scanner') && subRole != 'scanner' && role != 'admin') {
          return authProvider.homeRoute;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/landing',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const LandingScreen(),
        ),
      ),
      GoRoute(
        path: '/role-selection',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const AuthScreen(),
        ),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) {
          final tab = state.uri.queryParameters['tab'] ?? 'signin';
          final role = state.uri.queryParameters['role'] ?? 'student';
          return buildAnimatedPage(
            context: context,
            state: state,
            child: AuthScreen(initialTab: tab, initialRole: role),
          );
        },
      ),
      GoRoute(
        path: '/login-callback',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const OAuthCallbackScreen(),
        ),
      ),
      GoRoute(
        path: '/offline',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const OfflineScreen(),
        ),
      ),

      // ─── Student Routes ───────────────────────────────────────────────────
      GoRoute(
        path: '/student',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const StudentMainNavigation(),
        ),
      ),
      GoRoute(
        path: '/my-tickets',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const StudentTicketsScreen(),
        ),
      ),
      GoRoute(
        path: '/student/event/:id',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return buildAnimatedPage(
            context: context,
            state: state,
            child: EventDetailsScreen(eventId: eventId),
          );
        },
      ),

      // ─── Admin Routes ─────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/event-form',
        pageBuilder: (context, state) {
          final eventId = state.uri.queryParameters['id'];
          return buildAnimatedPage(
            context: context,
            state: state,
            child: AdminEventFormScreen(eventId: eventId),
          );
        },
      ),
      GoRoute(
        path: '/admin/participants/:id',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return buildAnimatedPage(
            context: context,
            state: state,
            child: AdminParticipantsScreen(eventId: eventId),
          );
        },
      ),
      GoRoute(
        path: '/admin/banners',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const AdminBannerCustomizerScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/staff',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const AdminStaffManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const AdminUserDirectoryScreen(),
        ),
      ),
      // ─── Staff Routes ─────────────────────────────────────────────────────
      GoRoute(
        path: '/staff/organizer',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const OrganizerDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/staff/coordinator',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const CoordinatorDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/staff/tech',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const TechProviderScreen(),
        ),
      ),
      GoRoute(
        path: '/staff/scanner',
        pageBuilder: (context, state) => buildAnimatedPage(
          context: context,
          state: state,
          child: const QrScannerScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) {
      if (state.uri.toString().contains('login-callback')) {
        return const OAuthCallbackScreen();
      }
      return const AuthScreen();
    },
  );
}
