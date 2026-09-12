import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../models/registration_model.dart';
import '../../models/event_model.dart';

class AdminParticipantsScreen extends StatefulWidget {
  final String eventId;
  const AdminParticipantsScreen({super.key, required this.eventId});

  @override
  State<AdminParticipantsScreen> createState() => _AdminParticipantsScreenState();
}

class _AdminParticipantsScreenState extends State<AdminParticipantsScreen> {
  String _searchQuery = '';

  void _exportCSV(List<Registration> regs, String eventTitle) {
    if (regs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No participants to export!'), backgroundColor: Colors.amber),
      );
      return;
    }

    final StringBuffer csv = StringBuffer();
    // Headers
    csv.writeln('Roll Number,Full Name,College,Department,Year of Study,Phone Number,Registration Date,Status');
    
    for (final r in regs) {
      final regDate = DateFormat('yyyy-MM-dd HH:mm').format(r.registrationDate);
      csv.writeln('"${r.rollNumber}","${r.fullName}","${r.college}","${r.department}","${r.yearOfStudy}","${r.phoneNumber}","$regDate","${r.status}"');
    }

    Clipboard.setData(ClipboardData(text: csv.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV copied to clipboard for "$eventTitle"!'),
        backgroundColor: const Color(0xFF059669),
        action: SnackBarAction(
          label: 'Preview',
          textColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('CSV Preview'),
                content: SingleChildScrollView(
                  child: Text(
                    csv.toString(),
                    style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showQrVerificationModal(BuildContext context, List<Registration> regs, AppStateProvider stateProvider) {
    final searchController = TextEditingController();
    Registration? matchedReg;
    bool searched = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2563EB), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Scan & Verify Entry Pass',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter Roll Number or QR payload to verify registration status',
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Enter Roll No (e.g. 22CS014) or Pass Data',
                              hintStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF2563EB), size: 20),
                              filled: true,
                              fillColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final q = searchController.text.trim().toLowerCase();
                            if (q.isEmpty) return;
                            Registration? found;
                            for (final r in regs) {
                              if (r.rollNumber.toLowerCase() == q ||
                                  r.id.toLowerCase() == q ||
                                  q.contains(r.rollNumber.toLowerCase())) {
                                found = r;
                                break;
                              }
                            }
                            setSheetState(() {
                              matchedReg = found;
                              searched = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (searched && matchedReg == null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ENTRY DENIED - UNREGISTERED', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900, fontSize: 13)),
                                  Text('No matching student registration found for this QR pass', style: TextStyle(color: Color(0xFF991B1B), fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (searched && matchedReg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        matchedReg!.fullName,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        '${matchedReg!.rollNumber} • ${matchedReg!.department}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF059669)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    matchedReg!.status.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('PHONE: +91 ${matchedReg!.phoneNumber}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                Text('YEAR: ${matchedReg!.yearOfStudy}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (matchedReg!.status != 'Attended')
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    stateProvider.updateRegistrationStatus(matchedReg!.id, 'Attended');
                                    setSheetState(() {
                                      matchedReg = Registration(
                                        id: matchedReg!.id, eventId: matchedReg!.eventId, rollNumber: matchedReg!.rollNumber,
                                        fullName: matchedReg!.fullName, department: matchedReg!.department, yearOfStudy: matchedReg!.yearOfStudy,
                                        phoneNumber: matchedReg!.phoneNumber, registrationDate: matchedReg!.registrationDate, status: 'Attended',
                                      );
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Marked ${matchedReg!.fullName} as Attended! ✓'),
                                        backgroundColor: const Color(0xFF10B981),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                                  label: const Text('GRANT ENTRY & MARK ATTENDED', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<AppStateProvider>(context);
    
    // Find event
    final event = stateProvider.events.firstWhere(
      (e) => e.id == widget.eventId,
      orElse: () => Event(
        id: '', title: 'Unknown Event', description: '', bannerUrl: '',
        dateTime: DateTime.now(), venue: '', category: '', coordinatorName: '', coordinatorPhone: ''
      ),
    );

    // Get event registrations
    final eventRegs = stateProvider.registrations
        .where((r) => r.eventId == widget.eventId)
        .toList();

    // Filter registrations by search query
    final filteredRegs = eventRegs.where((r) {
      return r.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.rollNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.department.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.college.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Metrics
    final total = eventRegs.length;
    final attended = eventRegs.where((r) => r.status == 'Attended').length;
    final registered = eventRegs.where((r) => r.status == 'Registered').length;
    final cancelled = eventRegs.where((r) => r.status == 'Cancelled').length;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B)),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Participant roster & data gathering',
              style: TextStyle(fontSize: 10, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF10B981)),
            tooltip: 'Live Camera QR Scanner',
            onPressed: () => context.push('/staff/scanner'),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Manual Code Verification',
            onPressed: () => _showQrVerificationModal(context, eventRegs, stateProvider),
          ),
          IconButton(
            icon: const Icon(Icons.copy_all, color: Color(0xFF1E3C72)),
            tooltip: 'Export CSV',
            onPressed: () => _exportCSV(eventRegs, event.title),
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Statistics Summary Row
          Container(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCountBox('Registered', registered, Colors.blue),
                _buildCountBox('Attended', attended, Colors.green),
                _buildCountBox('Cancelled', cancelled, Colors.red),
                _buildCountBox('Total Roster', total, Colors.blueGrey),
              ],
            ),
          ),

          // Certificate Batch Publish Bar
          if (attended > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFF10B981), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Publish Certificates for $attended Verified Student${attended == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        for (final r in eventRegs) {
                          if (r.status == 'Attended' || r.status == 'Checked In') {
                            stateProvider.publishCertificate(r.id);
                          }
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Published all certificates for $attended verified students! 🎓'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 14),
                      label: const Text('Publish All 🎓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'Search by student name, roll number, dept...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
          ),

          // Roster List
          Expanded(
            child: filteredRegs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredRegs.length,
                    itemBuilder: (context, index) {
                      final reg = filteredRegs[index];
                      return _buildParticipantCard(context, reg, stateProvider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBox(String label, int value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildParticipantCard(BuildContext context, Registration reg, AppStateProvider stateProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final regDate = DateFormat('MMM d • h:mm a').format(reg.registrationDate);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0)),
      ),
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reg.fullName,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildInteractiveStatus(context, reg, stateProvider),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Roll No: ${reg.rollNumber}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF475569)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  regDate,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reg.college}\n${reg.department} • ${reg.yearOfStudy}',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Phone: ${reg.phoneNumber}',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                      ),
                      if (reg.status == 'Checked In' || reg.status == 'Attended') ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Text(
                            'Verified ✅ by Coordinator: ${reg.verifiedBy ?? "Campus Coordinator"}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Colors.blueGrey, size: 18),
                      tooltip: 'Copy contact details',
                      onPressed: () {
                        final text = 'Name: ${reg.fullName}\nID: ${reg.rollNumber}\nCollege: ${reg.college}\nDept: ${reg.department}\nPhone: ${reg.phoneNumber}\nVerifiedBy: ${reg.verifiedBy ?? "N/A"}';
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Details copied to clipboard.'), duration: Duration(seconds: 1)),
                        );
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 6),
                    if (reg.status == 'Checked In' || reg.status == 'Attended')
                      ElevatedButton.icon(
                        onPressed: reg.isCertificatePublished
                            ? null
                            : () {
                                stateProvider.publishCertificate(reg.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Certificate published for ${reg.fullName}! 🎓'),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              },
                        icon: Icon(
                          reg.isCertificatePublished ? Icons.verified_rounded : Icons.card_membership_rounded,
                          size: 14,
                        ),
                        label: Text(
                          reg.isCertificatePublished ? 'Cert Published 🎓' : 'Publish Cert 🎓',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: reg.isCertificatePublished ? const Color(0xFF047857) : const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveStatus(BuildContext context, Registration reg, AppStateProvider stateProvider) {
    Color color;
    switch (reg.status) {
      case 'Registered':
        color = Colors.blue;
        break;
      case 'Attended':
        color = Colors.green;
        break;
      case 'Cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return PopupMenuButton<String>(
      initialValue: reg.status,
      onSelected: (String status) {
        stateProvider.updateRegistrationStatus(reg.id, status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${reg.fullName} status updated to $status!'),
            backgroundColor: status == 'Attended' ? Colors.green : Colors.blueGrey,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'Registered',
          child: Row(
            children: [
              Icon(Icons.circle_outlined, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Text('Registered', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'Attended',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text('Attended (Issues Cert)', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'Cancelled',
          child: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Cancelled', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reg.status,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 56, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            'No participants registered yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          SizedBox(height: 6),
          Text(
            'Students who register for this event will appear here.',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
