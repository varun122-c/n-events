import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';
import '../../widgets/top_notification.dart';

class StudentTicketsScreen extends StatelessWidget {
  const StudentTicketsScreen({super.key});

  void _copyToClipboard(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    TopNotification.showSuccess(context, 'Copied $label to clipboard!');
  }

  void _showFullscreenTicketModal(BuildContext context, String ticketQrData, String eventTitle, String studentName, String studentRoll) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.confirmation_number_rounded, color: Color(0xFF2563EB), size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                eventTitle,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        QrImageView(
                          data: ticketQrData,
                          version: QrVersions.auto,
                          size: 230.0,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0F172A),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0F172A),
                          ),
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                          backgroundColor: Colors.white,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Image.asset('assets/images/logo.png', width: 32, height: 32),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    studentName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'ID: $studentRoll',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _copyToClipboard(context, 'Ticket QR Data', ticketQrData);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Event Ticket Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<AppStateProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final studentRoll = authProvider.studentRoll;
    final studentPhone = authProvider.studentPhone;
    final studentName = authProvider.studentName.isNotEmpty ? authProvider.studentName : 'Student User';
    final cleanPhone = studentPhone.replaceAll(RegExp(r'\D'), '');

    // Filter student registrations
    final registrations = stateProvider.registrations.where((r) {
      final matchRoll = studentRoll.isNotEmpty && r.rollNumber.toLowerCase() == studentRoll.toLowerCase();
      final matchPhone = cleanPhone.isNotEmpty && r.phoneNumber.replaceAll(RegExp(r'\D'), '') == cleanPhone;
      return matchRoll || matchPhone;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Provider.of<AppStateProvider>(context, listen: false).setStudentTabIndex(0);
              context.go('/student');
            }
          },
        ),
        title: Row(
          children: [
            const Icon(Icons.confirmation_number_rounded, color: Color(0xFF2563EB), size: 22),
            const SizedBox(width: 8),
            Text(
              'My Event Tickets',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
      body: registrations.isEmpty
          ? _buildEmptyTicketsView(context, isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: registrations.length,
              itemBuilder: (context, index) {
                final reg = registrations[index];
                final event = stateProvider.events.firstWhere(
                  (e) => e.id == reg.eventId,
                  orElse: () => Event(
                    id: reg.eventId,
                    title: 'Campus Event',
                    description: '',
                    bannerUrl: '',
                    dateTime: DateTime.now(),
                    venue: 'Campus Main Hall',
                    category: 'Technical',
                    coordinatorName: 'Event Coordinator',
                    coordinatorPhone: '',
                  ),
                );

                final pCode = authProvider.participantCode;
                final ticketQrData = jsonEncode({
                  'name': studentName,
                  'code': pCode,
                  'eventCode': event.eventCode,
                });

                final formattedDate = DateFormat('EEE, MMM d • h:mm a').format(event.dateTime);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Banner with Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(reg.status, isDark),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.confirmation_number_outlined, size: 16, color: _getStatusTextColor(reg.status)),
                                const SizedBox(width: 6),
                                Text(
                                  event.category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: _getStatusTextColor(reg.status),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF18181B) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: isDark ? Border.all(color: const Color(0xFF27272A)) : null,
                              ),
                              child: Text(
                                reg.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : _getStatusTextColor(reg.status, isDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'CODE: ${event.eventCode}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'USER ID: $pCode',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF2563EB)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    formattedDate,
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF2563EB)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    event.venue,
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // QR Ticket Pass Matrix with Stack Overlay
                            Center(
                              child: GestureDetector(
                                onTap: () => _showFullscreenTicketModal(context, ticketQrData, event.title, studentName, reg.rollNumber),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      QrImageView(
                                        data: ticketQrData,
                                        version: QrVersions.auto,
                                        size: 160.0,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Color(0xFF0F172A),
                                        ),
                                        dataModuleStyle: const QrDataModuleStyle(
                                          dataModuleShape: QrDataModuleShape.square,
                                          color: Color(0xFF0F172A),
                                        ),
                                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                                        backgroundColor: Colors.white,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.asset('assets/images/logo.png', width: 24, height: 24),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Coordinator Verification Status Badge
                            if (reg.status == 'Checked In' || reg.status == 'Attended')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF10B981)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 15),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Verified ✅ by Coordinator: ${reg.verifiedBy ?? "Campus Coordinator"}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFF59E0B)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 13),
                                    SizedBox(width: 5),
                                    Text(
                                      'Pending Verification ⏳ Show QR at Entry',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 14),

                            // Ticket Actions
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showFullscreenTicketModal(context, ticketQrData, event.title, studentName, reg.rollNumber),
                                    icon: const Icon(Icons.fullscreen_rounded, size: 16),
                                    label: const Text('Enlarge QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2563EB),
                                      side: const BorderSide(color: Color(0xFF2563EB)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.push('/student/chat/${event.id}/${reg.rollNumber}'),
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                    label: const Text('Chat Coord', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyTicketsView(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.confirmation_number_outlined, size: 56, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Event Tickets Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register for upcoming campus tech events or hackathons to get your instant entry QR pass ticket!',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/student'),
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text('Explore Campus Events'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusBgColor(String status, bool isDark) {
    switch (status) {
      case 'Attended':
        return isDark ? const Color(0xFF065F46) : const Color(0xFFECFDF5);
      case 'Cancelled':
        return isDark ? const Color(0xFF991B1B) : const Color(0xFFFEF2F2);
      default:
        return isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
    }
  }

  Color _getStatusTextColor(String status, [bool isDark = false]) {
    switch (status) {
      case 'Attended':
        return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      case 'Cancelled':
        return isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      default:
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    }
  }
}
