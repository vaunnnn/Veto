import 'package:flutter/material.dart';
// Make sure to import your AppTheme! Adjust the path if necessary.
import 'package:veto/core/themes/app_theme.dart'; 
import 'package:veto/features/rooms/screens/landing_screen.dart';


void main() {
  runApp(const VetoApp());
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