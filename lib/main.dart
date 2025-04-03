import 'package:events360_admin/core/themes/app_theme.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/infrastructure/user_role_service.dart';
import 'package:events360_admin/presentation/auth/sign_in_screen.dart';
import 'package:events360_admin/presentation/auth/sign_up_with_invitation_screen.dart';
import 'package:events360_admin/presentation/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Update the main function
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  await dotenv.load(fileName: ".env");

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Events360 Admin',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const SignInScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle the member_signup route with token parameter
        if (settings.name == '/member_signup') {
          // Extract token from arguments
          final token = settings.arguments as String? ?? '';

          return MaterialPageRoute(
            builder: (context) => SignUpWithInvitationScreen(
              invitationToken: token,
            ),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInvitationToken();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = SupabaseService().client.auth.currentSession;
    final isAuthenticated = session != null;

    if (isAuthenticated) {
      await UserRoleService.initialize(session.user.id);
      await SupabaseService.loadOrganizationIdFromStorage();
    }

    if (mounted) {
      setState(() {
        _isAuthenticated = isAuthenticated;
        _isLoading = false;
      });
    }
  }

  void _checkInvitationToken() {
    // Check if there's a token in the URL
    final uri = Uri.base;
    final fragment = uri.fragment;

    // Handle hash fragment URLs like /#/member_signup?token=xyz
    if (fragment.startsWith('/member_signup')) {
      final tokenParam = Uri.parse(fragment).queryParameters['token'];
      if (tokenParam != null && tokenParam.isNotEmpty) {
        // Navigate to signup screen with the token
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/member_signup',
              arguments: tokenParam);
        });
        return;
      }
    }

    // Also check regular query parameters (fallback)
    final token = uri.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      // Navigate to signup screen with the token
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/member_signup',
            arguments: token);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isAuthenticated) {
      return const AdminHomeScreen();
    }

    return const SignInScreen();
  }
}
