import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Hindi'];
  final AuthService _authService = AuthService();
  bool _isProfileLoading = true;
  String _name = '';
  String _username = '';
  String _sports = '';
  String _teams = '';
  String _players = '';
  String? _profilePicBase64;
  List<dynamic> _badges = [];
  double _predictionAccuracyRate = 0.0;
  int _chatActivityScore = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.locale.languageCode == 'hi') {
      _selectedLanguage = 'Hindi';
    } else {
      _selectedLanguage = 'English';
    }
  }

  Future<void> _loadUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPic = prefs.getString('profile_picture_${user.uid}');
      if (cachedPic != null && mounted) {
        setState(() {
          _profilePicBase64 = cachedPic;
        });
      }
    } catch (e) {
      debugPrint('Error loading cached profile picture: $e');
    }

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
          _profilePicBase64 = data['profilePicture'];
          
          _badges = data['badges'] is List ? List<dynamic>.from(data['badges']) : [];
          _predictionAccuracyRate = (data['prediction_accuracy_rate'] ?? 0.0).toDouble();
          _chatActivityScore = (data['chat_activity_score'] ?? 0).toInt();
        });

        if (data['profilePicture'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_picture_${user.uid}', data['profilePicture']);
        }
        
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

  Future<void> _recalculateBadges() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isProfileLoading = true;
    });

    final body = {
      'uid': user.uid,
      'prediction_accuracy_rate': _predictionAccuracyRate,
      'chat_activity_score': _chatActivityScore,
    };

    List<dynamic> calculatedBadges = [];
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/community/badges/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        calculatedBadges = resData['badges'] ?? [];
      }
    } catch (e) {
      debugPrint('Error triggering badge calculations via backend: $e');
    }

    if (calculatedBadges.isEmpty) {
      final nowStr = DateTime.now().toIso8601String();
      if (_predictionAccuracyRate > 75.0 || _predictionAccuracyRate > 0.75) {
        final pct = _predictionAccuracyRate > 1.0 ? _predictionAccuracyRate : _predictionAccuracyRate * 100;
        calculatedBadges.add({
          'id': 'top_predictor',
          'badge_name': 'Top Predictor',
          'badge_icon_url': 'https://img.icons8.com/color/48/star--v1.png',
          'badge_type': 'performance',
          'assigned_at': nowStr,
          'description': 'Top Predictor - Assigned for ${pct.toStringAsFixed(0)}% accurate match predictions'
        });
      }
      if (_chatActivityScore > 50) {
        calculatedBadges.add({
          'id': 'super_chatter',
          'badge_name': 'Super Chatter',
          'badge_icon_url': 'https://img.icons8.com/color/48/chat--v1.png',
          'badge_type': 'engagement',
          'assigned_at': nowStr,
          'description': 'Super Chatter - Assigned for reaching high chat activity score ($_chatActivityScore)'
        });
      }
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'prediction_accuracy_rate': _predictionAccuracyRate,
        'chat_activity_score': _chatActivityScore,
        'badges': calculatedBadges,
      });

      setState(() {
        _badges = calculatedBadges;
        _isProfileLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User badges recalculated and updated!'),
            backgroundColor: Color(0xFF00FF7F),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving recalculated badges to Firestore: $e');
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF00FF7F)),
              title: Text('Gallery', style: GoogleFonts.inter(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00FF7F)),
              title: Text('Camera', style: GoogleFonts.inter(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() {
        _profilePicBase64 = base64String;
      });

      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_picture_${user.uid}', base64String);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profilePicture': base64String,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_picture_updated'.tr()),
            backgroundColor: const Color(0xFF00FF7F),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _showSportsSelectionDialog() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final List<String> currentSports = _sports
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final List<String> availableSports = ['Cricket', 'Kabaddi', 'Football'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'favorite_sports'.tr().toUpperCase(),
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
                  Text(
                    'Select your favorite sports (restricted to analytical sports):',
                    style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableSports.map((sport) {
                      final isSelected = currentSports.contains(sport);
                      Color chipColor;
                      switch (sport) {
                        case 'Cricket':
                          chipColor = const Color(0xFF00FF7F);
                          break;
                        case 'Kabaddi':
                          chipColor = Colors.orangeAccent;
                          break;
                        case 'Football':
                          chipColor = Colors.blueAccent;
                          break;
                        default:
                          chipColor = const Color(0xFF00FF7F);
                      }
                      
                      return FilterChip(
                        label: Text(sport),
                        selected: isSelected,
                        labelStyle: GoogleFonts.inter(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        selectedColor: chipColor,
                        checkmarkColor: Colors.black,
                        backgroundColor: const Color(0xFF2D2D2D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? chipColor : Colors.grey[700]!,
                            width: 1,
                          ),
                        ),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              if (!currentSports.contains(sport)) {
                                currentSports.add(sport);
                              }
                            } else {
                              currentSports.remove(sport);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr().toUpperCase(), style: const TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    final newValue = currentSports.join(', ');
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({'sports': newValue});

                      if (!mounted) return;
                      setState(() {
                        _sports = newValue;
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Favorite sports updated successfully!'),
                            backgroundColor: const Color(0xFF00FF7F),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error updating sports: $e');
                    }
                  },
                  child: Text(
                    'save'.tr().toUpperCase(),
                    style: const TextStyle(color: Color(0xFF00FF7F), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
                                if (!mounted) return;
                                setState(() {
                                  _username = cleanVal;
                                });
                              }
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({fieldKey: newValue});

                              if (!mounted) return;

                              if (fieldKey == 'name') {
                                await user.updateDisplayName(newValue);
                                await user.reload();
                                if (!mounted) return;
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
          'profile_title'.tr().toUpperCase(),
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
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFF00FF7F).withValues(alpha: 0.2),
                                backgroundImage: _profilePicBase64 != null
                                    ? MemoryImage(base64Decode(_profilePicBase64!))
                                    : null,
                                child: _profilePicBase64 == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Color(0xFF00FF7F),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00FF7F),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: Color(0xFF121212),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                        if (_badges.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: _badges.map((badge) {
                              final name = badge['badge_name'] ?? 'Badge';
                              final iconUrl = badge['badge_icon_url'] ?? '';
                              final desc = badge['description'] ?? name;
                              return Tooltip(
                                message: desc,
                                child: GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(desc),
                                        backgroundColor: const Color(0xFF00FF7F),
                                        duration: const Duration(seconds: 3),
                                        action: SnackBarAction(
                                          label: 'OK',
                                          textColor: Colors.black,
                                          onPressed: () {},
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.network(
                                          iconUrl,
                                          width: 18,
                                          height: 18,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.star,
                                            size: 18,
                                            color: Color(0xFF00FF7F),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          name,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
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
                  _buildSectionTitle('account_details'.tr().toUpperCase()),
                  _buildInfoCard(
                    title: 'display_name'.tr(),
                    value: _name,
                    icon: Icons.person_outline,
                    onTap: () => _editField('display_name'.tr(), 'name', _name),
                  ),
                  _buildInfoCard(
                    title: 'unique_username'.tr(),
                    value: '@$_username',
                    icon: Icons.alternate_email,
                    onTap: () => _editField('unique_username'.tr(), 'username', _username),
                  ),

                  const SizedBox(height: 24),

                  // Favorites Section
                  _buildSectionTitle('favorites'.tr().toUpperCase()),
                  _buildInfoCard(
                    title: 'favorite_sports'.tr(),
                    value: _sports,
                    icon: Icons.sports_score,
                    onTap: _showSportsSelectionDialog,
                  ),
                  _buildInfoCard(
                    title: 'favorite_teams'.tr(),
                    value: _teams,
                    icon: Icons.shield,
                    onTap: () => _editField('favorite_teams'.tr(), 'teams', _teams),
                  ),
                  _buildInfoCard(
                    title: 'favorite_players'.tr(),
                    value: _players,
                    icon: Icons.star,
                    onTap: () => _editField('favorite_players'.tr(), 'players', _players),
                  ),

                  const SizedBox(height: 32),

                  // Settings Section
                  _buildSectionTitle('settings'.tr().toUpperCase()),
                  
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
                          'language'.tr(),
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
                              if (newValue != null) {
                                setState(() {
                                  _selectedLanguage = newValue;
                                });
                                if (newValue == 'Hindi') {
                                  context.setLocale(const Locale('hi'));
                                } else {
                                  context.setLocale(const Locale('en'));
                                }
                              }
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

                  _buildSettingsTile(title: 'about_us'.tr(), icon: Icons.info_outline, onTap: () {}),
                  _buildSettingsTile(title: 'help_support'.tr(), icon: Icons.help_outline, onTap: () {}),
                  
                  const SizedBox(height: 20),
                  
                  // Badge Assignment Simulator
                  _buildSectionTitle('BADGE ASSIGNMENT SIMULATOR'),
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Automated Badge Triggers',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adjust metrics to simulate automated triggers: Top Predictor (>75% accuracy) and Super Chatter (>50 score).',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Prediction Accuracy:',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                            ),
                            Text(
                              '${(_predictionAccuracyRate > 1.0 ? _predictionAccuracyRate : _predictionAccuracyRate * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF00FF7F),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _predictionAccuracyRate > 1.0 
                              ? _predictionAccuracyRate / 100.0 
                              : _predictionAccuracyRate,
                          min: 0.0,
                          max: 1.0,
                          activeColor: const Color(0xFF00FF7F),
                          inactiveColor: Colors.grey[800],
                          onChanged: (val) {
                            setState(() {
                              _predictionAccuracyRate = val;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Chat Activity Score:',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                            ),
                            Text(
                              '$_chatActivityScore',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF00FF7F),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _chatActivityScore.toDouble(),
                          min: 0.0,
                          max: 100.0,
                          divisions: 100,
                          activeColor: const Color(0xFF00FF7F),
                          inactiveColor: Colors.grey[800],
                          onChanged: (val) {
                            setState(() {
                              _chatActivityScore = val.round();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _recalculateBadges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FF7F),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'RECALCULATE & UPDATE BADGES',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                              'confirm_logout_title'.tr().toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            content: Text(
                              'confirm_logout_msg'.tr(),
                              style: GoogleFonts.inter(color: Colors.grey[300]),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('cancel'.tr().toUpperCase(), style: const TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('logout'.tr().toUpperCase(), style: const TextStyle(color: Colors.redAccent)),
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
                        'logout'.tr().toUpperCase(),
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
