import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Hindi', 'Spanish', 'French', 'Arabic'];
  final AuthService _authService = AuthService();
  bool _isProfileLoading = true;
  String _name = '';
  String _username = '';
  String _sports = '';
  String _teams = '';
  String _players = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (!mounted) return;
        setState(() {
          _name = data['name'] ?? user.displayName ?? 'Sports Fan';
          _username = data['username'] ?? '';
          _sports = data['sports'] ?? 'Cricket, Football';
          _teams = data['teams'] ?? 'Real Madrid, Mumbai Indians';
          _players = data['players'] ?? 'Virat Kohli, Lionel Messi';
        });
        
        if (_username.isEmpty) {
          await _initializeDefaultUsername(user);
        } else {
          if (!mounted) return;
          setState(() {
            _isProfileLoading = false;
          });
        }
      } else {
        await _initializeDefaultProfile(user);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (!mounted) return;
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _initializeDefaultUsername(User user) async {
    final uid = user.uid;
    final suffix = uid.length >= 5 ? uid.substring(uid.length - 5) : uid;
    final tempUsername = 'fan_$suffix'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    
    try {
      await FirebaseFirestore.instance.collection('usernames').doc(tempUsername).set({
        'uid': uid,
      });
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': user.displayName ?? 'Sports Fan',
        'username': tempUsername,
        'sports': _sports.isEmpty ? 'Cricket, Football' : _sports,
        'teams': _teams.isEmpty ? 'Real Madrid, Mumbai Indians' : _teams,
        'players': _players.isEmpty ? 'Virat Kohli, Lionel Messi' : _players,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _username = tempUsername;
        _isProfileLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing default username: $e');
      if (!mounted) return;
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _initializeDefaultProfile(User user) async {
    final uid = user.uid;
    final suffix = uid.length >= 5 ? uid.substring(uid.length - 5) : uid;
    final tempUsername = 'fan_$suffix'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');

    try {
      await FirebaseFirestore.instance.collection('usernames').doc(tempUsername).set({
        'uid': uid,
      });
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': user.displayName ?? 'Sports Fan',
        'username': tempUsername,
        'sports': 'Cricket, Football',
        'teams': 'Real Madrid, Mumbai Indians',
        'players': 'Virat Kohli, Lionel Messi',
      });

      if (!mounted) return;
      setState(() {
        _name = user.displayName ?? 'Sports Fan';
        _username = tempUsername;
        _sports = 'Cricket, Football';
        _teams = 'Real Madrid, Mumbai Indians';
        _players = 'Virat Kohli, Lionel Messi';
        _isProfileLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing profile: $e');
      if (!mounted) return;
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _editField(String title, String fieldKey, String currentValue) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: currentValue);
    String? errorMessage;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'EDIT ${title.toUpperCase()}',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00FF7F),
                  letterSpacing: 1.5,
                  fontSize: 16,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter new $title',
                      hintStyle: GoogleFonts.inter(color: Colors.grey[650]),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF7F)),
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newValue = controller.text.trim();
                          if (newValue.isEmpty) {
                            setDialogState(() {
                              errorMessage = '$title cannot be empty';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            errorMessage = null;
                          });

                          try {
                            if (fieldKey == 'username') {
                              final cleanVal = newValue.toLowerCase().replaceAll('@', '').trim();
                              final usernameRegExp = RegExp(r'^[a-z0-9_]{3,20}$');
                              if (!usernameRegExp.hasMatch(cleanVal)) {
                                throw Exception('Username must be 3-20 characters, containing only lowercase letters, numbers, and underscores.');
                              }

                              if (cleanVal != _username) {
                                final doc = await FirebaseFirestore.instance
                                    .collection('usernames')
                                    .doc(cleanVal)
                                    .get();

                                if (doc.exists) {
                                  final data = doc.data();
                                  if (data?['uid'] != user.uid) {
                                    throw Exception('Username is already taken by another user.');
                                  }
                                }

                                final batch = FirebaseFirestore.instance.batch();
                                batch.set(
                                  FirebaseFirestore.instance.collection('usernames').doc(cleanVal),
                                  {'uid': user.uid},
                                );
                                batch.update(
                                  FirebaseFirestore.instance.collection('users').doc(user.uid),
                                  {'username': cleanVal},
                                );
                                if (_username.isNotEmpty && _username != cleanVal) {
                                  batch.delete(
                                    FirebaseFirestore.instance.collection('usernames').doc(_username),
                                  );
                                }

                                await batch.commit();
                                setState(() {
                                  _username = cleanVal;
                                });
                              }
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({fieldKey: newValue});

                              if (fieldKey == 'name') {
                                await user.updateDisplayName(newValue);
                                await user.reload();
                                setState(() {
                                  _name = newValue;
                                });
                              } else if (fieldKey == 'sports') {
                                setState(() {
                                  _sports = newValue;
                                });
                              } else if (fieldKey == 'teams') {
                                setState(() {
                                  _teams = newValue;
                                });
                              } else if (fieldKey == 'players') {
                                setState(() {
                                  _players = newValue;
                                });
                              }
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$title updated successfully!'),
                                  backgroundColor: const Color(0xFF00FF7F),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('SystemException: ', '');
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FF7F)),
                        )
                      : const Text('SAVE', style: TextStyle(color: Color(0xFF00FF7F), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fetch active user details from Firebase Auth
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    final String email = firebaseUser?.email ?? 'No email address';

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
      body: _isProfileLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Avatar & Basic Info
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF00FF7F).withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Color(0xFF00FF7F),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _name,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$_username',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00FF7F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Account Details Section
                  _buildSectionTitle('ACCOUNT DETAILS'),
                  _buildInfoCard(
                    title: 'Display Name',
                    value: _name,
                    icon: Icons.person_outline,
                    onTap: () => _editField('Display Name', 'name', _name),
                  ),
                  _buildInfoCard(
                    title: 'Unique Username',
                    value: '@$_username',
                    icon: Icons.alternate_email,
                    onTap: () => _editField('Unique Username', 'username', _username),
                  ),

                  const SizedBox(height: 24),

                  // Favorites Section
                  _buildSectionTitle('FAVORITES'),
                  _buildInfoCard(
                    title: 'Favorite Sports',
                    value: _sports,
                    icon: Icons.sports_score,
                    onTap: () => _editField('Favorite Sports', 'sports', _sports),
                  ),
                  _buildInfoCard(
                    title: 'Favorite Teams',
                    value: _teams,
                    icon: Icons.shield,
                    onTap: () => _editField('Favorite Teams', 'teams', _teams),
                  ),
                  _buildInfoCard(
                    title: 'Favorite Players',
                    value: _players,
                    icon: Icons.star,
                    onTap: () => _editField('Favorite Players', 'players', _players),
                  ),

                  const SizedBox(height: 32),

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
                        const Icon(Icons.language, color: Color(0xFF00FF7F)),
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
                      onPressed: () async {
                        // Confirm dialog
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            title: Text(
                              'LOG OUT',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to sign out of the Sports Hub?',
                              style: GoogleFonts.inter(color: Colors.grey[300]),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _authService.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        }
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

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                if (onTap != null)
                  Icon(Icons.edit, size: 16, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
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
