import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/oauth_callback_screen.dart';
import '../screens/student/student_main_navigation.dart';
import '../screens/student/event_details_screen.dart';
import '../screens/student/student_coordinator_chat_screen.dart';
import '../screens/student/student_tickets_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_event_form_screen.dart';
import '../screens/admin/admin_participants_screen.dart';
import '../screens/admin/admin_banner_customizer_screen.dart';
import '../screens/admin/admin_chats_screen.dart';
import '../screens/admin/admin_staff_management_screen.dart';
import '../screens/admin/admin_user_directory_screen.dart';
import '../screens/staff/organizer_dashboard_screen.dart';
import '../screens/staff/coordinator_dashboard_screen.dart';
import '../screens/staff/tech_provider_screen.dart';
import '../screens/staff/qr_scanner_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'] ?? 'signin';
          final role = state.uri.queryParameters['role'] ?? 'student';
          return AuthScreen(initialTab: tab, initialRole: role);
        },
      ),
      GoRoute(
        path: '/login-callback',
        builder: (context, state) => const OAuthCallbackScreen(),
      ),

      // ─── Student Routes ───────────────────────────────────────────────────
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentMainNavigation(),
      ),
      GoRoute(
        path: '/my-tickets',
        builder: (context, state) => const StudentTicketsScreen(),
      ),
      GoRoute(
        path: '/student/event/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return EventDetailsScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/student/chat/:eventId/:studentRoll',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final studentRoll = state.pathParameters['studentRoll']!;
          return StudentCoordinatorChatScreen(eventId: eventId, studentRoll: studentRoll);
        },
      ),

      // ─── Admin Routes ─────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/event-form',
        builder: (context, state) {
          final eventId = state.uri.queryParameters['id'];
          return AdminEventFormScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/admin/participants/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return AdminParticipantsScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/admin/banners',
        builder: (context, state) => const AdminBannerCustomizerScreen(),
      ),
      GoRoute(
        path: '/admin/chats',
        builder: (context, state) => const AdminChatsScreen(),
      ),
      GoRoute(
        path: '/admin/staff',
        builder: (context, state) => const AdminStaffManagementScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUserDirectoryScreen(),
      ),

      // ─── Staff Routes ─────────────────────────────────────────────────────
      GoRoute(
        path: '/staff/organizer',
        builder: (context, state) => const OrganizerDashboardScreen(),
      ),
      GoRoute(
        path: '/staff/coordinator',
        builder: (context, state) => const CoordinatorDashboardScreen(),
      ),
      GoRoute(
        path: '/staff/coordinator/chats',
        builder: (context, state) => const AdminChatsScreen(),
      ),
      GoRoute(
        path: '/staff/tech',
        builder: (context, state) => const TechProviderScreen(),
      ),
      GoRoute(
        path: '/staff/scanner',
        builder: (context, state) => const QrScannerScreen(),
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
