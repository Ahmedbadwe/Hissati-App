import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'models/app_user.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_role_screen.dart';
import 'screens/phone_login_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const HissatiApp());
}

class HissatiApp extends StatelessWidget {
  const HissatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حصتي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1565C0),
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const _AuthGate(),
    );
  }
}

/// Root router: listens to Firebase Auth state and decides whether to show
/// the login screen, onboarding (first-time user missing a Firestore
/// profile), or the main app shell.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return const PhoneLoginScreen();
        }

        return FutureBuilder<AppUser?>(
          future: AuthService.instance.fetchExistingProfile(firebaseUser.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              return OnboardingRoleScreen(
                uid: firebaseUser.uid,
                phoneNumber: firebaseUser.phoneNumber ?? '',
              );
            }

            return MainNavigationScreen(currentUser: profile);
          },
        );
      },
    );
  }
}
