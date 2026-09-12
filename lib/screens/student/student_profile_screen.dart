import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/image_cropper_dialog.dart';
import '../../widgets/universal_image.dart';

enum ProfileViewMode {
  normal,
  qrCode,
  activity,
}

// Reusable Animated Bounce Button Widget for tactile micro-interactions
class AnimatedBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedBounceButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<AnimatedBounceButton> createState() => _AnimatedBounceButtonState();
}

class _AnimatedBounceButtonState extends State<AnimatedBounceButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: widget.child,
        ),
      ),
    );
  }
}

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> with TickerProviderStateMixin {
  ProfileViewMode _viewMode = ProfileViewMode.normal;
  late AnimationController _scanController;
  late AnimationController _qrAnimationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _qrScaleAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _qrAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _qrScaleAnimation = CurvedAnimation(
      parent: _qrAnimationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _qrAnimationController.dispose();
    super.dispose();
  }

  void _switchViewMode(ProfileViewMode mode) {
    if (_viewMode == mode) return;
    setState(() {
      _viewMode = mode;
    });
    if (mode == ProfileViewMode.qrCode) {
      _qrAnimationController.forward(from: 0.0);
    }
  }

  void _copyToClipboard(BuildContext context, String label, String value) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    TopNotification.showSuccess(context, 'Copied $label to clipboard!');
  }

  Future<void> _pickImage(BuildContext context, AuthProvider authProvider, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile != null && context.mounted) {
        // Open Interactive Crop Dialog
        final croppedPath = await ImageCropperDialog.openCropper(
          context,
          File(pickedFile.path),
        );

        if (croppedPath != null && croppedPath.isNotEmpty) {
          await authProvider.updateProfile(
            name: authProvider.studentName,
            roll: authProvider.studentRoll,
            dept: authProvider.studentDept,
            college: authProvider.studentCollege,
            year: authProvider.studentYear,
            phone: authProvider.studentPhone,
            customAvatarUrl: croppedPath,
          );
          if (context.mounted) {
            TopNotification.showSuccess(
              context,
              'Profile picture cropped & updated instantly! ✓',
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        TopNotification.showError(context, 'Could not crop/select image: $e');
      }
    }
  }

  void _showImagePickerModal(BuildContext context, AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Profile Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose live camera capture or device gallery image',
                style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(context, authProvider, ImageSource.camera);
                      },
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Live Camera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(context, authProvider, ImageSource.gallery);
                      },
                      icon: const Icon(Icons.photo_library_rounded, size: 18, color: Color(0xFF2563EB)),
                      label: const Text('Gallery Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }



  void _showFullscreenQrModal(BuildContext context, String qrData, String name, String roll) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.qr_code_2_rounded, color: Color(0xFF2563EB), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Campus Entry Pass',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
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
                        data: qrData,
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
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'ID: $roll',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AnimatedBounceButton(
                    onTap: () {
                      _copyToClipboard(context, 'QR Code Pass Payload', qrData);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Copy Digital Pass Payload',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final stateProvider = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = authProvider.studentName.isNotEmpty ? authProvider.studentName : 'Student User';
    final roll = authProvider.studentRoll.isNotEmpty ? authProvider.studentRoll : '22CS014';
    final email = authProvider.currentUser?.email ?? 'student@gmail.com';
    final phone = authProvider.studentPhone.isNotEmpty ? authProvider.studentPhone : '9876543210';
    final gender = authProvider.studentGender.isNotEmpty ? authProvider.studentGender : 'Male';
    final dept = authProvider.studentDept.isNotEmpty ? authProvider.studentDept : 'Computer Science and Engineering (CSE)';
    final college = authProvider.studentCollege;
    final year = authProvider.studentYear.isNotEmpty ? authProvider.studentYear : '1st Year';
    final dob = authProvider.studentDob.isNotEmpty ? authProvider.studentDob : '15/05/2004';

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final totalRegs = stateProvider.registrations
        .where((r) =>
            (roll.isNotEmpty && r.rollNumber.toLowerCase() == roll.toLowerCase()) ||
            (cleanPhone.isNotEmpty && r.phoneNumber.replaceAll(RegExp(r'\D'), '') == cleanPhone))
        .length;

    final attendedCount = stateProvider.registrations
        .where((r) =>
            ((roll.isNotEmpty && r.rollNumber.toLowerCase() == roll.toLowerCase()) ||
             (cleanPhone.isNotEmpty && r.phoneNumber.replaceAll(RegExp(r'\D'), '') == cleanPhone)) &&
            r.status == 'Attended')
        .length;

    final pCode = authProvider.participantCode;
    final qrData = jsonEncode({
      'name': name,
      'code': pCode,
    });

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: false,
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
            }
          },
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'Student Profile Pass',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Hero Profile Identity Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Colors.black, Colors.black]
                      : [Colors.white, const Color(0xFFF1F5F9)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Image Avatar with Live Camera & Gallery Upload Badge
                    GestureDetector(
                      onTap: () => _showImagePickerModal(context, authProvider),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: EdgeInsets.all(authProvider.customAvatarUrl.isNotEmpty ? 3 : 10),
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2563EB),
                                width: 2,
                              ),
                            ),
                            child: authProvider.customAvatarUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: UniversalImage(
                                      pathOrUrl: authProvider.customAvatarUrl,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_rounded,
                                    size: 38,
                                    color: Color(0xFF2563EB),
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // User Name below profile picture
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Permanent 10-Digit Participant Code Badge
                    GestureDetector(
                      onTap: () => _copyToClipboard(context, '10-Digit Participant Code', authProvider.participantCode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fingerprint_rounded, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 6),
                            Text(
                              '10-DIGIT CODE: ${authProvider.participantCode}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD97706),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded, size: 12, color: Color(0xFFD97706)),
                          ],
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),

                    // Animated Stat Counters
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAnimatedStatTile(
                          context,
                          label: 'Registered',
                          count: totalRegs,
                          color: const Color(0xFF2563EB),
                          icon: Icons.assignment_turned_in_rounded,
                          onTap: () => _switchViewMode(ProfileViewMode.activity),
                        ),
                        _buildAnimatedStatTile(
                          context,
                          label: 'Attended',
                          count: attendedCount,
                          color: const Color(0xFF059669),
                          icon: Icons.check_circle_rounded,
                          onTap: () => _switchViewMode(ProfileViewMode.activity),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Segmented Mode Navigation Bar (3 Modes with Animated Bouncing Buttons)
            Container(
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.black : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  _buildTabButton(
                    mode: ProfileViewMode.normal,
                    label: 'Pass Info',
                    icon: Icons.badge_outlined,
                  ),
                  _buildTabButton(
                    mode: ProfileViewMode.qrCode,
                    label: 'QR Pass',
                    icon: Icons.qr_code_2_rounded,
                  ),
                  _buildTabButton(
                    mode: ProfileViewMode.activity,
                    label: 'Activity',
                    icon: Icons.analytics_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // View Content with Animated Transition & QR entrance scaling
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildCurrentView(context, isDark, name, roll, email, phone, gender, dept, college, year, dob, qrData, totalRegs, attendedCount),
            ),
            const SizedBox(height: 16),

            // Account Actions Card
            _buildAccountActionsCard(context, isDark, authProvider),
            const SizedBox(height: 16),

            // Theme Preferences Card
            _buildThemeCard(context, isDark, stateProvider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required ProfileViewMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: AnimatedBounceButton(
        onTap: () => _switchViewMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStatTile(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Flexible(
      child: AnimatedBounceButton(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: count.toDouble()),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutExpo,
                builder: (context, value, child) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView(
    BuildContext context,
    bool isDark,
    String name,
    String roll,
    String email,
    String phone,
    String gender,
    String dept,
    String college,
    String year,
    String dob,
    String qrData,
    int totalRegs,
    int attendedCount,
  ) {
    switch (_viewMode) {
      case ProfileViewMode.normal:
        return _buildNormalProfileView(context, isDark, name, roll, email, phone, gender, dept, college, year, dob);
      case ProfileViewMode.qrCode:
        return ScaleTransition(
          scale: _qrScaleAnimation,
          child: _buildQrPassView(context, isDark, name, roll, email, phone, gender, dept, year, dob, qrData),
        );
      case ProfileViewMode.activity:
        return _buildActivityView(context, isDark, totalRegs, attendedCount);
    }
  }

  // --- TAB 1: PASS INFO DETAILS VIEW ---
  Widget _buildNormalProfileView(
    BuildContext context,
    bool isDark,
    String name,
    String roll,
    String email,
    String phone,
    String gender,
    String dept,
    String college,
    String year,
    String dob,
  ) {
    return Container(
      key: const ValueKey('normal_view'),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_reg_rounded, size: 20, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Campus Registration Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Official verified campus information (Tap to copy details):',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          _buildCopyableDetailTile(context, isDark, 'College / University', college, Icons.school_rounded),
          _buildCopyableDetailTile(context, isDark, 'Roll Number / ID', roll, Icons.badge_rounded),
          _buildCopyableDetailTile(context, isDark, 'Verified Email', email, Icons.mark_email_read_rounded),
          _buildCopyableDetailTile(context, isDark, 'Mobile Phone (10 digits)', phone, Icons.phone_android_rounded),
          _buildCopyableDetailTile(context, isDark, 'Branch / Department', dept, Icons.account_balance_rounded),
          _buildCopyableDetailTile(context, isDark, 'Year of Study', year, Icons.calendar_month_rounded),
          _buildCopyableDetailTile(context, isDark, 'Gender', gender, Icons.person_pin_rounded),
          _buildCopyableDetailTile(context, isDark, 'Date of Birth (DOB)', dob, Icons.cake_rounded),
        ],
      ),
    );
  }

  Widget _buildCopyableDetailTile(BuildContext context, bool isDark, String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        title: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF94A3B8)),
          tooltip: 'Copy $label',
          onPressed: () => _copyToClipboard(context, label, value),
        ),
      ),
    );
  }

  // --- TAB 2: DIGITAL QR ENTRY PASS VIEW ---
  Widget _buildQrPassView(
    BuildContext context,
    bool isDark,
    String name,
    String roll,
    String email,
    String phone,
    String gender,
    String dept,
    String year,
    String dob,
    String qrData,
  ) {
    return Container(
      key: const ValueKey('qr_view'),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pass Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', width: 28, height: 28, fit: BoxFit.contain),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'N EVENTS DIGITAL CAMPUS PASS',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                    Text(
                      'Official Entry Pass • Tap QR to Enlarge',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Scannable Vector QR Code Matrix with Scanning Animation & Stack Overlay
                GestureDetector(
                  onTap: () => _showFullscreenQrModal(context, qrData, name, roll),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 210.0,
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
                      ),
                      // GPU-Safe Stack Logo Overlay
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
                        child: Image.asset('assets/images/logo.png', width: 30, height: 30),
                      ),
                      // Laser scan line overlay effect
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 20 + (_scanAnimation.value * 190),
                            child: Container(
                              width: 210,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // QR Pass Details Summary Table
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildPassDetailRow('STUDENT NAME', name),
                      const Divider(height: 12),
                      _buildPassDetailRow('USER ID / ROLL', roll),
                      const Divider(height: 12),
                      _buildPassDetailRow('DEPARTMENT', dept),
                      const Divider(height: 12),
                      _buildPassDetailRow('YEAR & GENDER', '$year • $gender'),
                      const Divider(height: 12),
                      _buildPassDetailRow('QR SCANNABLE PAYLOAD', 'Encodes User ID & Name Only'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: AnimatedBounceButton(
                        onTap: () => _showFullscreenQrModal(context, qrData, name, roll),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2563EB)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fullscreen_rounded, size: 16, color: Color(0xFF2563EB)),
                              SizedBox(width: 6),
                              Text(
                                'Enlarge QR Pass',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedBounceButton(
                        onTap: () => _copyToClipboard(context, 'QR Data Payload', qrData),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Copy Data',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
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
  }

  // --- TAB 3: ACTIVITY & CERTIFICATES VIEW ---
  Widget _buildActivityView(BuildContext context, bool isDark, int totalRegs, int attendedCount) {
    final double attendanceRate = totalRegs > 0 ? (attendedCount / totalRegs * 100) : 0.0;

    return Container(
      key: const ValueKey('activity_view'),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Text(
                'Campus Participation Statistics',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Attendance Rate Indicator Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Attendance Rate',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${attendanceRate.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalRegs > 0 ? (attendedCount / totalRegs) : 0,
                    minHeight: 10,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$attendedCount out of $totalRegs registered campus events verified',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Action Cards to Tickets & Certificates
          Row(
            children: [
              Expanded(
                child: AnimatedBounceButton(
                  onTap: () => context.go('/my-tickets'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_rounded, color: Color(0xFF2563EB), size: 22),
                        SizedBox(width: 8),
                        Text('My Event Tickets & Passes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }

  // --- ACCOUNT ACTIONS CARD ---
  Widget _buildAccountActionsCard(BuildContext context, bool isDark, AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.06),
            blurRadius: 12,
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
              children: [
                const Icon(Icons.manage_accounts_rounded, color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Account Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 6),

            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.switch_account_rounded, color: Color(0xFF2563EB), size: 18),
              ),
              title: Text(
                'Switch Account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              subtitle: const Text(
                'Sign in with another student profile',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
              onTap: () {
                authProvider.logout();
                context.go('/auth');
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Divider(height: 1),
            ),

            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
              ),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
              subtitle: const Text(
                'End current student session',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFEF4444)),
              onTap: () {
                authProvider.logout();
                context.go('/auth');
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- THEME SELECTOR CARD ---
  Widget _buildThemeCard(BuildContext context, bool isDark, AppStateProvider stateProvider) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 340;
            return Flex(
              direction: isNarrow ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDark ? Colors.amber : const Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Interface Theme',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (isNarrow) const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text('Light', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('Dark', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('Auto', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {stateProvider.themeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      stateProvider.setThemeMode(newSelection.first);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
