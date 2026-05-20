import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'JOIN THE LEAGUE',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create your profile to track matches, analyze stats, and join the community.',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
              ),
              SizedBox(height: 40),
              _buildTextField(
                hint: 'Full Name',
                icon: Icons.person_outline,
                obscureText: false,
              ),
              SizedBox(height: 16),
              _buildTextField(
                hint: 'Email Address',
                icon: Icons.email_outlined,
                obscureText: false,
              ),
              SizedBox(height: 16),
              _buildTextField(
                hint: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              SizedBox(height: 16),
              _buildTextField(
                hint: 'Confirm Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: Mock Register Action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00FF7F),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  'CREATE ACCOUNT',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required bool obscureText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: TextField(
        obscureText: obscureText,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
