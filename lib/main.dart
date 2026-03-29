import 'package:flutter/material.dart';
// 1. Import your landing screen file here
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      
      home: const LandingScreen(),
    );
  }
}