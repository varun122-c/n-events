import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/registration_model.dart';
import '../../models/event_model.dart';
import 'package:go_router/go_router.dart';

class StudentHistoryScreen extends StatelessWidget {
  const StudentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<AppStateProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final studentRoll = authProvider.studentRoll;
    final pCode = authProvider.participantCode;
    final hasProfile = studentRoll.isNotEmpty || pCode.isNotEmpty;

    // Filter registrations for active user matching roll number or participant code
    final registrations = hasProfile
        ? stateProvider.registrations
            .where((r) => r.rollNumber.toLowerCase() == studentRoll.toLowerCase() || r.rollNumber.toLowerCase() == pCode.toLowerCase())
            .toList()
        : <Registration>[];

    final now = DateTime.now();

    // Upcoming active registrations (registered status and future date)
    final upcomingRegs = registrations.where((r) {
      final event = stateProvider.events.firstWhere((e) => e.id == r.eventId, 
        orElse: () => Event(
          id: '', title: 'Unknown Event', description: '', bannerUrl: '', 
          dateTime: now, venue: '', category: '', coordinatorName: '', coordinatorPhone: ''
        )
      );
      return event.dateTime.isAfter(now) && r.status != 'Cancelled';
    }).toList();

    // Past or Cancelled or Attended registrations
    final pastRegs = registrations.where((r) {
      final event = stateProvider.events.firstWhere((e) => e.id == r.eventId,
        orElse: () => Event(
          id: '', title: 'Unknown Event', description: '', bannerUrl: '', 
          dateTime: now, venue: '', category: '', coordinatorName: '', coordinatorPhone: ''
        )
      );
      return event.dateTime.isBefore(now) || r.status == 'Cancelled' || r.status == 'Attended';
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF000000) : Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF000000) : Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            tooltip: 'Back',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                Provider.of<AppStateProvider>(context, listen: false).setStudentTabIndex(0);
              }
            },
          ),
          title: Text(
            'My Event Registrations',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          bottom: TabBar(
            labelColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3C72),
            unselectedLabelColor: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
            indicatorColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E3C72),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Upcoming (${upcomingRegs.length})'),
              Tab(text: 'Past / Cancelled (${pastRegs.length})'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Dark Mode History Header Banner
            _buildHistoryHeaderBanner(context, isDark, registrations.length, upcomingRegs.length, pastRegs.length),

            Expanded(
              child: TabBarView(
                children: [
                  _buildHistoryList(context, upcomingRegs, stateProvider, isDark, isUpcoming: true),
                  _buildHistoryList(context, pastRegs, stateProvider, isDark, isUpcoming: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryHeaderBanner(
    BuildContext context, 
    bool isDark, 
    int totalCount, 
    int upcomingCount, 
    int pastCount
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.2) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: isDark ? Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)) : null,
                ),
                child: Icon(
                  Icons.confirmation_number_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EVENT PASS HUB 🎟️',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track active passes, attendance & re-registration',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatPill(isDark, 'TOTAL PASSES', totalCount.toString(), isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              _buildStatPill(isDark, 'UPCOMING', upcomingCount.toString(), const Color(0xFF22C55E)),
              const SizedBox(width: 8),
              _buildStatPill(isDark, 'PAST / CANCELLED', pastCount.toString(), isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(bool isDark, String label, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF94A3B8),
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<Registration> regs,
    AppStateProvider stateProvider,
    bool isDark, {
    required bool isUpcoming,
  }) {
    if (regs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.calendar_today_outlined : Icons.history_toggle_off_rounded,
              size: 56,
              color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming registrations' : 'No past registrations found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isUpcoming
                  ? 'Explore campus events and register to see them here.'
                  : 'Cancelled or completed events will show up here.',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: regs.length,
      itemBuilder: (context, index) {
        final reg = regs[index];
        final event = stateProvider.events.firstWhere(
          (e) => e.id == reg.eventId,
          orElse: () => Event(
            id: '',
            title: 'Unknown Event',
            description: '',
            bannerUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&auto=format&fit=crop',
            dateTime: DateTime.now(),
            venue: 'N/A',
            category: 'N/A',
            coordinatorName: '',
            coordinatorPhone: '',
          ),
        );

        final formattedDate = DateFormat('EEEE, MMMM d • h:mm a').format(event.dateTime);

        return GestureDetector(
          onTap: () {
            if (event.id.isNotEmpty) {
              context.push('/student/event/${event.id}');
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      _buildStatusBadge(context, reg.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.venue,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: 24,
                    thickness: 1,
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registered Student:',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? const Color(0xFFA1A1AA) : Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              reg.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Re-Register option for Cancelled Events
                          if (reg.status == 'Cancelled') ...[
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ElevatedButton.icon(
                                onPressed: () => _confirmReRegistration(context, stateProvider, reg, isDark),
                                icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                                label: const Text('Re-Register', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                          // Active Registration Options
                          if (isUpcoming && reg.status == 'Registered') ...[
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: TextButton.icon(
                                onPressed: () {
                                  context.push('/student/chat/${event.id}/${reg.rollNumber}');
                                },
                                icon: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 14,
                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                ),
                                label: Text(
                                  'Chat Coordinator',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                              tooltip: 'Cancel Registration',
                              onPressed: () => _confirmCancellation(context, stateProvider, reg, isDark),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Registered':
        bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
        textColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
        break;
      case 'Attended':
        bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
        textColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
        break;
      case 'Cancelled':
        bgColor = isDark ? const Color(0xFF451A03) : const Color(0xFFFEF2F2);
        textColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        break;
      default:
        bgColor = isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9);
        textColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  void _confirmCancellation(BuildContext context, AppStateProvider stateProvider, Registration reg, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: isDark ? const BorderSide(color: Color(0xFF27272A)) : BorderSide.none,
        ),
        title: Text(
          'Cancel Registration',
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel your registration for this event?',
          style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No, Keep It',
              style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              stateProvider.updateRegistrationStatus(reg.id, 'Cancelled');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Registration cancelled. You can re-register anytime from history.'),
                  backgroundColor: isDark ? const Color(0xFF27272A) : Colors.grey,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmReRegistration(BuildContext context, AppStateProvider stateProvider, Registration reg, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: isDark ? const BorderSide(color: Color(0xFF27272A)) : BorderSide.none,
        ),
        title: Text(
          'Re-Register for Event',
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Would you like to restore your registration status for this event?',
          style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              stateProvider.updateRegistrationStatus(reg.id, 'Registered');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Re-registered successfully! Your event pass is active again.'),
                  backgroundColor: Color(0xFF10B981),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text('Yes, Re-Register'),
          ),
        ],
      ),
    );
  }
}
