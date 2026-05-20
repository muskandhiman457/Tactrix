import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SportsHubApp());
}

class SportsHubApp extends StatelessWidget {
  const SportsHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00FF7F),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00FF7F),
          secondary: const Color(0xFF00FF7F),
          surface: const Color(0xFF121212),
        ),
      ),
      home: LoginScreen(),
    );
  }
}
