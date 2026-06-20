import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Hunger Games',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.jersey10TextTheme(),
        scaffoldBackgroundColor: const Color(0xFF2C1A0E),
      ),
      home: const MainScreen(),
    );
  }
}