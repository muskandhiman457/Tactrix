import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/main_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyANMvjkbeZtPI9RAMUHCBbGsuaZKEFFUdY',
        appId: '1:46829962310:web:b5c8473db7233bdabaf647',
        messagingSenderId: '46829962310',
        projectId: 'sports-hub-92ef5',
        storageBucket: 'sports-hub-92ef5.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const SportsHubApp());
}

class SportsHubApp extends StatelessWidget {
  const SportsHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    final User? currentUser = FirebaseAuth.instance.currentUser;

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
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF7F),
          secondary: Color(0xFF00FF7F),
          surface: Color(0xFF121212),
        ),
      ),
      home: currentUser != null ? const MainDashboard() : const LoginScreen(),
    );
  }
}
