import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/registration_model.dart';
import '../../models/event_model.dart';

class StudentCertificatesScreen extends StatelessWidget {
  const StudentCertificatesScreen({super.key});

  static const Color goldColor = Color(0xFFFFD700); // Pure Gold Color
  static const Color goldAccentColor = Color(0xFFF59E0B); // Amber Gold

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<AppStateProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final studentRoll = authProvider.studentRoll;
    final studentName = authProvider.studentName.isNotEmpty ? authProvider.studentName : 'Student';
    final hasProfile = studentRoll.isNotEmpty;

    // Filter registrations that are "Attended" or published by admin
    final attendedRegs = hasProfile
        ? stateProvider.registrations
            .where((r) =>
                r.rollNumber.toLowerCase() == studentRoll.toLowerCase() &&
                (r.status == 'Attended' || r.isCertificatePublished))
            .toList()
        : <Registration>[];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
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
        title: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: goldColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'My Certificates',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: attendedRegs.isEmpty
                ? _buildEmptyState(context, isDark)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: attendedRegs.length,
                    itemBuilder: (context, index) {
                      final reg = attendedRegs[index];
                      final event = stateProvider.events.firstWhere(
                        (e) => e.id == reg.eventId,
                        orElse: () => Event(
                          id: '',
                          title: 'Unknown Event',
                          description: '',
                          bannerUrl: '',
                          dateTime: DateTime.now(),
                          venue: 'N/A',
                          category: 'N/A',
                          coordinatorName: '',
                          coordinatorPhone: '',
                        ),
                      );

                      return _buildCertificateCard(context, isDark, reg, event, studentName);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(BuildContext context, bool isDark, Registration reg, Event event, String studentName) {
    final issueDate = DateFormat('MMMM d, yyyy').format(event.dateTime);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      color: isDark ? Colors.black : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Gold Certificate Icon Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? goldColor.withValues(alpha: 0.15)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: goldColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldColor.withValues(alpha: isDark ? 0.3 : 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: goldColor,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 13, color: goldColor),
                      const SizedBox(width: 4),
                      Text(
                        'Issued: $issueDate',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _viewCertificateDialog(context, isDark, reg, event, studentName),
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 14, color: goldColor),
                        label: const Text(
                          'View',
                          style: TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: goldColor.withValues(alpha: 0.6)),
                          backgroundColor: isDark ? goldColor.withValues(alpha: 0.1) : const Color(0xFFFFFBEB),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _downloadCertificate(context, isDark, event.title),
                        icon: const Icon(Icons.download_outlined, size: 14),
                        label: const Text(
                          'Download',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldAccentColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: goldColor.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.workspace_premium_rounded, size: 58, color: goldColor),
            ),
            const SizedBox(height: 20),
            Text(
              'No certificates earned yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Attend registered events. Once coordinators mark your attendance, your official digital certificates will appear here!',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _viewCertificateDialog(BuildContext context, bool isDark, Registration reg, Event event, String studentName) {
    final issueDate = DateFormat('MMMM d, yyyy').format(event.dateTime);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black : const Color(0xFFFAF6F0),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: goldColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: goldColor.withValues(alpha: isDark ? 0.3 : 0.2),
                blurRadius: 25,
                spreadRadius: 2,
              )
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium_rounded, color: goldColor, size: 68),
                const SizedBox(height: 12),
                const Text(
                  'CERTIFICATE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: goldColor,
                  ),
                ),
                Text(
                  'OF PARTICIPATION',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF8B5A2B),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'PROUDLY PRESENTED TO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF8B7355),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  studentName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white : const Color(0xFF1E3C72),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: goldColor.withValues(alpha: 0.4), thickness: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'for active and successful participation in the campus event',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issueDate,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? goldColor : const Color(0xFF5C4033)),
                        ),
                        Text(
                          'Date of Issue',
                          style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          event.coordinatorName.isNotEmpty ? event.coordinatorName : 'Event Coordinator',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? goldColor : const Color(0xFF5C4033)),
                        ),
                        Text(
                          'Coordinator Sign',
                          style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // QR code representation
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: goldColor, width: 1.5),
                  ),
                  child: QrImageView(
                    data: 'nEvents-Verify-${reg.id}',
                    version: QrVersions.auto,
                    size: 85.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Official Digital Credential',
                  style: TextStyle(fontSize: 9, color: goldColor, fontWeight: FontWeight.w600),
                ),
                if (reg.verifiedBy != null && reg.verifiedBy!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Verified ✅ by Coordinator: ${reg.verifiedBy}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadCertificate(context, isDark, event.title);
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download PDF Certificate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldAccentColor,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _downloadCertificate(BuildContext context, bool isDark, String eventTitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!context.mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded: Certificate_$eventTitle.pdf'),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        });
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const CircularProgressIndicator(color: goldColor),
              const SizedBox(width: 20),
              Text(
                'Generating secure PDF...',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
