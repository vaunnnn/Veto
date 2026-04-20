import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Make sure to import your AppTheme! Adjust the path if necessary.
import 'package:veto/core/themes/app_theme.dart';
import 'package:veto/features/rooms/screens/landing_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // 1. MUST be first
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load env variables - try .env.local first (secure), fall back to .env
  try {
    await dotenv.load(fileName: ".env.local");
  } catch (e) {
    // Fallback to .env for backward compatibility
    await dotenv.load(fileName: ".env");
  }

  // 3. MUST happen before runApp
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const ProviderScope(child: VetoApp()));
}

class VetoApp extends StatelessWidget {
  const VetoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veto',
      debugShowCheckedModeBanner: false,

      // 1. Hook up your Light Theme
      theme: AppTheme.lightTheme,

      // 2. Hook up your Dark Theme
      darkTheme: AppTheme.darkTheme,

      // 3. Tell Flutter how to switch between them (system default is usually best)
      themeMode: ThemeMode.system,

      home: const LandingScreen(),
    );
  }
}
