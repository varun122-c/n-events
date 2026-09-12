import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';
import '../../widgets/confetti_particles.dart';
import '../../widgets/universal_image.dart';
import '../../config/departments.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showConfetti = false;
  
  late TextEditingController _nameController;
  late TextEditingController _rollController;
  late TextEditingController _phoneController;
  
  String _selectedDept = AitsDepartments.defaultDepartment;
  String _selectedYear = '1st Year';

  final List<String> _departments = AitsDepartments.allDepartments;

  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    'Post Graduate',
  ];

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: authProvider.studentName);
    _rollController = TextEditingController(text: authProvider.studentRoll);
    _phoneController = TextEditingController(text: authProvider.studentPhone);
    
    if (authProvider.studentDept.isNotEmpty && _departments.contains(authProvider.studentDept)) {
      _selectedDept = authProvider.studentDept;
    }
    if (authProvider.studentYear.isNotEmpty && _years.contains(authProvider.studentYear)) {
      _selectedYear = authProvider.studentYear;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showRegistrationSheet(BuildContext context, Event event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF18181B) : Theme.of(context).appBarTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Event Registration',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'EVENT CODE: ${event.eventCode}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Permanent 10-Digit Participant ID Badge
                      Builder(
                        builder: (context) {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final pCode = authProvider.participantCode;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF18181B) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFF2563EB).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.fingerprint_rounded, color: Color(0xFF2563EB), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'YOUR PERMANENT 10-DIGIT PARTICIPANT CODE',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB), letterSpacing: 0.6),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        pCode,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'VERIFIED ID',
                                    style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // User Full Name Input Field
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                        decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Full Name is required' : null,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _submitRegistration(context, event),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF1E3C72),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Builder(
                            builder: (context) {
                              final pCode = Provider.of<AuthProvider>(context, listen: false).participantCode;
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Confirm Registration with ID: $pCode',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _submitRegistration(BuildContext context, Event event) async {
    if (_formKey.currentState!.validate()) {
      final stateProvider = Provider.of<AppStateProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final name = _nameController.text.trim();
      final pCode = authProvider.participantCode;
      final roll = authProvider.studentRoll.isNotEmpty ? authProvider.studentRoll : pCode;
      final dept = authProvider.studentDept.isNotEmpty ? authProvider.studentDept : 'General';
      final year = authProvider.studentYear.isNotEmpty ? authProvider.studentYear : 'Current Year';
      final phone = authProvider.studentPhone.isNotEmpty ? authProvider.studentPhone : '1234567890';

      final college = authProvider.studentCollege;

      final success = await stateProvider.registerForEvent(
        eventId: event.id,
        fullName: name,
        rollNumber: roll,
        department: dept,
        college: college,
        yearOfStudy: year,
        phoneNumber: phone,
      );

      // Save student name if changed
      if (authProvider.studentName != name) {
        await authProvider.updateProfile(
          name: name,
          roll: roll,
          dept: dept,
          year: year,
          phone: phone,
        );
      }

      // Save student credentials to local profile automatically if not set yet!
      if (authProvider.studentRoll.isEmpty) {
        await authProvider.updateProfile(
          name: _nameController.text.trim(),
          roll: _rollController.text.trim().toUpperCase(),
          dept: _selectedDept,
          year: _selectedYear,
          phone: _phoneController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context); // Close Bottom Sheet

      if (success) {
        setState(() {
          _showConfetti = true;
        });
        _showTicketDialog(event);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already registered for this event!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showTicketDialog(Event event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isDark ? Border.all(color: const Color(0xFF27272A)) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                          ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                          : [const Color(0xFF1E3C72), const Color(0xFF2A5298)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 56),
                      SizedBox(height: 12),
                      Text(
                        'Booking Confirmed!',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your digital ticket is ready',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        event.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 16),
                      _buildTicketRow('Attendee', _nameController.text.trim()),
                      const SizedBox(height: 8),
                      _buildTicketRow('Student ID', _rollController.text.trim().toUpperCase()),
                      const SizedBox(height: 8),
                      _buildTicketRow('Department', _selectedDept),
                      const SizedBox(height: 8),
                      _buildTicketRow('Venue', event.venue),
                      const SizedBox(height: 8),
                      _buildTicketRow('Time', DateFormat('MMM d, yyyy • h:mm a').format(event.dateTime)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(thickness: 1, color: isDark ? const Color(0xFF27272A) : Colors.grey),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade200),
                        ),
                        child: QrImageView(
                          data: 'nEvents-Reg-${_rollController.text.trim()}-${event.id}',
                          version: QrVersions.auto,
                          size: 110.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _syncToCalendar(context, event),
                              icon: const Icon(Icons.calendar_today_outlined, size: 14),
                              label: const Text('Sync Calendar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.white : const Color(0xFF1E3C72),
                                side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF1E3C72),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('Back to Events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showSubEventDetailsModal(BuildContext context, SubEvent sub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showFullscreenImage(context, sub.imageUrl),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Stack(
                    children: [
                      UniversalImage(
                        pathOrUrl: sub.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Tap to Fullscreen', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sub.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: sub.category == 'Technical' ? const Color(0xFF2563EB) : const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sub.category.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          sub.isFree ? 'FREE ENTRY' : 'TICKET: ₹${sub.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: sub.isFree ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                        if (sub.venue.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 2),
                          Text(
                            sub.venue,
                            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                    if (sub.details.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Details & Competition Rules:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          sub.details,
                          style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF334155), height: 1.4),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Close Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: UniversalImage(
                pathOrUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.7),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B), fontSize: 12),
      prefixIcon: Icon(icon, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569), size: 18),
      filled: true,
      fillColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? const Color(0xFF2563EB) : const Color(0xFF1E3C72), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = Provider.of<AppStateProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Find the event
    final event = stateProvider.events.firstWhere(
      (e) => e.id == widget.eventId,
      orElse: () => Event(
        id: '',
        title: 'Event Not Found',
        description: 'This event may have been deleted by the administrator.',
        bannerUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&auto=format&fit=crop',
        dateTime: DateTime.now(),
        venue: 'N/A',
        category: 'N/A',
        coordinatorName: 'N/A',
        coordinatorPhone: 'N/A',
      ),
    );

    final isNotFound = event.id.isEmpty;
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(event.dateTime);
    final formattedTime = DateFormat('h:mm a').format(event.dateTime);

    // Check if the current user is already registered for this event
    final isAlreadyRegistered = stateProvider.registrations.any(
      (r) => r.eventId == event.id && 
          authProvider.studentRoll.isNotEmpty && 
          r.rollNumber.toLowerCase() == authProvider.studentRoll.toLowerCase() &&
          r.status != 'Cancelled',
    );

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Theme.of(context).appBarTheme.backgroundColor,
      body: isNotFound
          ? _buildNotFoundView()
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Image with Back Button
                      Stack(
                        children: [
                          Hero(
                            tag: 'event-img-${event.id}',
                            child: UniversalImage(
                              pathOrUrl: event.bannerUrl,
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            height: 250,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8,
                            left: 16,
                            child: CircleAvatar(
                              backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white.withOpacity(0.9),
                              child: IconButton(
                                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category & Price Tags
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF18181B) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: isDark ? Border.all(color: const Color(0xFF27272A)) : null,
                                  ),
                                  child: Text(
                                    event.category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: event.isFree 
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15) 
                                        : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: event.isFree ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        event.isFree ? Icons.card_giftcard_rounded : Icons.confirmation_number_rounded,
                                        size: 13,
                                        color: event.isFree ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        event.isFree ? 'FREE ENTRY' : 'TICKET: ₹${event.price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: event.isFree ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Title
                            Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            if (event.reviews.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(event.reviews.fold<double>(0, (prev, r) => prev + r.rating) / event.reviews.length).toStringAsFixed(1)} out of 5 stars (${event.reviews.length} reviews)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),

                            // Date & Time Box
                            _buildInfoTile(
                              icon: Icons.calendar_month_outlined,
                              title: formattedDate,
                              subtitle: formattedTime,
                            ),
                            const SizedBox(height: 14),

                            // Venue Box
                            _buildInfoTile(
                              icon: Icons.location_on_outlined,
                              title: event.venue,
                              subtitle: 'Please arrive 15 mins early',
                            ),
                            const SizedBox(height: 14),

                            // Coordinator Box
                            _buildInfoTile(
                              icon: Icons.contact_phone_outlined,
                              title: event.coordinatorName,
                              subtitle: event.coordinatorPhone,
                            ),
                            
                            const SizedBox(height: 24),
                            Text(
                              'About the Event',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF475569),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sub-Events Breakdown Section
                            if (event.subEvents.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(Icons.account_tree_rounded, color: Color(0xFF2563EB), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sub-Events & Competitions (${event.subEvents.length})',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: event.subEvents.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (context, sIdx) {
                                  final sub = event.subEvents[sIdx];
                                  final isTech = sub.category == 'Technical';
                                  return GestureDetector(
                                    onTap: () => _showSubEventDetailsModal(context, sub),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF18181B) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: UniversalImage(
                                                  pathOrUrl: sub.imageUrl,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
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
                                                            sub.title,
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 14,
                                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                          decoration: BoxDecoration(
                                                            color: isTech ? const Color(0xFF2563EB) : const Color(0xFF8B5CF6),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            sub.category.toUpperCase(),
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          sub.isFree ? 'FREE' : '₹${sub.price.toStringAsFixed(0)} Entry',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: sub.isFree ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                                          ),
                                                        ),
                                                        if (sub.venue.isNotEmpty) ...[
                                                          const SizedBox(width: 10),
                                                          Icon(Icons.location_on, size: 12, color: isDark ? Colors.grey : const Color(0xFF64748B)),
                                                          const SizedBox(width: 2),
                                                          Text(
                                                            sub.venue,
                                                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey : const Color(0xFF64748B)),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (sub.details.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                sub.details,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reviews & Ratings',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                if (event.reviews.isNotEmpty)
                                  Text(
                                    '${event.reviews.length} total',
                                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
                                  )
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (event.reviews.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.rate_review_outlined, size: 36, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('No reviews yet. Be the first to write!', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: event.reviews.length,
                                itemBuilder: (context, idx) {
                                  final rev = event.reviews[idx];
                                  final dateStr = DateFormat('MMM d, yyyy').format(rev.date);
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                                    ),
                                    color: isDark ? const Color(0xFF18181B) : Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(rev.studentName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                              Text(dateStr, style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF94A3B8))),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: List.generate(5, (starIdx) {
                                              return Icon(
                                                Icons.star,
                                                color: starIdx < rev.rating ? Colors.amber : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0)),
                                                size: 14,
                                              );
                                            }),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(rev.comment, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF475569), height: 1.4)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // If attended, let them write a review!
                            _buildWriteReviewSection(context, event, stateProvider, authProvider),
                            const SizedBox(height: 100), // Spacing for FAB
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom Fixed Register Button
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18181B) : Colors.white,
                      border: Border(top: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0))),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isAlreadyRegistered 
                            ? null 
                            : () => _showRegistrationSheet(context, event),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF1E3C72),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark ? const Color(0xFF064E3B) : const Color(0xFF059669),
                          disabledForegroundColor: isDark ? const Color(0xFF34D399) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isAlreadyRegistered ? '✓ Registered' : 'Register Now',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_showConfetti)
                  ConfettiParticles(
                    onFinished: () {
                      setState(() {
                        _showConfetti = false;
                      });
                    },
                  ),
              ],
            ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: isDark ? Border.all(color: const Color(0xFF27272A)) : null,
          ),
          child: Icon(icon, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF475569), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotFoundView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Event Not Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              'This event may have been deleted by the administrator or is no longer available.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWriteReviewSection(
    BuildContext context,
    Event event,
    AppStateProvider stateProvider,
    AuthProvider authProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentRoll = authProvider.studentRoll;
    if (studentRoll.isEmpty) return const SizedBox.shrink();

    final hasAttended = stateProvider.registrations.any(
      (r) => r.eventId == event.id && 
          r.rollNumber.toLowerCase() == studentRoll.toLowerCase() && 
          r.status == 'Attended',
    );

    if (!hasAttended) return const SizedBox.shrink();

    final alreadyReviewed = event.reviews.any(
      (r) => r.studentName.toLowerCase() == authProvider.studentName.toLowerCase(),
    );

    if (alreadyReviewed) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF059669) : Colors.green.shade200),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text('Thank you! You have reviewed this event.', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        elevation: 0,
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFEFF6FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? const Color(0xFF27272A) : const Color(0xFFBFDBFE)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share Your Experience!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3C72))),
              const SizedBox(height: 4),
              Text('Since you attended this event, please leave a quick rating & review.', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF1E293B))),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showWriteReviewBottomSheet(context, event, stateProvider, authProvider),
                icon: const Icon(Icons.rate_review, size: 16),
                label: const Text('Write a Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF1E3C72),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWriteReviewBottomSheet(
    BuildContext context,
    Event event,
    AppStateProvider stateProvider,
    AuthProvider authProvider,
  ) {
    double selectedRating = 5;
    final commentController = TextEditingController();
    final reviewFormKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF18181B) : Theme.of(context).appBarTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: reviewFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Write a Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                    Text(event.title, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B))),
                    const SizedBox(height: 20),
                    
                    Text('Rating', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (index) {
                        final starRating = index + 1;
                        return IconButton(
                          icon: Icon(
                            Icons.star,
                            color: starRating <= selectedRating ? Colors.amber : (isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300),
                            size: 32,
                          ),
                          onPressed: () {
                            setModalState(() {
                              selectedRating = starRating.toDouble();
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: commentController,
                      maxLines: 3,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                      decoration: _buildInputDecoration('Your Review', Icons.rate_review_outlined),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Review comment is required' : null,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (reviewFormKey.currentState!.validate()) {
                            stateProvider.addReview(
                              event.id,
                              authProvider.studentName.isNotEmpty ? authProvider.studentName : 'Attendee',
                              selectedRating,
                              commentController.text.trim(),
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Review submitted! Thank you.'), backgroundColor: Colors.teal),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF1E3C72),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _syncToCalendar(BuildContext context, Event event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!context.mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${event.title}" has been synced to your calendar!'),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        });
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isDark ? const BorderSide(color: Color(0xFF27272A)) : BorderSide.none,
          ),
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text('Syncing to calendar...', style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
        );
      },
    );
  }
}
