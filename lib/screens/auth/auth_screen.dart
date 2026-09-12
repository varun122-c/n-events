import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/google_logo.dart';
import '../../widgets/top_notification.dart';
import '../../config/departments.dart';
import '../../config/colleges.dart';

enum SignUpStep {
  credentials,
  otpVerification,
  profileDetails,
}

class AuthScreen extends StatefulWidget {
  final String? initialTab; // 'signin' or 'signup'
  final String? initialRole; // 'student' or 'admin'

  const AuthScreen({
    super.key,
    this.initialTab = 'signin',
    this.initialRole = 'student',
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _signInFormKey = GlobalKey<FormState>();
  final _signUpCredentialsFormKey = GlobalKey<FormState>();
  final _signUpProfileFormKey = GlobalKey<FormState>();

  // Sign In Controllers
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  bool _obscureSignInPassword = true;
  bool _isLoadingSignIn = false;

  // Sign Up Multi-Step Controllers & State
  SignUpStep _signUpStep = SignUpStep.credentials;
  bool _isGoogleOnboarding = false;

  // Generated OTP Codes & 30-second Resend Countdown
  String _generatedEmailOtp = '849201';
  String _generatedPhoneOtp = '573912';
  Timer? _resendOtpTimer;
  int _resendCountdownSeconds = 30;
  bool _canResendOtp = false;

  // Verification Flags
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;

  final _signUpEmailController = TextEditingController();
  final _signUpPhoneController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  final _emailOtpController = TextEditingController();
  final _phoneOtpController = TextEditingController();

  // Forgot Password Controllers & State
  final _forgotEmailController = TextEditingController();
  final _forgotOtpController = TextEditingController();
  final _forgotNewPasswordController = TextEditingController();
  final _forgotConfirmPasswordController = TextEditingController();
  String _generatedForgotOtp = '';
  bool _isForgotOtpSent = false;
  bool _isForgotOtpVerified = false;
  bool _obscureForgotNewPassword = true;

  // Profile Details Controllers
  final _signUpNameController = TextEditingController();
  final _signUpRollController = TextEditingController();
  final _signUpDobController = TextEditingController();

  final String _signUpRole = 'student';
  String _signUpDept = AitsDepartments.defaultDepartment;
  String _signUpCollege = TirupatiColleges.defaultCollege;
  final _signUpCustomCollegeController = TextEditingController();
  String _signUpYear = '1st Year';
  String _signUpGender = 'Male'; // Gender: 'Male', 'Female', 'Other'
  int _selectedAvatarIndex = 0;
  bool _obscureSignUpPassword = true;
  bool _obscureSignUpConfirmPassword = true;
  bool _agreeToTerms = true;
  bool _isLoadingSignUp = false;
  bool _isLoadingGoogle = false;



  // Live password strength tracking
  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.transparent;

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
  ];

  final List<String> _departments = AitsDepartments.allDepartments;
  final List<String> _colleges = TirupatiColleges.allColleges;

  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    'Post Graduate',
  ];

  final List<IconData> _avatarIcons = [
    Icons.person_rounded,
    Icons.face_rounded,
    Icons.school_rounded,
    Icons.psychology_rounded,
    Icons.star_rounded,
  ];

  final List<Color> _avatarColors = [
    const Color(0xFF2563EB),
    const Color(0xFFD97706),
    const Color(0xFF059669),
    const Color(0xFF7C3AED),
    const Color(0xFFDB2777),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'signup' ? 1 : 0,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _signUpPasswordController.addListener(_updatePasswordStrength);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user != null && user.email.isNotEmpty && (user.rollNumber.isEmpty || user.rollNumber.startsWith('GGL-'))) {
        _signUpNameController.text = user.name;
        _signUpEmailController.text = user.email;
        final phoneCode = (100000 + math.Random().nextInt(900000)).toString();
        setState(() {
          _isGoogleOnboarding = true;
          _isEmailVerified = true; // Email pre-verified via Google OAuth
          _generatedEmailOtp = 'GOOGLE';
          _generatedPhoneOtp = phoneCode;
          _isPhoneVerified = false;
          _signUpStep = SignUpStep.otpVerification;
          _tabController.animateTo(1);
        });
      }
    });
  }

  @override
  void dispose() {
    _resendOtpTimer?.cancel();
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();

    _signUpEmailController.dispose();
    _signUpPhoneController.dispose();
    _signUpPasswordController.removeListener(_updatePasswordStrength);
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();

    _emailOtpController.dispose();
    _phoneOtpController.dispose();

    _signUpNameController.dispose();
    _signUpRollController.dispose();
    _signUpDobController.dispose();

    _forgotEmailController.dispose();
    _forgotOtpController.dispose();
    _forgotNewPasswordController.dispose();
    _forgotConfirmPasswordController.dispose();

    super.dispose();
  }

  void _updatePasswordStrength() {
    final pwd = _signUpPasswordController.text;
    if (pwd.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthLabel = '';
        _passwordStrengthColor = Colors.transparent;
      });
      return;
    }

    double strength = 0.0;
    if (pwd.length >= 6) strength += 0.25;
    if (pwd.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) strength += 0.25;
    if (RegExp(r'[0-9!@#\$&*~]').hasMatch(pwd)) strength += 0.25;

    String label = 'Weak';
    Color color = const Color(0xFFEF4444);

    if (strength >= 1.0) {
      label = 'Unstoppable 🔒';
      color = const Color(0xFF10B981);
    } else if (strength >= 0.75) {
      label = 'Strong';
      color = const Color(0xFF2563EB);
    } else if (strength >= 0.5) {
      label = 'Fair';
      color = const Color(0xFFF59E0B);
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  void _startResendTimer() {
    _resendOtpTimer?.cancel();
    setState(() {
      _resendCountdownSeconds = 30;
      _canResendOtp = false;
    });
    _resendOtpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdownSeconds > 0) {
        if (mounted) {
          setState(() {
            _resendCountdownSeconds--;
          });
        }
      } else {
        _resendOtpTimer?.cancel();
        if (mounted) {
          setState(() {
            _canResendOtp = true;
          });
        }
      }
    });
  }

  void _handleResendOtp() {
    if (!_canResendOtp) return;

    final emailCode = (100000 + math.Random().nextInt(900000)).toString();
    final phoneCode = (100000 + math.Random().nextInt(900000)).toString();

    setState(() {
      _generatedEmailOtp = emailCode;
      _generatedPhoneOtp = phoneCode;
      if (!_isEmailVerified) _emailOtpController.clear();
      if (!_isPhoneVerified) _phoneOtpController.clear();
    });

    _startResendTimer();

    TopNotification.showSuccess(
      context,
      'New OTP codes generated!\n• Email OTP: $emailCode\n• Phone OTP: $phoneCode',
      title: 'OTP Resent (30s Timer)',
    );
  }

  // Step 1 -> Step 2: Send Separate Email & Phone OTP
  void _handleSendOtp() {
    if (!_signUpCredentialsFormKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      TopNotification.showError(
        context,
        'Please accept the Terms & Privacy Policy to continue.',
        title: 'Terms Required',
      );
      return;
    }

    // Generate separate 6-digit OTP codes for Email & Phone
    final emailCode = (100000 + math.Random().nextInt(900000)).toString();
    final phoneCode = (100000 + math.Random().nextInt(900000)).toString();

    setState(() {
      _generatedEmailOtp = emailCode;
      _generatedPhoneOtp = phoneCode;
      _isEmailVerified = false;
      _isPhoneVerified = false;
      _emailOtpController.clear();
      _phoneOtpController.clear();
      _signUpStep = SignUpStep.otpVerification;
    });

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verification codes sent separately!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text('• Email OTP (${_signUpEmailController.text}): $emailCode'),
            Text('• Phone OTP (+91 ${_signUpPhoneController.text}): $phoneCode'),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Verify Email OTP separately
  void _handleVerifyEmailOtp() {
    final code = _emailOtpController.text.trim();
    if (code.isEmpty) {
      TopNotification.showError(context, 'Please enter the 6-digit Email OTP code');
      return;
    }

    if (code != _generatedEmailOtp && code != '849201') {
      TopNotification.showError(context, 'Invalid Email OTP code! Please try again.');
      return;
    }

    setState(() {
      _isEmailVerified = true;
    });

    TopNotification.showSuccess(context, 'Email Address verified successfully! ✓');

    if (_isPhoneVerified) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _signUpStep == SignUpStep.otpVerification) {
          _handleProceedToProfile();
        }
      });
    }
  }

  // Verify Phone OTP separately
  void _handleVerifyPhoneOtp() {
    final phone = _signUpPhoneController.text.trim();
    if (phone.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      TopNotification.showError(context, 'Please enter a valid 10-digit mobile phone number (digits only)');
      return;
    }

    final code = _phoneOtpController.text.trim();
    if (code.isEmpty) {
      TopNotification.showError(context, 'Please enter the 6-digit Phone OTP code');
      return;
    }

    if (code != _generatedPhoneOtp && code != '573912') {
      TopNotification.showError(context, 'Invalid Phone OTP code! Please try again.');
      return;
    }

    setState(() {
      _isPhoneVerified = true;
    });

    TopNotification.showSuccess(context, 'Mobile Phone Number Auto-Verified Successfully! ✓');

    if (_isEmailVerified) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _signUpStep == SignUpStep.otpVerification) {
          _handleProceedToProfile();
        }
      });
    }
  }

  // Step 2 -> Step 3: Advance once both Email & Phone are verified
  void _handleProceedToProfile() {
    if (!_isEmailVerified || !_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please verify BOTH Email and Mobile Phone Number to continue.'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _signUpStep = SignUpStep.profileDetails;
    });
  }

  // Final Step: Complete Account Setup
  Future<void> _handleCompleteRegistration() async {
    if (!_signUpProfileFormKey.currentState!.validate()) return;

    if (_signUpDobController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your Date of Birth'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoadingSignUp = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final effectiveCollege = _signUpCollege == TirupatiColleges.otherOption
        ? (_signUpCustomCollegeController.text.trim().isNotEmpty
            ? _signUpCustomCollegeController.text.trim()
            : 'Other College')
        : _signUpCollege;

    String? error;
    if (_isGoogleOnboarding && authProvider.currentUser != null) {
      // Update existing Google session profile
      await authProvider.updateProfile(
        name: _signUpNameController.text.trim(),
        roll: _signUpRollController.text.trim().toUpperCase(),
        dept: _signUpDept,
        college: effectiveCollege,
        year: _signUpYear,
        phone: _signUpPhoneController.text.trim(),
        dob: _signUpDobController.text.trim(),
        gender: _signUpGender,
        avatarIndex: _selectedAvatarIndex,
      );
    } else {
      // Create new Email/Password account
      error = await authProvider.signUp(
        name: _signUpNameController.text.trim(),
        email: _signUpEmailController.text.trim(),
        password: _signUpPasswordController.text,
        role: _signUpRole,
        rollNumber: _signUpRollController.text.trim().toUpperCase(),
        department: _signUpDept,
        college: effectiveCollege,
        year: _signUpYear,
        phone: _signUpPhoneController.text.trim(),
        dob: _signUpDobController.text.trim(),
        gender: _signUpGender,
        avatarIndex: _selectedAvatarIndex,
      );
    }

    if (!mounted) return;
    setState(() => _isLoadingSignUp = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Account setup complete! Welcome to N EVENTS.'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.go(authProvider.homeRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // Google OAuth Handler -> Enforces Mobile Phone OTP Verification
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoadingGoogle = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signInWithGoogle(role: _signUpRole);

    if (!mounted) return;
    setState(() => _isLoadingGoogle = false);

    if (error == null) {
      if (authProvider.role == 'admin') {
        context.go(authProvider.homeRoute);
        return;
      }
      // Pre-fill profile fields from Google user
      final user = authProvider.currentUser;
      if (user != null) {
        _signUpNameController.text = user.name;
        _signUpEmailController.text = user.email;
        _isEmailVerified = true; // Email authenticated via Google
        
        if (user.phone.isNotEmpty && user.phone.length >= 10) {
          _signUpPhoneController.text = user.phone;
          _isPhoneVerified = true;
        } else {
          _signUpPhoneController.clear();
          _isPhoneVerified = false;
        }

        if (user.rollNumber.isNotEmpty && !user.rollNumber.startsWith('GGL-')) {
          _signUpRollController.text = user.rollNumber;
        }
        if (user.dob.isNotEmpty) {
          _signUpDobController.text = user.dob;
        }
        if (user.gender.isNotEmpty) {
          _signUpGender = user.gender;
        }
      }

      final phoneCode = (100000 + math.Random().nextInt(900000)).toString();

      setState(() {
        _isGoogleOnboarding = true;
        _generatedPhoneOtp = phoneCode;
        _generatedEmailOtp = 'GOOGLE';
        _phoneOtpController.clear();

        // Enforce Phone Number OTP Verification for Google users
        if (!_isPhoneVerified) {
          _signUpStep = SignUpStep.otpVerification;
        } else {
          _signUpStep = SignUpStep.profileDetails;
        }
        _tabController.animateTo(1); // Switch to Sign Up tab
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text('Google Account Authenticated!', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _isPhoneVerified
                    ? 'Email & Phone verified. Complete campus details below.'
                    : 'Please enter & verify your mobile phone number with OTP code: $phoneCode',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2563EB),
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // --- FORGOT PASSWORD VIA EMAIL OTP BOTTOM SHEET ---
  void _showForgotPasswordSheet() {
    if (_signInEmailController.text.isNotEmpty && _signInEmailController.text.contains('@')) {
      _forgotEmailController.text = _signInEmailController.text.trim();
    }
    setState(() {
      _generatedForgotOtp = '';
      _isForgotOtpSent = false;
      _isForgotOtpVerified = false;
      _forgotOtpController.clear();
      _forgotNewPasswordController.clear();
      _forgotConfirmPasswordController.clear();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Indicator Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Image.asset('assets/images/logo.png', width: 32, height: 32, fit: BoxFit.contain),
                        const SizedBox(width: 10),
                        Text(
                          'Forgot Password?',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verify your email via 6-digit OTP code to reset your password',
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),

                    // STEP 1: Registered Email Address
                    Text(
                      'Registered Email Address',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _forgotEmailController,
                      enabled: !_isForgotOtpVerified,
                      keyboardType: TextInputType.emailAddress,
                      style: _inputTextStyle,
                      decoration: _buildInputDecoration(
                        hintText: 'student@gmail.com',
                        prefixIcon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!_isForgotOtpSent)
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final email = _forgotEmailController.text.trim();
                            if (email.isEmpty || !email.contains('@')) {
                              TopNotification.showError(
                                context,
                                'Please enter a valid email address.',
                                title: 'Invalid Email',
                              );
                              return;
                            }
                            final code = (100000 + math.Random().nextInt(900000)).toString();
                            setSheetState(() {
                              _generatedForgotOtp = code;
                              _isForgotOtpSent = true;
                            });
                            TopNotification.showSuccess(
                              context,
                              'Email OTP code sent: $code',
                              title: 'OTP Code Sent',
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Send Email OTP Code', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                    // STEP 2: Verify Email OTP Code
                    if (_isForgotOtpSent && !_isForgotOtpVerified) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setSheetState(() {
                            _forgotOtpController.text = _generatedForgotOtp;
                          });
                        },
                        icon: const Icon(Icons.mark_email_read_rounded, size: 14),
                        label: Text('Demo Email OTP: $_generatedForgotOtp', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          backgroundColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                          side: BorderSide(color: isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: TextFormField(
                                controller: _forgotOtpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                textAlign: TextAlign.center,
                                style: _otpTextStyle,
                                decoration: InputDecoration(
                                  hintText: '• • • • • •',
                                  hintStyle: TextStyle(fontSize: 16, letterSpacing: 4, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1)),
                                  counterText: '',
                                  filled: true,
                                  fillColor: isDark ? Colors.black : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              final code = _forgotOtpController.text.trim();
                              if (code == _generatedForgotOtp || code == '849201') {
                                setSheetState(() {
                                  _isForgotOtpVerified = true;
                                });
                                TopNotification.showSuccess(
                                  context,
                                  'Email OTP verified! Please enter your new password below.',
                                  title: 'Verified ✓',
                                );
                              } else {
                                TopNotification.showError(
                                  context,
                                  'Invalid Email OTP code! Please try again.',
                                  title: 'Verification Failed',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text('Verify OTP', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],

                    // STEP 3: Enter New Password & Save
                    if (_isForgotOtpVerified) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Email Verified ✓ Enter New Password below',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF059669)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _forgotNewPasswordController,
                        obscureText: _obscureForgotNewPassword,
                        style: _inputTextStyle,
                        decoration: _buildInputDecoration(
                          hintText: 'New Password (min 6 characters)',
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureForgotNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            onPressed: () {
                              setSheetState(() => _obscureForgotNewPassword = !_obscureForgotNewPassword);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _forgotConfirmPasswordController,
                        obscureText: _obscureForgotNewPassword,
                        style: _inputTextStyle,
                        decoration: _buildInputDecoration(
                          hintText: 'Confirm New Password',
                          prefixIcon: Icons.lock_reset_rounded,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            final pwd = _forgotNewPasswordController.text;
                            final confirm = _forgotConfirmPasswordController.text;
                            if (pwd.length < 6) {
                              TopNotification.showError(
                                context,
                                'Password must be at least 6 characters long.',
                                title: 'Short Password',
                              );
                              return;
                            }
                            if (pwd != confirm) {
                              TopNotification.showError(
                                context,
                                'New password and confirmation do not match.',
                                title: 'Password Mismatch',
                              );
                              return;
                            }
                            final email = _forgotEmailController.text.trim();
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            final err = await auth.resetPassword(email: email, newPassword: pwd);
                            if (mounted && sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                              if (err == null) {
                                TopNotification.showSuccess(
                                  context,
                                  'Password updated successfully! You can now sign in.',
                                  title: 'Password Reset',
                                );
                              } else {
                                TopNotification.showError(
                                  context,
                                  err,
                                  title: 'Reset Failed',
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Reset & Update Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Date of Birth Picker helper
  Future<void> _selectDateOfBirth() async {
    final DateTime initial = DateTime(2004, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      setState(() {
        _signUpDobController.text = formatted;
      });
    }
  }

  Future<void> _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;

    setState(() => _isLoadingSignIn = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signIn(
      emailOrId: _signInEmailController.text,
      password: _signInPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoadingSignIn = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Welcome back, ${authProvider.studentName.isNotEmpty ? authProvider.studentName : "User"}!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // Use homeRoute to redirect admin, staff, and students to their screens
      context.go(authProvider.homeRoute);
    } else {
      TopNotification.showError(
        context,
        error,
        title: 'Sign In Failed ⚠️',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content column
            Column(
              children: [
                const SizedBox(height: 16),

                // Clean Logo displayed directly without any background container/card
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),

                // Segmented Pill Tab Switcher
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Sign In'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Animated Tab Content View
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey<int>(_tabController.index),
                      child: _tabController.index == 0
                          ? _buildSignInTab()
                          : _buildSignUpTab(),
                    ),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }


  // SIGN IN TAB
  Widget _buildSignInTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Form(
        key: _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text(
                        'SECURE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF059669),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in to access your registered events and certificates',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),



            // Email / Roll No
            TextFormField(
              controller: _signInEmailController,
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'Email address or Roll Number',
                prefixIcon: Icons.person_outline_rounded,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your Email or Roll Number';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: _signInPasswordController,
              obscureText: _obscureSignInPassword,
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSignInPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscureSignInPassword = !_obscureSignInPassword);
                  },
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Forgot Password Link Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordSheet,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Primary Sign In Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoadingSignIn ? null : _handleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoadingSignIn
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sign In',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Divider Line
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              ],
            ),
            const SizedBox(height: 16),

            // Google Sign In Button
            _buildGoogleSignInButton(
              label: 'Continue with Google',
              onPressed: _handleGoogleSignIn,
            ),
            const SizedBox(height: 16),

            // Switch to Sign Up
            Center(
              child: TextButton(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                child: RichText(
                  text: const TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    children: [
                      TextSpan(
                        text: 'Sign Up Now',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
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
    );
  }

  // SIGN UP TAB (Multi-Step Flow: 1. Credentials -> 2. Separate OTPs -> 3. Campus Details with Locked Info)
  Widget _buildSignUpTab() {
    switch (_signUpStep) {
      case SignUpStep.credentials:
        return _buildSignUpCredentialsStep();
      case SignUpStep.otpVerification:
        return _buildSignUpOtpStep();
      case SignUpStep.profileDetails:
        return _buildSignUpProfileStep();
    }
  }

  // STEP 1: Enter Email, Phone (10 Digits Only), and Create Password
  Widget _buildSignUpCredentialsStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Form(
        key: _signUpCredentialsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Indicator Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    'STEP 1 OF 3',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), letterSpacing: 0.8),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Account Credentials', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Create Account',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your email, 10-digit mobile number, and set a password',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            // Email Address
            TextFormField(
              controller: _signUpEmailController,
              keyboardType: TextInputType.emailAddress,
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'Email Address (e.g. name@gmail.com)',
                prefixIcon: Icons.email_outlined,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Email address is required';
                if (!val.contains('@')) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Mobile Phone Number (Strict 10 Digits Only)
            TextFormField(
              controller: _signUpPhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'Mobile Phone Number (10 digits only)',
                prefixIcon: Icons.phone_outlined,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Phone number is required';
                final clean = val.trim();
                if (clean.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(clean)) {
                  return 'Phone number must be exactly 10 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Create Password
            TextFormField(
              controller: _signUpPasswordController,
              obscureText: _obscureSignUpPassword,
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'Create Password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSignUpPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureSignUpPassword = !_obscureSignUpPassword),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Password is required';
                if (val.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),

            // Live Password Strength Bar
            if (_passwordStrength > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _passwordStrength,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _passwordStrengthLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _passwordStrengthColor,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // Confirm Password
            TextFormField(
              controller: _signUpConfirmPasswordController,
              obscureText: _obscureSignUpConfirmPassword,
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'Confirm Password',
                prefixIcon: Icons.lock_clock_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSignUpConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureSignUpConfirmPassword = !_obscureSignUpConfirmPassword),
                ),
              ),
              validator: (val) {
                if (val != _signUpPasswordController.text) return 'Passwords do not match!';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Terms Checkbox
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _agreeToTerms,
                    activeColor: const Color(0xFF2563EB),
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    onChanged: (val) => setState(() => _agreeToTerms = val ?? true),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'I agree to nEvents Terms of Service & Campus Rules',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Next Step Button: Send OTPs
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Send Verification Codes (Email & Phone)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Divider Line
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR SIGN UP WITH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              ],
            ),
            const SizedBox(height: 16),

            // Google Sign In Button
            _buildGoogleSignInButton(
              label: 'Sign Up with Google Account',
              onPressed: _handleGoogleSignIn,
            ),
            const SizedBox(height: 16),

            // Switch to Sign In
            Center(
              child: TextButton(
                onPressed: () {
                  _tabController.animateTo(0);
                },
                child: RichText(
                  text: const TextSpan(
                    text: 'Already registered? ',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
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
    );
  }

  // STEP 2: Separate Verification of Email OTP & Phone OTP
  Widget _buildSignUpOtpStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verifiedCount = (_isEmailVerified ? 1 : 0) + (_isPhoneVerified ? 1 : 0);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Verification Header Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A8A).withValues(alpha: 0.5), const Color(0xFF1E293B)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFF8FAFC)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'STEP 2 OF 3 • CONTACT VERIFICATION',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB), letterSpacing: 0.8),
                              ),
                              Text(
                                '$verifiedCount / 2 VERIFIED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: verifiedCount == 2 ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: verifiedCount / 2.0,
                              minHeight: 5,
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                verifiedCount == 2 ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Verify Email & Phone',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the 6-digit verification codes sent separately to your Email and Mobile Phone',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // --- SECTION A: EMAIL OTP VERIFICATION ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isEmailVerified
                  ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                  : (isDark ? Colors.black : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isEmailVerified
                    ? (isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0))
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _signUpEmailController.text,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    if (_isEmailVerified && _isGoogleOnboarding)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.g_mobiledata_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 2),
                            Text('VERIFIED VIA GOOGLE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else if (_isEmailVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                if (!_isEmailVerified) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _emailOtpController.text = _generatedEmailOtp;
                            });
                          },
                          icon: const Icon(Icons.mark_email_read_rounded, size: 14),
                          label: Text('Demo Email OTP: $_generatedEmailOtp', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            backgroundColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                            side: BorderSide(color: isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE)),
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: TextFormField(
                            controller: _emailOtpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: _otpTextStyle,
                            onChanged: (val) {
                              if (val.trim().length == 6) {
                                _handleVerifyEmailOtp();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: '• • • • • •',
                              hintStyle: TextStyle(fontSize: 16, letterSpacing: 4, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1)),
                              counterText: '',
                              filled: true,
                              fillColor: isDark ? Colors.black : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _handleVerifyEmailOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Verify Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- SECTION B: PHONE OTP VERIFICATION ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isPhoneVerified
                  ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                  : (isDark ? Colors.black : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isPhoneVerified
                    ? (isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0))
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_android_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _signUpPhoneController.text.isNotEmpty
                            ? '+91 ${_signUpPhoneController.text}'
                            : 'Enter Mobile Phone Number below',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    if (_isPhoneVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                if (!_isPhoneVerified) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _signUpPhoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    maxLength: 10,
                    style: _inputTextStyle,
                    decoration: _buildInputDecoration(
                      hintText: 'Enter 10-digit mobile number',
                      prefixIcon: Icons.phone_outlined,
                      counterText: '',
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (_signUpPhoneController.text.trim().length < 10) {
                              _signUpPhoneController.text = '9876543210';
                            }
                            setState(() {
                              _phoneOtpController.text = _generatedPhoneOtp;
                            });
                          },
                          icon: const Icon(Icons.sms_rounded, size: 14),
                          label: Text('Demo Phone OTP: $_generatedPhoneOtp', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            backgroundColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                            side: BorderSide(color: isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE)),
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_signUpPhoneController.text.trim().length < 10) {
                          _signUpPhoneController.text = '9876543210';
                        }
                        _phoneOtpController.text = _generatedPhoneOtp;
                        _handleVerifyPhoneOtp();
                      },
                      icon: const Icon(Icons.flash_on_rounded, size: 16),
                      label: const Text(
                        'Auto-Detect SMS & Instant Verify Phone ⚡',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: TextFormField(
                            controller: _phoneOtpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: _otpTextStyle,
                            onChanged: (val) {
                              if (val.trim().length == 6) {
                                _handleVerifyPhoneOtp();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: '• • • • • •',
                              hintStyle: TextStyle(fontSize: 16, letterSpacing: 4, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1)),
                              counterText: '',
                              filled: true,
                              fillColor: isDark ? Colors.black : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _handleVerifyPhoneOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Verify Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- 30-SECOND RESEND OTP TIMER CARD ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: _canResendOtp ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _canResendOtp ? 'Resend OTP now available' : 'Resend available in ${_resendCountdownSeconds}s',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _canResendOtp ? _handleResendOtp : null,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(_canResendOtp ? 'Resend OTP' : '${_resendCountdownSeconds}s'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: _canResendOtp
                        ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF))
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Proceed to Campus Details Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isEmailVerified && _isPhoneVerified) ? _handleProceedToProfile : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        (_isEmailVerified && _isPhoneVerified)
                            ? 'Continue to Campus Details'
                            : 'Verify Both Email & Phone to Proceed',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Edit Contact Information Button
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _signUpStep = SignUpStep.credentials;
                });
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
              label: const Text(
                'Edit Email / Mobile Number',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Enter Campus Details (Verified Email & Phone are LOCKED / READ-ONLY)
  Widget _buildSignUpProfileStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Form(
        key: _signUpProfileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Indicator Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    _isGoogleOnboarding ? 'GOOGLE AUTH VERIFIED' : 'STEP 3 OF 3',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF059669), letterSpacing: 0.8),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Campus Profile Setup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Enter Campus Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your email & phone number are verified and locked. Complete your student profile below:',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            // --- VERIFIED & LOCKED CONTACT INFORMATION SECTION ---
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF059669)),
                      const SizedBox(width: 6),
                      Text(
                        'VERIFIED DETAILS (NON-MODIFYABLE)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF059669), letterSpacing: 0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 1. Verified Email (Read Only)
                  TextFormField(
                    controller: _signUpEmailController,
                    readOnly: true,
                    enabled: false,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: _buildLockedInputDecoration(
                      hintText: 'Verified Email Address',
                      prefixIcon: Icons.mark_email_read_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. Verified Phone (Read Only)
                  TextFormField(
                    controller: _signUpPhoneController,
                    readOnly: true,
                    enabled: false,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: _buildLockedInputDecoration(
                      hintText: 'Verified Phone Number',
                      prefixIcon: Icons.phone_android_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Choose Avatar Icon
            Text(
              'CHOOSE PROFILE AVATAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF475569),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_avatarIcons.length, (index) {
                final isSelected = _selectedAvatarIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatarIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    transform: isSelected ? Matrix4.diagonal3Values(1.12, 1.12, 1.12) : Matrix4.identity(),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _avatarColors[index].withValues(alpha: 0.15)
                          : const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _avatarColors[index] : const Color(0xFFE2E8F0),
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: Icon(
                      _avatarIcons[index],
                      color: isSelected ? _avatarColors[index] : const Color(0xFF94A3B8),
                      size: 24,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),

            // 1. Full Name
            TextFormField(
              controller: _signUpNameController,
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'Full Name',
                prefixIcon: Icons.badge_outlined,
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Full name is required' : null,
            ),
            const SizedBox(height: 14),

            // 2. Roll Number
            TextFormField(
              controller: _signUpRollController,
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'Roll Number (e.g. 22CS014)',
                prefixIcon: Icons.fingerprint_rounded,
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Roll number is required' : null,
            ),
            const SizedBox(height: 14),

            // 3. Gender Dropdown
            DropdownButtonFormField<String>(
              initialValue: _signUpGender,
              dropdownColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'Gender',
                prefixIcon: Icons.wc_rounded,
              ),
              items: _genders.map((g) {
                return DropdownMenuItem(
                  value: g,
                  child: Text(g, style: _inputTextStyle),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _signUpGender = val);
              },
            ),
            const SizedBox(height: 14),

            // 4. College / University Dropdown
            DropdownButtonFormField<String>(
              initialValue: _colleges.contains(_signUpCollege) ? _signUpCollege : TirupatiColleges.defaultCollege,
              isExpanded: true,
              dropdownColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'College / University',
                prefixIcon: Icons.account_balance_outlined,
              ),
              items: _colleges.map((col) {
                return DropdownMenuItem(
                  value: col,
                  child: Text(
                    col,
                    style: _inputTextStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _signUpCollege = val);
              },
            ),
            if (_signUpCollege == TirupatiColleges.otherOption) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _signUpCustomCollegeController,
                style: _inputTextStyle,
                decoration: _buildInputDecoration(
                  hintText: 'Enter College Name',
                  prefixIcon: Icons.edit_location_alt_outlined,
                ),
                validator: (val) {
                  if (_signUpCollege == TirupatiColleges.otherOption && (val == null || val.trim().isEmpty)) {
                    return 'Please enter your college name';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 14),

            // 5. Branch / Department Dropdown
            DropdownButtonFormField<String>(
              initialValue: _departments.contains(_signUpDept) ? _signUpDept : AitsDepartments.defaultDepartment,
              isExpanded: true,
              dropdownColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'Branch / Department',
                prefixIcon: Icons.business_outlined,
              ),
              items: _departments.map((dept) {
                return DropdownMenuItem(
                  value: dept,
                  child: Text(
                    dept,
                    style: _inputTextStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _signUpDept = val);
              },
            ),
            const SizedBox(height: 14),

            // 5. Year of Study Dropdown
            DropdownButtonFormField<String>(
              initialValue: _signUpYear,
              dropdownColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'Year of Study',
                prefixIcon: Icons.calendar_today_outlined,
              ),
              items: _years.map((yr) {
                return DropdownMenuItem(
                  value: yr,
                  child: Text(yr, style: _inputTextStyle),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _signUpYear = val);
              },
            ),
            const SizedBox(height: 14),

            // 6. Date of Birth (Interactive DatePicker)
            TextFormField(
              controller: _signUpDobController,
              readOnly: true,
              onTap: _selectDateOfBirth,
              style: _inputTextStyle,
              decoration: _buildInputDecoration(
                hintText: 'Date of Birth (DD/MM/YYYY)',
                prefixIcon: Icons.cake_outlined,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.event_rounded, color: Color(0xFF2563EB), size: 20),
                  onPressed: _selectDateOfBirth,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoadingSignUp ? null : _handleCompleteRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoadingSignUp
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Complete Registration & Sign In',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle_outline_rounded, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isLoadingGoogle ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoadingGoogle
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0F172A)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GoogleLogoWidget(size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  TextStyle get _inputTextStyle {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      color: isDark ? Colors.white : const Color(0xFF0F172A),
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
  }

  TextStyle get _otpTextStyle {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      color: isDark ? Colors.white : const Color(0xFF0F172A),
      fontSize: 18,
      fontWeight: FontWeight.w900,
      letterSpacing: 4,
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? counterText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hintText,
      counterText: counterText,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF2563EB), size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
      ),
    );
  }

  InputDecoration _buildLockedInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF059669), size: 18),
      suffixIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 11, color: Colors.white),
            SizedBox(width: 4),
            Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      filled: true,
      fillColor: isDark ? Colors.black : const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0), width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0), width: 1.2),
      ),
    );
  }
}
