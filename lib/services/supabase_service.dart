import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Initialize Supabase SDK
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('Supabase initialized successfully!');
    } catch (e) {
      debugPrint('Supabase initialization warning (running in hybrid fallback mode): $e');
      _isInitialized = false;
    }
  }

  // Sign up with Supabase Auth
  static Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userMetadata,
  }) async {
    if (!_isInitialized || client == null) return null;
    try {
      final response = await client!.auth.signUp(
        email: email.trim(),
        password: password,
        data: userMetadata,
      );
      return response;
    } catch (e) {
      debugPrint('Supabase SignUp Exception: $e');
      rethrow;
    }
  }

  // Sign in with Supabase Auth
  static Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized || client == null) return null;
    try {
      final response = await client!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Supabase SignIn Exception: $e');
      rethrow;
    }
  }

  // Sign in with Google Auth
  static Future<bool> signInWithGoogle() async {
    if (!_isInitialized || client == null) {
      debugPrint('Supabase is not initialized.');
      return false;
    }
    try {
      final String redirectUrl = kIsWeb
          ? Uri.base.origin
          : 'io.supabase.nvents://login-callback';
      return await client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
    } catch (e) {
      debugPrint('Supabase Google OAuth Exception: $e');
      rethrow;
    }
  }

  // Sign out from Supabase Auth
  static Future<void> signOut() async {
    if (!_isInitialized || client == null) return;
    try {
      await client!.auth.signOut();
    } catch (e) {
      debugPrint('Supabase SignOut Exception: $e');
    }
  }

  // Get current user session
  static Session? get currentSession {
    if (!_isInitialized || client == null) return null;
    return client!.auth.currentSession;
  }

  // Get current auth user
  static User? get currentUser {
    if (!_isInitialized || client == null) return null;
    return client!.auth.currentUser;
  }

  // Update user metadata in Supabase Auth
  static Future<void> updateUserMetadata(Map<String, dynamic> data) async {
    if (!_isInitialized || client == null) return;
    try {
      await client!.auth.updateUser(UserAttributes(data: data));
    } catch (e) {
      debugPrint('Supabase updateUserMetadata Exception: $e');
    }
  }
}
