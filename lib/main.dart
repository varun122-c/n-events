import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/app_state_provider.dart';
import 'router/app_router.dart';
import 'services/supabase_service.dart';
import 'services/sender_email_service.dart';
import 'widgets/web_responsive_frame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Mount UI immediately for lightning fast web load time
  runApp(const MyApp());

  // Initialize network & services asynchronously in background
  _initServicesAsync();
}

void _initServicesAsync() async {
  try {
    await SenderEmailService.init();
  } catch (e) {
    debugPrint('Email service init error: $e');
  }
  try {
    await SupabaseService.initialize().timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        debugPrint('Supabase init timeout on startup, proceeding with offline mode...');
      },
    );
  } catch (e) {
    debugPrint('Supabase init error on startup: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, stateProvider, _) {
          return MaterialApp.router(
            title: 'nEvents',
            debugShowCheckedModeBanner: false,
            themeMode: stateProvider.themeMode,
            builder: (context, child) => WebResponsiveFrame(child: child ?? const SizedBox()),
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3C72),
                primary: const Color(0xFF1E3C72),
                secondary: const Color(0xFF0F2027),
                tertiary: Colors.cyan,
                brightness: Brightness.light,
              ),
              cardTheme: const CardThemeData(
                color: Colors.white,
                elevation: 0,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: Colors.white,
                constraints: BoxConstraints(maxWidth: 500),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Colors.white,
                constraints: BoxConstraints(maxWidth: 500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF1E293B),
                elevation: 0,
                iconTheme: IconThemeData(color: Color(0xFF1E293B)),
              ),
              navigationBarTheme: NavigationBarThemeData(
                indicatorColor: Colors.cyan.shade100,
                backgroundColor: Colors.white,
                labelTextStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.black,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3C72),
                primary: const Color(0xFF1E3C72),
                secondary: const Color(0xFF0F2027),
                tertiary: Colors.cyan,
                brightness: Brightness.dark,
                surface: Colors.black,
              ),
              cardTheme: const CardThemeData(
                color: Colors.black,
                elevation: 0,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: Colors.black,
                constraints: BoxConstraints(maxWidth: 500),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Colors.black,
                constraints: BoxConstraints(maxWidth: 500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              navigationBarTheme: NavigationBarThemeData(
                indicatorColor: Colors.cyan.shade900,
                backgroundColor: Colors.black,
                labelTextStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                ),
              ),
            ),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
