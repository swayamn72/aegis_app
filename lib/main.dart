import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'aegis_main_scaffold.dart'; // 👈 Import your main scaffold

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

      // 👇 Instead of home:, use routes + initialRoute
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const AegisMainScaffold(),
      },
    );
  }
}
