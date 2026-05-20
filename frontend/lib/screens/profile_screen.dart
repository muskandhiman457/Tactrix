import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Hindi', 'Spanish', 'French', 'Arabic'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'PROFILE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar & Basic Info
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF00FF7F).withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF00FF7F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Alex Champion',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'alex.champ@example.com',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Favorites Section
            _buildSectionTitle('FAVORITES'),
            _buildInfoCard(
              title: 'Favorite Sports',
              value: 'Cricket, Football',
              icon: Icons.sports_score,
            ),
            _buildInfoCard(
              title: 'Favorite Teams',
              value: 'Real Madrid, Mumbai Indians',
              icon: Icons.shield,
            ),
            _buildInfoCard(
              title: 'Favorite Players',
              value: 'Virat Kohli, Lionel Messi',
              icon: Icons.star,
            ),

            const SizedBox(height: 40),

            // Settings Section
            _buildSectionTitle('SETTINGS'),
            
            // Language Selector
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.language, color: const Color(0xFF00FF7F)),
                  const SizedBox(width: 16),
                  Text(
                    'Language',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      dropdownColor: const Color(0xFF1E1E1E),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      style: GoogleFonts.inter(color: Colors.white),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLanguage = newValue!;
                          // TODO: Implement easy_localization context.setLocale() here
                        });
                      },
                      items: _languages.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            _buildSettingsTile(title: 'About Us', icon: Icons.info_outline, onTap: () {}),
            _buildSettingsTile(title: 'Help & Support', icon: Icons.help_outline, onTap: () {}),
            
            const SizedBox(height: 20),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Mock Logout
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: Text(
                  'LOGOUT',
                  style: GoogleFonts.outfit(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00FF7F)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({required String title, required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00FF7F)),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
