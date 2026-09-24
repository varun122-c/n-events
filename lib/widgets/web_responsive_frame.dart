import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

/// Wraps the Flutter App in a responsive centered container when running on Web / Desktop.
/// Prevents awkward stretched screens, cut-off bottom sheets, or ultra-wide layout distortions.
class WebResponsiveFrame extends StatelessWidget {
  final Widget child;

  const WebResponsiveFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mobile width threshold — on mobile width screens, render directly
    if (screenWidth <= 640) {
      return child;
    }

    final stateProvider = Provider.of<AppStateProvider>(context);

    // Desktop / Web View Mode: Centered Responsive App Container
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background ambient gradient circles
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
              ),
            ),
          ),

          // Main Responsive Content Area
          Column(
            children: [
              // Web Header Bar
              SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      // Brand Logo & Title
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'nEvents',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Campus Event Management Portal',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Web View Controls
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phonelink_rounded, color: Color(0xFF60A5FA), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Responsive View',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Theme Toggle
                      IconButton(
                        onPressed: () {
                          stateProvider.setThemeMode(
                            stateProvider.isDarkMode ? ThemeMode.light : ThemeMode.dark,
                          );
                        },
                        icon: Icon(
                          stateProvider.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                          color: Colors.amber,
                        ),
                        tooltip: 'Toggle Theme',
                      ),
                    ],
                  ),
                ),
              ),

              // Centered Application Frame
              Expanded(
                child: Center(
                  child: Container(
                    width: 500,
                    margin: const EdgeInsets.only(top: 8, bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 2,
                          offset: const Offset(0, 12),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
