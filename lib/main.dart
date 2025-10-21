import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() {
  runApp(const AegisApp());
}

class AegisApp extends StatelessWidget {
  const AegisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aegis App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E1117),
      ),
      home: const LoginScreen(), // start with login screen
    );
  }
}
