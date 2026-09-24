import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';

class CoordinatorDashboardScreen extends StatefulWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  State<CoordinatorDashboardScreen> createState() => _CoordinatorDashboardScreenState();
}

class _CoordinatorDashboardScreenState extends State<CoordinatorDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Checked In', 'Pending'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportCSV(BuildContext context, String eventTitle, List<Registration> regs) {
    final buffer = StringBuffer();
    buffer.writeln('Registration ID,Student Name,Roll Number,Department/Branch,Year,Phone,10-Digit Code,Status,Verified By,Date');

    for (final r in regs) {
      final ticketCode = r.id.substring(0, r.id.length < 10 ? r.id.length : 10).toUpperCase();
      final user10Digit = UserModel.generate10DigitParticipantCode(r.rollNumber);
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(r.registrationDate);
      final verifier = r.verifiedBy ?? 'N/A';
      buffer.writeln('"${r.id}","${r.fullName}","${r.rollNumber}","${r.department}","${r.yearOfStudy}","${r.phoneNumber}","$ticketCode / $user10Digit","${r.status}","$verifier","$dateStr"');
    }

    final csvData = buffer.toString();
    Clipboard.setData(ClipboardData(text: csvData));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
        ),
        title: Row(
          children: [
            const Icon(Icons.table_chart_rounded, color: Color(0xFF10B981), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Excel Roster Export',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Roster for "$eventTitle" (${regs.length} records) formatted for Excel & CSV:',
              style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(maxHeight: 160),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.black : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  csvData,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvData));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CSV roster copied to clipboard! Ready to paste into Excel.'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy CSV for Excel', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showScanVerifyDialog(BuildContext context, AppStateProvider stateProvider, List<Event> assignedEvents) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DualVerifierModal(
          isDark: isDark,
          stateProvider: stateProvider,
          assignedEvents: assignedEvents,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final stateProvider = Provider.of<AppStateProvider>(context);

    final assignedEvents = stateProvider.getAssignedEvents(authProvider.assignedEventIds);
    final assignedRegs = stateProvider.registrations.where((r) => assignedEvents.any((e) => e.id == r.eventId)).toList();
    final checkedInRegsCount = assignedRegs.where((r) => r.status == 'Checked In' || r.status == 'Attended').length;
    final unreadChatCount = stateProvider.chatMessages.where((m) => m.senderRole == 'student' && !m.isRead).length;

    final coordName = authProvider.currentUser?.name.isNotEmpty == true ? authProvider.currentUser!.name : 'Coordinator';

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coordinator Portal',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Welcome back, $coordName',
                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_rounded, color: Color(0xFF10B981)),
            tooltip: 'Export Roster to Excel / CSV',
            onPressed: () {
              if (assignedRegs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No student registrations available to export.')),
                );
              } else {
                _exportCSV(context, 'All Assigned Events', assignedRegs);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Verify Ticket / Camera Scanner',
            onPressed: () => _showScanVerifyDialog(context, stateProvider, assignedEvents),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) {
              if (v == 'export') {
                _exportCSV(context, 'All Assigned Events', assignedRegs);
              } else if (v == 'personal') {
                authProvider.setPersonalAccountMode(true);
                context.go('/student');
              } else if (v == 'scanner') {
                context.push('/staff/scanner');
              } else if (v == 'logout') {
                authProvider.logout();
                context.go('/auth');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'personal',
                child: Row(
                  children: [
                    Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 18),
                    SizedBox(width: 8),
                    Text('Shift to Personal Account'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'scanner',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Text('Full Camera QR Scanner'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_rounded, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Text('Export Excel / CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stat Metrics Bar
          Container(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricPill(
                    'Assigned',
                    '${assignedEvents.length}',
                    Icons.event_seat_rounded,
                    const Color(0xFF2563EB),
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricPill(
                    'Registered',
                    '${assignedRegs.length}',
                    Icons.groups_rounded,
                    const Color(0xFF0284C7),
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricPill(
                    'Checked In',
                    '$checkedInRegsCount',
                    Icons.check_circle_rounded,
                    const Color(0xFF059669),
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricPill(
                    'Inquiries',
                    '$unreadChatCount',
                    Icons.chat_rounded,
                    unreadChatCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                    isDark,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scan QR & Manual Code Hero Banner
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                      : [const Color(0xFF2563EB), const Color(0xFF1E3C72)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Scan QR & 10-Digit Code Verifier',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Scan Event QR or Profile QR, or enter 10-digit code',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showScanVerifyDialog(context, stateProvider, assignedEvents),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text('Open Verifier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search student name, roll number, or 10-digit code…',
                      hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF2563EB)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', 'All Roster', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Checked In', 'Checked In Only', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'Pending Check-In', isDark),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Events & Registered Students List
          Expanded(
            child: assignedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 64, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        Text(
                          'No events assigned to your coordinator account.\nContact campus admin for access.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: assignedEvents.length,
                    itemBuilder: (context, index) {
                      final event = assignedEvents[index];
                      var eventRegs = assignedRegs.where((r) => r.eventId == event.id).toList();

                      // Apply status filter
                      if (_statusFilter == 'Checked In') {
                        eventRegs = eventRegs.where((r) => r.status == 'Checked In' || r.status == 'Attended').toList();
                      } else if (_statusFilter == 'Pending') {
                        eventRegs = eventRegs.where((r) => r.status != 'Checked In' && r.status != 'Attended').toList();
                      }

                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        final q = _searchQuery.toLowerCase();
                        eventRegs = eventRegs.where((r) {
                          final user10 = UserModel.generate10DigitParticipantCode(r.rollNumber).toLowerCase();
                          final ticketCode = r.id.substring(0, r.id.length < 10 ? r.id.length : 10).toLowerCase();
                          return r.fullName.toLowerCase().contains(q) ||
                              r.rollNumber.toLowerCase().contains(q) ||
                              r.department.toLowerCase().contains(q) ||
                              user10.contains(q) ||
                              ticketCode.contains(q);
                        }).toList();
                      }

                      final eventCheckedInCount = eventRegs.where((r) => r.status == 'Checked In' || r.status == 'Attended').length;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        color: isDark ? const Color(0xFF18181B) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                        ),
                        child: ExpansionTile(
                          shape: const RoundedRectangleBorder(side: BorderSide.none),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            child: const Icon(Icons.event_rounded, color: Color(0xFF2563EB), size: 20),
                          ),
                          title: Text(
                            event.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            '${DateFormat('dd MMM yyyy, hh:mm a').format(event.dateTime)} • $eventCheckedInCount / ${eventRegs.length} Checked In',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                          ),
                          children: [
                            Divider(color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9)),
                            if (eventRegs.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'STUDENT ROSTER (${eventRegs.length})',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : const Color(0xFF475569), letterSpacing: 0.5),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _exportCSV(context, event.title, eventRegs),
                                      icon: const Icon(Icons.file_download_rounded, size: 16, color: Color(0xFF10B981)),
                                      label: const Text('Export Excel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                                    ),
                                  ],
                                ),
                              ),
                            if (eventRegs.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No students matching "$_searchQuery".'
                                      : 'No registered students for this event.',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: eventRegs.length,
                                itemBuilder: (context, rIndex) {
                                  final reg = eventRegs[rIndex];
                                  final ticketCode = reg.id.substring(0, reg.id.length < 10 ? reg.id.length : 10).toUpperCase();
                                  final user10Code = UserModel.generate10DigitParticipantCode(reg.rollNumber);
                                  final isCheckedIn = (reg.status == 'Checked In' || reg.status == 'Attended');

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isCheckedIn
                                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                            : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isCheckedIn
                                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                              : const Color(0xFF2563EB).withValues(alpha: 0.15),
                                          child: Text(
                                            reg.fullName.isNotEmpty ? reg.fullName[0].toUpperCase() : 'S',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isCheckedIn ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      reg.fullName,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w900,
                                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isCheckedIn
                                                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                                          : const Color(0xFF2563EB).withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      isCheckedIn ? 'Checked In ✅' : 'Registered',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isCheckedIn ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${reg.rollNumber} • ${reg.department} (${reg.yearOfStudy})',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '10-Digit: $user10Code',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontFamily: 'monospace',
                                                        fontWeight: FontWeight.bold,
                                                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Pass: $ticketCode',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: isDark ? Colors.white54 : Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (reg.verifiedBy != null && reg.verifiedBy!.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Verified by: ${reg.verifiedBy}',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(
                                            isCheckedIn ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                            color: isCheckedIn ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                            size: 24,
                                          ),
                                          tooltip: isCheckedIn ? 'Already Checked In' : 'Mark Checked In',
                                          onPressed: () {
                                            final nextStatus = isCheckedIn ? 'Registered' : 'Checked In';
                                            stateProvider.updateRegistrationStatus(
                                              reg.id,
                                              nextStatus,
                                              verifiedBy: coordName,
                                            );
                                            HapticFeedback.mediumImpact();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _statusFilter = value;
          });
        }
      },
    );
  }

  Widget _buildMetricPill(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DualVerifierModal extends StatefulWidget {
  final bool isDark;
  final AppStateProvider stateProvider;
  final List<Event> assignedEvents;

  const _DualVerifierModal({
    required this.isDark,
    required this.stateProvider,
    required this.assignedEvents,
  });

  @override
  State<_DualVerifierModal> createState() => _DualVerifierModalState();
}

class _DualVerifierModalState extends State<_DualVerifierModal> {
  int _activeTab = 0; // 0 = Live Camera QR, 1 = Manual 10-Digit Code Entry
  final TextEditingController _manualController = TextEditingController();
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _torchOn = false;
  bool _isProcessingScan = false;
  Registration? _verifiedRegistration;
  String? _verificationMessage;

  @override
  void dispose() {
    _manualController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _verifyCode(String rawInput) {
    final clean = rawInput.trim();
    if (clean.isEmpty) return;

    final assignedIds = widget.assignedEvents.map((e) => e.id).toList();

    final reg = widget.stateProvider.verifyParticipantCode(
      participantCode: clean,
      assignedEventIds: assignedIds.isNotEmpty ? assignedIds : null,
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final coordName = authProvider.currentUser?.name.isNotEmpty == true ? authProvider.currentUser!.name : 'Campus Coordinator';

    debugPrint('📋 SCANNED QR DETAILS: Raw: "$clean" | Student: ${reg?.fullName} | Roll: ${reg?.rollNumber} | VerifiedBy: $coordName');

    setState(() {
      _verifiedRegistration = reg;
      if (reg != null) {
        _verificationMessage = 'VALID';
      } else {
        _verificationMessage = 'NO MATCH: Scanned payload "$clean" was not found in your assigned events.';
      }
    });
  }

  void _onCameraDetect(BarcodeCapture capture) {
    if (_isProcessingScan) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessingScan = true);
    HapticFeedback.mediumImpact();

    final code = barcode.rawValue!.trim();
    _verifyCode(code);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isProcessingScan = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final authProvider = Provider.of<AuthProvider>(context);
    final coordName = authProvider.currentUser?.name.isNotEmpty == true ? authProvider.currentUser!.name : 'Campus Coordinator';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Ticket & Profile Verifier',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dual Option Selector Tab Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTab == 0 ? const Color(0xFF2563EB) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: _activeTab == 0 ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Camera QR Scan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _activeTab == 0 ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTab == 1 ? const Color(0xFF2563EB) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pin_rounded,
                            size: 16,
                            color: _activeTab == 1 ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Enter 10-Digit Code',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _activeTab == 1 ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_activeTab == 0) ...[
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF2563EB), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            MobileScanner(
                              controller: _cameraController,
                              onDetect: _onCameraDetect,
                            ),
                            Center(
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                      color: _torchOn ? Colors.amber : Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _cameraController.toggleTorch();
                                      setState(() => _torchOn = !_torchOn);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 20),
                                    onPressed: () => _cameraController.switchCamera(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan Event Ticket QR or Student Profile QR',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF64748B), fontWeight: FontWeight.bold),
                    ),
                  ] else ...[
                    TextField(
                      controller: _manualController,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      decoration: InputDecoration(
                        hintText: 'Enter 10-digit code or Roll number (e.g. 9876543210)…',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, letterSpacing: 0),
                        prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF2563EB)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                          onPressed: () => _verifyCode(_manualController.text),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.black : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (v) => _verifyCode(v),
                    ),
                  ],

                  if (_verificationMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildVerificationResultCard(context, isDark, coordName),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationResultCard(BuildContext context, bool isDark, String coordName) {
    final reg = _verifiedRegistration;
    if (reg == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INVALID QR / TICKET CODE ❌',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _verificationMessage ?? 'Scanned payload was not found in your assigned events list.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isAlreadyVerified = (reg.status == 'Checked In' || reg.status == 'Attended');
    final profile10Digit = UserModel.generate10DigitParticipantCode(reg.rollNumber);
    final ticketPassCode = reg.id.substring(0, reg.id.length < 10 ? reg.id.length : 10).toUpperCase();
    final eventIdx = widget.stateProvider.events.indexWhere((e) => e.id == reg.eventId);
    final eventTitle = eventIdx != -1 ? widget.stateProvider.events[eventIdx].title : 'Campus Event';
    final verifiedByDisplay = reg.verifiedBy ?? coordName;
    final formattedTime = reg.verifiedAt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(reg.verifiedAt!)
        : DateFormat('MMM d, yyyy • h:mm a').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAlreadyVerified
            ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
            : const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlreadyVerified ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAlreadyVerified ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAlreadyVerified ? Icons.verified_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAlreadyVerified ? 'ALREADY VERIFIED ✅' : 'TICKET VERIFIED VALID 🎟️',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isAlreadyVerified ? const Color(0xFFD97706) : const Color(0xFF059669),
                      ),
                    ),
                    Text(
                      isAlreadyVerified
                          ? 'Student is marked ${reg.status} for this event.'
                          : 'Ready for coordinator check-in.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAlreadyVerified
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                      : const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAlreadyVerified ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  ),
                ),
                child: Text(
                  reg.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isAlreadyVerified ? const Color(0xFFD97706) : const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 10-DIGIT CODE HERO BANNER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pin_rounded, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Text(
                      '10-DIGIT PARTICIPANT CODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  profile10Digit,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: Color(0xFF2563EB),
                  ),
                ),
                Text(
                  'Ticket Pass Code: $ticketPassCode',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (isAlreadyVerified) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified by Coordinator: $verifiedByDisplay\nTime: $formattedTime',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow('Student Name', reg.fullName, isDark, isBold: true),
                const Divider(height: 12),
                _buildDetailRow('Roll Number', reg.rollNumber, isDark),
                const Divider(height: 12),
                _buildDetailRow('Branch / Dept', '${reg.department} (${reg.yearOfStudy} Year)', isDark),
                const Divider(height: 12),
                _buildDetailRow('Phone Number', reg.phoneNumber, isDark),
                const Divider(height: 12),
                _buildDetailRow('Linked Event', eventTitle, isDark, isBold: true),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.stateProvider.updateRegistrationStatus(
                  reg.id,
                  'Checked In',
                  verifiedBy: coordName,
                );
                setState(() {
                  _verifiedRegistration = reg.copyWith(
                    status: 'Checked In',
                    verifiedBy: coordName,
                    verifiedAt: DateTime.now(),
                  );
                });
                HapticFeedback.mediumImpact();
              },
              icon: Icon(
                isAlreadyVerified ? Icons.check_circle_rounded : Icons.how_to_reg_rounded,
                size: 18,
              ),
              label: Text(
                isAlreadyVerified
                    ? 'Already Verified by $verifiedByDisplay ✓'
                    : 'Mark Verified & Checked In by $coordName',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAlreadyVerified ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
