import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import 'student_home_screen.dart';
import 'student_history_screen.dart';
import 'student_ai_assistant_screen.dart';
import 'student_certificates_screen.dart';
import 'student_profile_screen.dart';

class StudentMainNavigation extends StatefulWidget {
  const StudentMainNavigation({super.key});

  @override
  State<StudentMainNavigation> createState() => _StudentMainNavigationState();
}

class _StudentMainNavigationState extends State<StudentMainNavigation> {
  int _selectedIndex = 0;

  int _lastNotificationCount = 0;
  bool _initializedNotifs = false;
  bool _showHUD = false;
  NotificationModel? _hudNotif;
  Timer? _hudTimer;

  final List<Widget> _screens = [
    StudentHomeScreen(),
    StudentHistoryScreen(),
    StudentAiAssistantScreen(),
    StudentCertificatesScreen(),
    StudentProfileScreen(),
  ];

  void _showHUDNotification(NotificationModel notification) {
    _hudTimer?.cancel();
    setState(() {
      _hudNotif = notification;
      _showHUD = true;
    });

    _hudTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showHUD = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hudTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<AppStateProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final notifsCount = stateProvider.notifications.length;

    // Auto-redirect if admin granted staff/coordinator subRole (unless in Personal Account mode!)
    if (authProvider.subRole.isNotEmpty && !authProvider.isPersonalAccountMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final targetRoute = authProvider.homeRoute;
          final roleLabel = SubRoles.label(authProvider.subRole);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Role Granted: $roleLabel! Redirecting to staff portal...'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
            ),
          );
          context.go(targetRoute);
        }
      });
    }

    // Sync tab index from stateProvider if changed
    if (stateProvider.studentTabIndex != _selectedIndex) {
      _selectedIndex = stateProvider.studentTabIndex;
    }

    // Detect new live alerts
    if (!_initializedNotifs) {
      _lastNotificationCount = notifsCount;
      _initializedNotifs = true;
    } else if (notifsCount > _lastNotificationCount) {
      final newNotif = stateProvider.notifications.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showHUDNotification(newNotif);
      });
      _lastNotificationCount = notifsCount;
    } else {
      _lastNotificationCount = notifsCount;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          stateProvider.setStudentTabIndex(0);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),

          // Real-time Dropdown Notification HUD Banner
          if (_hudNotif != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              top: _showHUD ? MediaQuery.of(context).padding.top + 12 : -100,
              left: 16,
              right: 16,
              child: Material(
                elevation: 10,
                shadowColor: Colors.black38,
                borderRadius: BorderRadius.circular(16),
                color: isDark ? Colors.black : Colors.white,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showHUD = false;
                    });
                    if (_hudNotif!.linkedEventId != null && _hudNotif!.linkedEventId!.isNotEmpty) {
                      context.push('/student/event/${_hudNotif!.linkedEventId}');
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF2563EB), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _hudNotif!.title,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _hudNotif!.message,
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: isDark ? Colors.black : Theme.of(context).appBarTheme.backgroundColor,
        elevation: 8,
        shadowColor: Colors.black26,
        selectedIndex: _selectedIndex,
        indicatorColor: isDark ? Colors.cyan.shade900 : Colors.cyan.shade100,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          stateProvider.setStudentTabIndex(index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, color: isDark ? Colors.white70 : Colors.black87),
            selectedIcon: Icon(Icons.explore, color: isDark ? Colors.cyanAccent : const Color(0xFF1E3C72)),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, color: isDark ? Colors.white70 : Colors.black87),
            selectedIcon: Icon(Icons.history, color: isDark ? Colors.cyanAccent : const Color(0xFF1E3C72)),
            label: 'History',
          ),
          NavigationDestination(
            icon: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Image.asset('assets/images/n_ai_logo.jpg', fit: BoxFit.cover),
              ),
            ),
            selectedIcon: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD97706), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Image.asset('assets/images/n_ai_logo.jpg', fit: BoxFit.cover),
              ),
            ),
            label: 'N.ai',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined, color: isDark ? Colors.white70 : Colors.black87),
            selectedIcon: Icon(Icons.workspace_premium, color: isDark ? Colors.cyanAccent : const Color(0xFF1E3C72)),
            label: 'Certificates',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: isDark ? Colors.white70 : Colors.black87),
            selectedIcon: Icon(Icons.person, color: isDark ? Colors.cyanAccent : const Color(0xFF1E3C72)),
            label: 'Profile',
          ),
        ],
      ),
    ),
  );
}
}
