import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../services/supabase_db_service.dart';
import '../config/departments.dart';
import '../config/colleges.dart';

class AuthProvider extends ChangeNotifier {
  /// The one hard-coded admin email address for this app.
  static const String _adminEmail = 'nevents026@gmail.com';

  static bool _isAdminEmail(String email) =>
      email.trim().toLowerCase() == _adminEmail;

  static const String _keyCurrentUserId = 'current_user_id';
  static const String _keyRegisteredUsers = 'registered_users_v2';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyCurrentUserJson = 'current_user_json_v2';

  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  List<UserModel> _registeredUsers = [];

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  List<UserModel> get registeredUsers => List.unmodifiable(_registeredUsers);

  String get role {
    if (_currentUser != null && _isAdminEmail(_currentUser!.email)) {
      return 'admin';
    }
    return _currentUser?.role ?? 'student';
  }
  String get studentName => _currentUser?.name ?? '';
  String get studentRoll => _currentUser?.rollNumber ?? '';
  String get studentDept => _currentUser?.department ?? 'Computer Science and Engineering (CSE)';
  String get studentCollege => _currentUser?.college ?? 'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)';
  String get studentYear => _currentUser?.year ?? '1st Year';
  String get studentPhone => _currentUser?.phone ?? '';
  String get studentDob => _currentUser?.dob ?? '';
  String get studentGender => _currentUser?.gender ?? 'Male';
  String get participantCode => _currentUser?.displayParticipantCode ?? '9876543210';
  String get customAvatarUrl => _currentUser?.customAvatarUrl ?? '';

  // Staff sub-role getters
  String get subRole => _currentUser?.subRole ?? '';
  String get assignedDepartment => _currentUser?.assignedDepartment ?? '';
  List<String> get assignedEventIds => _currentUser?.assignedEventIds ?? [];
  bool get isStaff => (_currentUser?.subRole ?? '').isNotEmpty;

  /// Returns the Go-Router path this user should land on after login
  String get homeRoute {
    if (role == 'admin') return '/admin';
    switch (subRole) {
      case 'organizer':
        return '/staff/organizer';
      case 'coordinator':
        return '/staff/coordinator';
      case 'tech_provider':
        return '/staff/tech';
      case 'scanner':
        return '/staff/scanner';
      default:
        return '/student';
    }
  }

  AuthProvider() {
    _loadFromPrefs();
  }

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    int tries = 0;
    while (!_isInitialized && tries < 20) {
      await Future.delayed(const Duration(milliseconds: 50));
      tries++;
    }
  }

  List<UserModel> _getDefaultAccounts() {
    return [];
  }

  Future<void> _saveCurrentSession(UserModel user) async {
    // Always enforce admin role for the admin email, regardless of what's stored
    final effectiveUser = _isAdminEmail(user.email)
        ? user.copyWith(role: 'admin')
        : user;
    _currentUser = effectiveUser;
    _isLoggedIn = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyCurrentUserId, effectiveUser.id);
      await prefs.setString(_keyCurrentUserJson, json.encode(effectiveUser.toMap()));
    } catch (e) {
      debugPrint('Error saving current session: $e');
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load registered users from local cache
      final usersJson = prefs.getString(_keyRegisteredUsers);
      if (usersJson != null && usersJson.isNotEmpty) {
        try {
          final List<dynamic> list = json.decode(usersJson);
          _registeredUsers = list.map((item) => UserModel.fromMap(item)).toList();
        } catch (_) {
          _registeredUsers = _getDefaultAccounts();
        }
      } else {
        _registeredUsers = _getDefaultAccounts();
        await _saveUsersToPrefs();
      }

      _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final currentUserId = prefs.getString(_keyCurrentUserId);
      final currentUserJson = prefs.getString(_keyCurrentUserJson);

      if (_isLoggedIn) {
        // Try loading from local cache first (fast startup)
        if (currentUserJson != null && currentUserJson.isNotEmpty) {
          try {
            _currentUser = UserModel.fromMap(json.decode(currentUserJson));
          } catch (_) {
            _currentUser = null;
          }
        }

        if (_currentUser == null && currentUserId != null) {
          final matches = _registeredUsers.where((u) => u.id == currentUserId);
          if (matches.isNotEmpty) {
            _currentUser = matches.first;
          }
        }

        if (_currentUser != null && _isAdminEmail(_currentUser!.email)) {
          _currentUser = _currentUser!.copyWith(role: 'admin');
        }

        // If we have a user from cache, try refreshing profile from Supabase in background
        if (_currentUser != null && SupabaseService.isInitialized) {
          _refreshProfileFromSupabase(_currentUser!.id);
        }

        if (_currentUser == null) {
          _isLoggedIn = false;
        }
      } else {
        // Check if Supabase has an active session (e.g. after token refresh)
        if (SupabaseService.isInitialized) {
          final sbUser = SupabaseService.currentUser;
          if (sbUser != null) {
            await _loadProfileFromSupabase(sbUser);
          }
        }
        if (_currentUser == null) {
          _isLoggedIn = false;
        }
      }
    } catch (e) {
      debugPrint('Error loading auth state from prefs: $e');
      _currentUser = null;
      _isLoggedIn = false;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Fetch profile from Supabase and update current user in background.
  Future<void> _refreshProfileFromSupabase(String userId) async {
    try {
      final profile = await SupabaseDbService.fetchProfile(userId);
      if (profile == null) return;
      // Merge email from local cache (profiles table doesn't store email)
      final email = _currentUser?.email ?? SupabaseService.currentUser?.email ?? '';
      // Always enforce admin role for the admin email
      final effectiveRole = _isAdminEmail(email) ? 'admin' : profile.role;
      final merged = profile.copyWith(
        email: email,
        password: _currentUser?.password ?? '',
        role: effectiveRole,
      );
      _currentUser = merged;
      await _saveCurrentSession(merged);
      notifyListeners();
    } catch (e) {
      debugPrint('Background profile refresh error: $e');
    }
  }

  /// Load a full user profile from Supabase auth + profiles table after sign-in.
  Future<void> _loadProfileFromSupabase(User sbUser) async {
    try {
      final email = sbUser.email ?? '';
      final effectiveRole = _isAdminEmail(email) ? 'admin' : 'student';
      final profile = await SupabaseDbService.fetchProfile(sbUser.id);
      if (profile != null) {
        final merged = profile.copyWith(
          email: email,
          password: '',
          // Always enforce admin role for the admin email
          role: _isAdminEmail(email) ? 'admin' : profile.role,
        );
        await _saveCurrentSession(merged);
        _isLoggedIn = true;
      } else {
        // Profile not yet created (e.g. first Google sign-in)
        final metadata = sbUser.userMetadata ?? {};
        final newUser = UserModel(
          id: sbUser.id,
          name: metadata['name'] ?? sbUser.email?.split('@').first ?? 'User',
          email: email,
          password: '',
          role: effectiveRole,
          rollNumber: metadata['roll_number'] ?? '',
          department: metadata['department'] ?? AitsDepartments.defaultDepartment,
          college: metadata['college'] ?? TirupatiColleges.defaultCollege,
          year: metadata['year'] ?? '1st Year',
          phone: metadata['phone'] ?? '',
          dob: metadata['dob'] ?? '',
          gender: metadata['gender'] ?? 'Male',
          avatarIndex: metadata['avatar_index'] ?? 0,
        );
        await SupabaseDbService.upsertProfile(newUser);
        await _saveCurrentSession(newUser);
        _isLoggedIn = true;
      }
    } catch (e) {
      debugPrint('_loadProfileFromSupabase error: $e');
    }
  }

  Future<void> _saveUsersToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _registeredUsers.map((u) => u.toMap()).toList();
    await prefs.setString(_keyRegisteredUsers, json.encode(jsonList));
  }

  Future<void> deleteUserAccount(String userId) async {
    _registeredUsers.removeWhere((u) => 
        u.id == userId || 
        u.email.trim().toLowerCase() == userId.trim().toLowerCase() ||
        (u.rollNumber.isNotEmpty && u.rollNumber.trim().toUpperCase() == userId.trim().toUpperCase()));
    
    if (_currentUser != null && (_currentUser!.id == userId || _currentUser!.email.trim().toLowerCase() == userId.trim().toLowerCase())) {
      _currentUser = null;
      _isLoggedIn = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyIsLoggedIn);
        await prefs.remove(_keyCurrentUserId);
        await prefs.remove(_keyCurrentUserJson);
      } catch (e) {
        debugPrint('Error clearing session on delete: $e');
      }
    }
    await _saveUsersToPrefs();
    notifyListeners();
  }

  Future<void> updateStaffRole({
    required String userId,
    required String subRole,
    required String assignedDepartment,
    required List<String> assignedEventIds,
  }) async {
    final idx = _registeredUsers.indexWhere((u) =>
        u.id == userId ||
        u.email.trim().toLowerCase() == userId.trim().toLowerCase() ||
        (u.rollNumber.isNotEmpty && u.rollNumber.trim().toUpperCase() == userId.trim().toUpperCase()));

    if (idx != -1) {
      _registeredUsers[idx] = _registeredUsers[idx].copyWith(
        subRole: subRole,
        assignedDepartment: assignedDepartment,
        assignedEventIds: assignedEventIds,
      );
      await _saveUsersToPrefs();
    }

    if (_currentUser != null &&
        (_currentUser!.id == userId ||
         _currentUser!.email.trim().toLowerCase() == userId.trim().toLowerCase() ||
         (_currentUser!.rollNumber.isNotEmpty && _currentUser!.rollNumber.trim().toUpperCase() == userId.trim().toUpperCase()))) {
      _currentUser = _currentUser!.copyWith(
        subRole: subRole,
        assignedDepartment: assignedDepartment,
        assignedEventIds: assignedEventIds,
      );
      await _saveCurrentSession(_currentUser!);
    }
    notifyListeners();
  }

  // ─── SIGN UP ─────────────────────────────────────────────────────────────

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    required String rollNumber,
    required String department,
    String college = 'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)',
    required String year,
    required String phone,
    String dob = '',
    String gender = 'Male',
    int avatarIndex = 0,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanRoll = rollNumber.trim().toUpperCase();
    // Force admin role if this is the admin email
    final effectiveRole = _isAdminEmail(cleanEmail) ? 'admin' : role;

    // Try Supabase Auth Sign Up if Supabase is active
    if (SupabaseService.isInitialized) {
      try {
        final response = await SupabaseService.signUp(
          email: cleanEmail,
          password: password,
          userMetadata: {
            'name': name.trim(),
            'role': effectiveRole,
            'roll_number': cleanRoll,
            'department': department,
            'college': college,
            'year': year,
            'phone': phone.trim(),
            'dob': dob,
            'gender': gender,
            'avatar_index': avatarIndex,
          },
        );

        if (response?.user != null) {
          final userId = response!.user!.id;
          final newUser = UserModel(
            id: userId,
            name: name.trim(),
            email: cleanEmail,
            password: password,
            role: effectiveRole,
            rollNumber: cleanRoll,
            department: department,
            college: college,
            year: year,
            phone: phone.trim(),
            dob: dob,
            gender: gender,
            avatarIndex: avatarIndex,
          );

          // Write profile to Supabase profiles table
          await SupabaseDbService.upsertProfile(newUser);

          _registeredUsers.removeWhere((u) => u.email.toLowerCase() == cleanEmail);
          _registeredUsers.add(newUser);
          await _saveUsersToPrefs();
          await _saveCurrentSession(newUser);
          notifyListeners();
          return null; // Success
        }
      } on AuthException catch (e) {
        return e.message;
      } catch (e) {
        debugPrint('Supabase sign up warning: $e');
        // Fall back to local account store if network issue
      }
    }

    // ── Local fallback ────────────────────────────────────────────────────
    if (_registeredUsers.any((u) => u.email.toLowerCase() == cleanEmail)) {
      return 'An account with this email address already exists!';
    }
    if (effectiveRole == 'student' && cleanRoll.isNotEmpty &&
        _registeredUsers.any((u) => u.rollNumber.toUpperCase() == cleanRoll)) {
      return 'An account with this Roll Number / ID already exists!';
    }

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: cleanEmail,
      password: password,
      role: effectiveRole,
      rollNumber: cleanRoll,
      department: department,
      college: college,
      year: year,
      phone: phone.trim(),
      dob: dob,
      gender: gender,
      avatarIndex: avatarIndex,
    );

    _registeredUsers.add(newUser);
    await _saveUsersToPrefs();
    await _saveCurrentSession(newUser);
    notifyListeners();
    return null; // Success
  }

  // ─── SIGN IN ─────────────────────────────────────────────────────────────

  Future<String?> signIn({
    required String emailOrId,
    required String password,
  }) async {
    final cleanInput = emailOrId.trim().toLowerCase();
    final isAdmin = _isAdminEmail(cleanInput);

    // Try Supabase Auth Sign In if user provided an email
    if (SupabaseService.isInitialized && cleanInput.contains('@')) {
      try {
        final response = await SupabaseService.signIn(
          email: cleanInput,
          password: password,
        );

        if (response?.user != null) {
          final sbUser = response!.user!;

          // Fetch full profile from Supabase DB
          final profile = await SupabaseDbService.fetchProfile(sbUser.id);

          late UserModel authenticatedUser;
          if (profile != null) {
            authenticatedUser = profile.copyWith(
              email: sbUser.email ?? cleanInput,
              password: password,
              // Always enforce admin role for the admin email
              role: isAdmin ? 'admin' : profile.role,
            );
          } else {
            // Profile doesn't exist yet — create from auth metadata
            final metadata = sbUser.userMetadata ?? {};
            final effectiveRole = isAdmin ? 'admin' : (metadata['role'] ?? 'student');
            authenticatedUser = UserModel(
              id: sbUser.id,
              name: metadata['name'] ?? sbUser.email?.split('@').first ?? 'User',
              email: sbUser.email ?? cleanInput,
              password: password,
              role: effectiveRole,
              rollNumber: metadata['roll_number'] ?? '',
              department: metadata['department'] ?? AitsDepartments.defaultDepartment,
              college: metadata['college'] ?? TirupatiColleges.defaultCollege,
              year: metadata['year'] ?? '1st Year',
              phone: metadata['phone'] ?? '',
              dob: metadata['dob'] ?? '',
              gender: metadata['gender'] ?? 'Male',
              avatarIndex: metadata['avatar_index'] ?? 0,
            );
            // Persist the profile to Supabase for next time
            await SupabaseDbService.upsertProfile(authenticatedUser);
          }

          // Update local cache
          final index = _registeredUsers.indexWhere(
              (u) => u.id == authenticatedUser.id || u.email.toLowerCase() == cleanInput);
          if (index != -1) {
            _registeredUsers[index] = authenticatedUser;
          } else {
            _registeredUsers.add(authenticatedUser);
          }
          await _saveUsersToPrefs();
          await _saveCurrentSession(authenticatedUser);
          notifyListeners();
          return null; // Success
        }
      } on AuthException catch (e) {
        if (!isAdmin) return e.message;
        debugPrint('Supabase sign-in failed for admin email, falling back to local admin match: ${e.message}');
      } catch (e) {
        debugPrint('Supabase sign in warning: $e');
        // Fall back to local matching
      }
    }

    // ── Local fallback ────────────────────────────────────────────────────
    int index = _registeredUsers.indexWhere(
      (u) =>
          u.email.toLowerCase() == cleanInput ||
          (u.rollNumber.isNotEmpty && u.rollNumber.toLowerCase() == cleanInput),
    );

    UserModel userMatch;
    if (index != -1) {
      userMatch = _registeredUsers[index];
    } else if (isAdmin) {
      // Auto-register admin account if missing locally
      userMatch = UserModel(
        id: 'admin_default_01',
        name: 'N Events Admin',
        email: _adminEmail,
        password: password,
        role: 'admin',
        rollNumber: 'ADMIN-01',
        department: 'Administration',
        college: TirupatiColleges.defaultCollege,
      );
      _registeredUsers.add(userMatch);
      await _saveUsersToPrefs();
    } else {
      return 'User not found! Please check your Email/Roll No or Sign Up first.';
    }

    if (!isAdmin && userMatch.password != password) {
      return 'Incorrect password! Please try again.';
    }

    // Apply admin role override before saving (handles local fallback path)
    final sessionUser = isAdmin ? userMatch.copyWith(role: 'admin', password: password) : userMatch;
    await _saveCurrentSession(sessionUser);
    notifyListeners();
    return null; // Success
  }

  // ─── GOOGLE SIGN IN ──────────────────────────────────────────────────────

  Future<String?> signInWithGoogle({String role = 'student'}) async {
    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.signInWithGoogle();
        final sbUser = SupabaseService.currentUser;
        if (sbUser != null) {
          await _loadProfileFromSupabase(sbUser);
          notifyListeners();
          return null;
        }
      }
    } catch (e) {
      debugPrint('Google OAuth Warning: $e');
    }

    // Google Sign-In Fallback / Demo Account creation
    final googleDemoUser = UserModel(
      id: 'usr_google_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Google Auth User',
      email: 'user.google@gmail.com',
      password: 'google123',
      role: role,
      rollNumber: 'GGL-2026-01',
      department: AitsDepartments.defaultDepartment,
      year: '2nd Year',
      phone: '',
      avatarIndex: 0,
    );

    await _saveCurrentSession(googleDemoUser);
    notifyListeners();
    return null;
  }

  // ─── HANDLE GOOGLE AUTH SUCCESS ──────────────────────────────────────────

  Future<void> handleGoogleAuthSuccess({
    required String id,
    required String name,
    required String email,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Try to load from Supabase profiles first
    if (SupabaseService.isInitialized) {
      final profile = await SupabaseDbService.fetchProfile(id);
      if (profile != null) {
        final merged = profile.copyWith(email: cleanEmail, password: '');
        await _saveCurrentSession(merged);
        notifyListeners();
        return;
      }
    }

    final index = _registeredUsers.indexWhere(
        (u) => u.id == id || u.email.toLowerCase() == cleanEmail);

    UserModel user;
    if (index != -1) {
      user = _registeredUsers[index];
    } else {
      user = UserModel(
        id: id,
        name: name,
        email: cleanEmail,
        password: 'oauth_google_protected',
        role: 'student',
        rollNumber: '',
        department: AitsDepartments.defaultDepartment,
        college: TirupatiColleges.defaultCollege,
        year: '1st Year',
      );
      _registeredUsers.add(user);
      await _saveUsersToPrefs();
      // Also write to Supabase
      await SupabaseDbService.upsertProfile(user);
    }
    await _saveCurrentSession(user);
    notifyListeners();
  }

  // ─── RESET PASSWORD ──────────────────────────────────────────────────────

  Future<String?> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final index = _registeredUsers.indexWhere(
      (u) =>
          u.email.toLowerCase() == cleanEmail ||
          u.rollNumber.toLowerCase() == cleanEmail,
    );

    if (index == -1) {
      return 'No registered user account found for "$email".';
    }

    final updatedUser = _registeredUsers[index].copyWith(password: newPassword);
    _registeredUsers[index] = updatedUser;

    if (_currentUser?.id == updatedUser.id) {
      _currentUser = updatedUser;
    }

    await _saveUsersToPrefs();
    notifyListeners();
    return null; // Success
  }

  // ─── LEGACY LOGIN ────────────────────────────────────────────────────────

  Future<void> login(String selectedRole) async {
    final defaultUser = _registeredUsers.firstWhere(
      (u) => u.role == selectedRole,
      orElse: () => _getDefaultAccounts().first,
    );

    _currentUser = defaultUser;
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyCurrentUserId, defaultUser.id);

    notifyListeners();
  }

  // ─── LOGOUT ──────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;

    await SupabaseService.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyCurrentUserId);
    await prefs.remove(_keyCurrentUserJson);

    notifyListeners();
  }

  // ─── UPDATE PROFILE ──────────────────────────────────────────────────────

  Future<void> updateProfile({
    required String name,
    required String roll,
    required String dept,
    String? college,
    required String year,
    required String phone,
    String? dob,
    String? gender,
    int? avatarIndex,
    String? customAvatarUrl,
  }) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      name: name,
      rollNumber: roll,
      department: dept,
      college: college ?? _currentUser!.college,
      year: year,
      phone: phone,
      dob: dob ?? _currentUser!.dob,
      gender: gender ?? _currentUser!.gender,
      avatarIndex: avatarIndex ?? _currentUser!.avatarIndex,
      customAvatarUrl: customAvatarUrl ?? _currentUser!.customAvatarUrl,
    );

    // Update in registered list
    final index = _registeredUsers.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _registeredUsers[index] = updatedUser;
    } else {
      _registeredUsers.add(updatedUser);
    }

    await _saveUsersToPrefs();
    await _saveCurrentSession(updatedUser);

    // Persist updated profile to Supabase
    await SupabaseDbService.upsertProfile(updatedUser);

    // Also update Supabase auth metadata
    await SupabaseService.updateUserMetadata({
      'name': name,
      'roll_number': roll,
      'department': dept,
      'year': year,
      'phone': phone,
    });

    notifyListeners();
  }
}
