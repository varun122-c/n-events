import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

class OAuthCallbackScreen extends StatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _handleOAuthResult();
  }

  Future<void> _handleOAuthResult() async {
    // Wait briefly for Supabase SDK to complete deep link token exchange
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final sbUser = SupabaseService.currentUser;
    if (sbUser != null) {
      final metadata = sbUser.userMetadata ?? {};
      final name = metadata['full_name'] ??
          metadata['name'] ??
          sbUser.email?.split('@').first ??
          'Google User';
      final email = sbUser.email ?? '';

      await authProvider.handleGoogleAuthSuccess(
        id: sbUser.id,
        name: name,
        email: email,
      );

      if (!mounted) return;
      if (authProvider.role == 'admin') {
        context.go(authProvider.homeRoute);
      } else if (authProvider.studentRoll.isEmpty || authProvider.studentRoll.startsWith('GGL-')) {
        context.go('/auth?tab=signup');
      } else {
        context.go(authProvider.homeRoute);
      }
    } else {
      // If user session wasn't established, navigate back to auth
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF2563EB)),
            const SizedBox(height: 20),
            Text(
              'Completing Google Sign In...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Syncing your profile credentials...',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
