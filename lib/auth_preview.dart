import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';

void main() => runApp(const AuthPreviewApp());

class AuthPreviewApp extends StatelessWidget {
  const AuthPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Preview',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
        fontFamily: 'Tajawal',
      ),
      home: const AuthScreen(),
    );
  }
}
