import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _heroController.forward();

    // Simulate loading animation for statistics
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stateProvider = Provider.of<AppStateProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final totalEvents = stateProvider.events.length;
    final totalRegistrations = stateProvider.registrations.length;
    final activeStaff = stateProvider.staffAssignments.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF020617),
                    const Color(0xFF1E1B4B),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFEFF6FF),
                    const Color(0xFFEEF2FF),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background glowing aura
            Positioned(
              top: -60,
              right: -60,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                            blurRadius: 120,
                            spreadRadius: 50,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Top Header / Navigation Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // App Branding
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 32,
                                  height: 32,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'N EVENTS',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),

                          // Header Actions
                          Row(
                            children: [
                              if (authProvider.isLoggedIn)
                                ElevatedButton.icon(
                                  onPressed: () => context.go(authProvider.homeRoute),
                                  icon: const Icon(Icons.dashboard_rounded, size: 18),
                                  label: const Text('Dashboard'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                  ),
                                )
                              else ...[
                                TextButton(
                                  onPressed: () => context.go('/auth?tab=signin'),
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => context.go('/auth?tab=signup'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                  ),
                                  child: const Text('Get Started'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hero Section
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 32),
                            child: Column(
                              children: [
                                // Badge tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(0xFF818CF8)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        size: 16,
                                        color: Color(0xFF818CF8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Next-Gen Campus Event Portal',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? const Color(0xFFA5B4FC)
                                              : const Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Main Hero Title
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      LinearGradient(
                                    colors: isDark
                                        ? [
                                            Colors.white,
                                            const Color(0xFFA5B4FC),
                                            const Color(0xFFC084FC),
                                          ]
                                        : [
                                            const Color(0xFF0F172A),
                                            const Color(0xFF4F46E5),
                                            const Color(0xFF7C3AED),
                                          ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Discover, Register &\nExperience Campus Events',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width > 600 ? 44 : 32,
                                      fontWeight: FontWeight.w900,
                                      height: 1.15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Text(
                                  'Real-time ticketing, QR pass scanning, AI campus assistant, and direct coordinator chat — all in one place.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                    height: 1.5,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Hero CTA Buttons
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => context.go('/student'),
                                      icon: const Icon(Icons.explore_rounded),
                                      label: const Text('Explore Campus Events'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4F46E5),
                                        foregroundColor: Colors.white,
                                        elevation: 8,
                                        shadowColor: const Color(0xFF4F46E5)
                                            .withValues(alpha: 0.5),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 28, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => context.go('/auth'),
                                      icon: const Icon(Icons.person_add_rounded),
                                      label: const Text('Join as Student / Staff'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                        side: BorderSide(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.2)
                                              : const Color(0xFFCBD5E1),
                                          width: 1.5,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Statistics Counter Banner with Shimmer Loading State
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              context,
                              label: 'Active Events',
                              value: '$totalEvents+',
                              icon: Icons.event_available_rounded,
                              color: const Color(0xFF38BDF8),
                              isLoading: _isLoadingStats,
                            ),
                            _buildStatItem(
                              context,
                              label: 'Registrations',
                              value: '$totalRegistrations+',
                              icon: Icons.confirmation_number_rounded,
                              color: const Color(0xFF818CF8),
                              isLoading: _isLoadingStats,
                            ),
                            _buildStatItem(
                              context,
                              label: 'Staff & Co-Coordinators',
                              value: '$activeStaff+',
                              icon: Icons.groups_rounded,
                              color: const Color(0xFFC084FC),
                              isLoading: _isLoadingStats,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Interactive Feature Cards Grid
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Platform Capabilities',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Everything you need for seamless campus event management',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 20),

                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount:
                                MediaQuery.of(context).size.width > 768 ? 4 : 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.1,
                            children: [
                              _buildFeatureCard(
                                context,
                                title: 'Instant Pass Ticketing',
                                subtitle: 'Automated QR code pass generation & download',
                                icon: Icons.qr_code_2_rounded,
                                color: const Color(0xFF2563EB),
                                isDark: isDark,
                              ),
                              _buildFeatureCard(
                                context,
                                title: 'AI Campus Assistant',
                                subtitle: 'Powered by Gemini AI for event QA',
                                icon: Icons.psychology_rounded,
                                color: const Color(0xFFD97706),
                                isDark: isDark,
                              ),
                              _buildFeatureCard(
                                context,
                                title: 'Staff Ticket Scanner',
                                subtitle: 'Real-time entry verification for scanners',
                                icon: Icons.qr_code_scanner_rounded,
                                color: const Color(0xFF059669),
                                isDark: isDark,
                              ),
                              _buildFeatureCard(
                                context,
                                title: 'Campus Notifications',
                                subtitle: 'Live broadcast alerts & event updates',
                                icon: Icons.notifications_active_rounded,
                                color: const Color(0xFF7C3AED),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Divider(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0xFFE2E8F0),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '© 2026 N Events • Annamacharya Institute of Technology and Sciences',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isLoading,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        if (isLoading)
          Container(
            width: 48,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
