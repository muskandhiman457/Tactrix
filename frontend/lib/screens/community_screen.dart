import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_config.dart';


import 'live_chat_room.dart';
import 'poll_widget.dart';
import 'lineup_creator_dialog.dart';
import 'lineup_preview_widget.dart';
import 'dynamic_user_avatar.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _isLoadingProfile = true;
  String _currentUserHandle = "@sports_fan";
  String _currentUserName = "Sports Fan";
  String _favoriteSports = "";
  String _favoritePlayers = "";
  List<dynamic> _currentUserBadges = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (!mounted) return;
        setState(() {
          _currentUserName = data['name'] ?? user.displayName ?? 'Sports Fan';
          final rawUsername = data['username'] ?? '';
          _currentUserHandle = rawUsername.isNotEmpty ? '@$rawUsername' : '@sports_fan';
          _favoriteSports = data['sports'] ?? '';
          _favoritePlayers = data['players'] ?? '';
          _currentUserBadges = data['badges'] is List ? List<dynamic>.from(data['badges']) : [];
          _isLoadingProfile = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile in community parent: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          title: Text(
            'community_hub'.tr().toUpperCase(),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: const Color(0xFF00FF7F),
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xFF00FF7F),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
            tabs: [
              Tab(text: 'live_chat'.tr().toUpperCase()),
              Tab(text: 'feed_polls'.tr().toUpperCase()),
              Tab(text: 'sports_news'.tr().toUpperCase()),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            LiveChatTab(
              currentUserHandle: _currentUserHandle,
              currentUserName: _currentUserName,
            ),
            CommunityFeedTab(
              currentUserHandle: _currentUserHandle,
              currentUserName: _currentUserName,
              favoriteSports: _favoriteSports,
              favoritePlayers: _favoritePlayers,
              currentUserBadges: _currentUserBadges,
            ),
            SportsNewsTab(
              favoriteSports: _favoriteSports,
              favoritePlayers: _favoritePlayers,
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- TAB 1: LIVE CHAT TAB -----------------
class LiveChatTab extends StatefulWidget {
  final String currentUserHandle;
  final String currentUserName;

  const LiveChatTab({
    super.key,
    required this.currentUserHandle,
    required this.currentUserName,
  });

  @override
  State<LiveChatTab> createState() => _LiveChatTabState();
}

class _LiveChatTabState extends State<LiveChatTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoadingRooms = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveRooms();
  }

  Future<void> _fetchActiveRooms() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRooms = true;
    });

    final List<Map<String, dynamic>> rooms = [];

    try {
      final futures = [
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/cricket/matches/live-and-upcoming')).timeout(const Duration(seconds: 5)),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/kabaddi/matches/live-and-upcoming')).timeout(const Duration(seconds: 5)),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/football/matches/live-and-upcoming')).timeout(const Duration(seconds: 5)),
      ];

      final responses = await Future.wait(futures);

      // Parse Cricket
      if (responses[0].statusCode == 200) {
        final data = jsonDecode(responses[0].body);
        final matches = data['matches'] is List ? data['matches'] : [];
        for (var m in matches) {
          final info = m['matchInfo'] ?? {};
          final state = info['state'] ?? 'Preview';
          if (state.toLowerCase() != 'complete') {
            final t1Short = info['team1']?['teamSName'] ?? 'T1';
            final t2Short = info['team2']?['teamSName'] ?? 'T2';
            final desc = info['matchDesc'] ?? 'Live Match';
            final matchId = info['matchId']?.toString() ?? 'unknown';
            rooms.add({
              'id': 'cricket_$matchId',
              'name': '$t1Short vs $t2Short - $desc',
              'sport': 'Cricket',
              'status': state.toUpperCase(),
              'details': info['status'] ?? 'Active Cricket Match discussion',
            });
          }
        }
      }

      // Parse Kabaddi
      if (responses[1].statusCode == 200) {
        final data = jsonDecode(responses[1].body);
        final matches = data['matches'] is List ? data['matches'] : [];
        for (var m in matches) {
          final info = m['matchInfo'] ?? {};
          final state = info['state'] ?? 'Preview';
          if (state.toLowerCase() != 'complete') {
            final t1Short = info['team1']?['teamSName'] ?? 'T1';
            final t2Short = info['team2']?['teamSName'] ?? 'T2';
            final desc = info['matchDesc'] ?? 'Live Match';
            final matchId = info['matchId']?.toString() ?? 'unknown';
            rooms.add({
              'id': 'kabaddi_$matchId',
              'name': '$t1Short vs $t2Short - $desc',
              'sport': 'Kabaddi',
              'status': state.toUpperCase(),
              'details': info['status'] ?? 'Active Kabaddi Match discussion',
            });
          }
        }
      }

      // Parse Football
      if (responses[2].statusCode == 200) {
        final data = jsonDecode(responses[2].body);
        final matchesRaw = data['response']?['matches'] ?? data['matches'] ?? [];
        final matches = matchesRaw is List ? matchesRaw : [];
        for (var m in matches) {
          final statusObj = m['status'] ?? {};
          final isFinished = statusObj['finished'] ?? false;
          if (!isFinished) {
            final t1 = m['home']?['name'] ?? 'Home';
            final t2 = m['away']?['name'] ?? 'Away';
            final matchId = m['id']?.toString() ?? m['matchId']?.toString() ?? 'unknown';
            final notStarted = m['notStarted'] ?? false;
            final tournamentName = m['tournamentName'] ?? 'FIFA World Cup 2026';
            rooms.add({
              'id': 'football_$matchId',
              'name': '$t1 vs $t2 - $tournamentName',
              'sport': 'Football',
              'status': notStarted ? 'PREVIEW' : 'LIVE',
              'details': statusObj['reason']?['long'] ?? '$tournamentName Discussion',
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching matches for chat rooms, using fallbacks: $e');
    }

    // Dynamic fallback so list is never empty
    if (rooms.isEmpty) {
      rooms.addAll([
        {
          'id': 'cricket_mock_1',
          'name': 'RCB vs GT - Live Discussion',
          'sport': 'Cricket',
          'status': 'LIVE',
          'details': 'IPL 2026 - High momentum run chase discussion',
        },
        {
          'id': 'kabaddi_mock_2',
          'name': 'PAT vs MUM - Match 45 Chat',
          'sport': 'Kabaddi',
          'status': 'LIVE',
          'details': 'Pro Kabaddi League Season 11 discussion',
        },
        {
          'id': 'football_mock_3',
          'name': 'RM vs MC - Champions League Discussion',
          'sport': 'Football',
          'status': 'PREVIEW',
          'details': 'Match kicks off in 2 hours',
        }
      ]);
    }

    if (!mounted) return;
    setState(() {
      _chatRooms = rooms;
      _isLoadingRooms = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoadingRooms) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF7F)));
    }

    return RefreshIndicator(
      onRefresh: _fetchActiveRooms,
      color: const Color(0xFF00FF7F),
      backgroundColor: const Color(0xFF1E1E1E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chatRooms.length,
        itemBuilder: (context, index) {
          final room = _chatRooms[index];
          final sport = room['sport'] ?? 'General';
          final name = room['name'] ?? 'Discussion Room';
          final details = room['details'] ?? '';
          final status = room['status'] ?? 'LIVE';
          final isLive = status == 'LIVE';

          IconData sportIcon;
          Color sportColor;
          switch (sport.toLowerCase()) {
            case 'cricket':
              sportIcon = Icons.sports_cricket;
              sportColor = const Color(0xFF00FF7F);
              break;
            case 'football':
              sportIcon = Icons.sports_soccer;
              sportColor = Colors.blueAccent;
              break;
            case 'kabaddi':
              sportIcon = Icons.sports_kabaddi;
              sportColor = Colors.orangeAccent;
              break;
            default:
              sportIcon = Icons.sports;
              sportColor = Colors.grey;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLive ? Colors.redAccent.withValues(alpha: 0.4) : Colors.grey[850]!,
                width: isLive ? 1.5 : 1.0,
              ),
              boxShadow: isLive
                  ? [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.05), blurRadius: 10)]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: sportColor.withValues(alpha: 0.15),
                      radius: 18,
                      child: Icon(sportIcon, color: sportColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            details,
                            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLive
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          color: isLive ? Colors.redAccent : Colors.blueAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiveChatRoom(
                          roomId: room['id'],
                          roomName: name,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF7F),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'ENTER DISCUSSION',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ----------------- TAB 2: COMMUNITY FEED TAB -----------------
class CommunityFeedTab extends StatefulWidget {
  final String currentUserHandle;
  final String currentUserName;
  final String favoriteSports;
  final String favoritePlayers;
  final List<dynamic> currentUserBadges;

  const CommunityFeedTab({
    super.key,
    required this.currentUserHandle,
    required this.currentUserName,
    required this.favoriteSports,
    required this.favoritePlayers,
    required this.currentUserBadges,
  });

  @override
  State<CommunityFeedTab> createState() => _CommunityFeedTabState();
}

class _CommunityFeedTabState extends State<CommunityFeedTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<dynamic> _posts = [];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/community/posts'));
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _posts = jsonDecode(response.body);
          _isLoadingPosts = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingPosts = false);
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      if (!mounted) return;
      setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _toggleLike(String postId) async {
    setState(() {
      _posts = _posts.map((post) {
        if (post['id'] == postId) {
          final List<dynamic> likedBy = List.from(post['liked_by'] ?? []);
          int likes = post['likes'] ?? 0;
          if (likedBy.contains(widget.currentUserHandle)) {
            likedBy.remove(widget.currentUserHandle);
            likes = (likes > 0) ? likes - 1 : 0;
          } else {
            likedBy.add(widget.currentUserHandle);
            likes += 1;
          }
          return {
            ...post,
            'liked_by': likedBy,
            'likes': likes,
          };
        }
        return post;
      }).toList();
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/community/posts/$postId/like?handle=${Uri.encodeComponent(widget.currentUserHandle)}'),
      );
      if (response.statusCode == 200) {
        final updatedPost = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _posts = _posts.map((post) => post['id'] == postId ? updatedPost : post).toList();
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      _fetchPosts();
    }
  }

  Future<void> _submitVote(String postId, int optionIndex) async {
    // Optimistic Vote update locally
    setState(() {
      _posts = _posts.map((post) {
        if (post['id'] == postId && post['poll'] != null) {
          final poll = Map<String, dynamic>.from(post['poll']);
          final List<dynamic> votes = List.from(poll['votes']);
          votes[optionIndex] = (votes[optionIndex] as int) + 1;
          poll['votes'] = votes;
          poll['userVotedIndex'] = optionIndex;
          return {
            ...post,
            'poll': poll,
          };
        }
        return post;
      }).toList();
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/community/posts/$postId/vote?index=$optionIndex&handle=${Uri.encodeComponent(widget.currentUserHandle)}'),
      );
      if (response.statusCode == 200) {
        final updatedPost = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _posts = _posts.map((post) => post['id'] == postId ? updatedPost : post).toList();
        });
      }
    } catch (e) {
      debugPrint('Error submitting vote: $e');
      _fetchPosts();
    }
  }

  Future<void> _submitPost({
    required String content,
    Map<String, dynamic>? poll,
    Map<String, dynamic>? lineup,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/community/posts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': widget.currentUserName,
          'handle': widget.currentUserHandle,
          'content': content,
          'poll': poll,
          'lineup': lineup,
          'badges': widget.currentUserBadges,
        }),
      );

      if (response.statusCode == 200) {
        final newPost = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _posts.insert(0, newPost);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post published successfully!', style: GoogleFonts.inter(color: Colors.black)),
            backgroundColor: const Color(0xFF00FF7F),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
    }
  }

  Future<void> _submitComment(String postId, String commentText, StateSetter modalSetState) async {
    if (commentText.trim().isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/community/posts/$postId/comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': widget.currentUserName,
          'handle': widget.currentUserHandle,
          'content': commentText,
        }),
      );

      if (response.statusCode == 200) {
        final updatedPost = jsonDecode(response.body);
        
        try {
          modalSetState(() {
            _posts = _posts.map((post) {
              if (post['id'] == postId) return updatedPost;
              return post;
            }).toList();
          });
        } catch (e) {
          debugPrint('Error updating modal sheet state: $e');
        }

        if (!mounted) return;
        setState(() {
          _posts = _posts.map((post) {
            if (post['id'] == postId) return updatedPost;
            return post;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF7F)));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _fetchPosts,
        color: const Color(0xFF00FF7F),
        backgroundColor: const Color(0xFF1E1E1E),
        child: _posts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forum_outlined, size: 64, color: Colors.grey[700]),
                    const SizedBox(height: 16),
                    Text(
                      'no_posts_yet'.tr(),
                      style: GoogleFonts.outfit(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'first_to_start_conversation'.tr(),
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length,
                separatorBuilder: (context, index) => Divider(color: Colors.grey[850]),
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return _buildFeedPost(post);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: const Color(0xFF00FF7F),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit_note, size: 28),
      ),
    );
  }

  Widget _buildFeedPost(dynamic post) {
    final String postId = post['id'].toString();
    final String name = post['name'] ?? 'Anonymous';
    final String handle = post['handle'] ?? '@anonymous';
    final String time = post['time'] ?? 'Just now';
    final String content = post['content'] ?? '';
    final int likesCount = post['likes'] ?? 0;
    final List<dynamic> likedBy = post['liked_by'] ?? [];
    final List<dynamic> comments = post['comments'] ?? [];
    final bool isLiked = likedBy.contains(widget.currentUserHandle);
    final List<dynamic> badges = post['badges'] ?? [];
    
    final Map<String, dynamic>? poll = post['poll'] != null ? Map<String, dynamic>.from(post['poll']) : null;
    final Map<String, dynamic>? lineup = post['lineup'] != null ? Map<String, dynamic>.from(post['lineup']) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DynamicUserAvatar(
            handle: handle,
            radius: 20,
            fallbackLetter: name.isNotEmpty ? name[0] : '?',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Name, Handle, Time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      handle,
                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    // Author Badges rendering
                    ...badges.map((badge) => _buildBadgeWidget(badge)),
                    const Spacer(),
                    Text(
                      time,
                      style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Content with custom hashtag highlighter
                _buildPostContent(content),

                // Inline Poll
                if (poll != null)
                  PollWidget(
                    question: poll['question'] ?? 'Poll Question',
                    options: List<String>.from(poll['options'] ?? []),
                    initialVotes: List<int>.from(poll['votes'] ?? []),
                    userVotedIndex: poll['userVotedIndex'] ?? -1,
                    onVote: (val) => _submitVote(postId, val),
                  ),

                // Attached Lineup
                if (lineup != null)
                  LineupPreviewWidget(lineup: lineup),
                
                const SizedBox(height: 14),
                
                // Interaction buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPostAction(
                      icon: Icons.chat_bubble_outline,
                      count: comments.length.toString(),
                      color: Colors.grey[500]!,
                      onTap: () => _showCommentsBottomSheet(post),
                    ),
                    _buildPostAction(
                      icon: Icons.repeat,
                      count: '4',
                      color: Colors.grey[500]!,
                      onTap: () {},
                    ),
                    _buildPostAction(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      count: likesCount.toString(),
                      color: isLiked ? Colors.redAccent : Colors.grey[500]!,
                      onTap: () => _toggleLike(postId),
                    ),
                    _buildPostAction(
                      icon: Icons.share_outlined,
                      count: '',
                      color: Colors.grey[500]!,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeWidget(dynamic badge) {
    if (badge is Map) {
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
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(left: 3),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.3), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconUrl.isNotEmpty) ...[
                  Image.network(
                    iconUrl,
                    width: 10,
                    height: 10,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.star,
                      size: 10,
                      color: Color(0xFF00FF7F),
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
                Text(
                  name,
                  style: GoogleFonts.inter(fontSize: 8, color: Colors.grey[300], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final badgeStr = badge.toString();
      return Tooltip(
        message: badgeStr,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(badgeStr),
                backgroundColor: const Color(0xFF00FF7F),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(left: 3),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[850]!, width: 0.5),
            ),
            child: Text(
              badgeStr,
              style: GoogleFonts.inter(fontSize: 8, color: Colors.grey[300], fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPostContent(String content) {
    final List<String> words = content.split(' ');
    final List<InlineSpan> spans = [];

    for (int i = 0; i < words.length; i++) {
      final String word = words[i];
      final String space = i == words.length - 1 ? '' : ' ';

      if (word.startsWith('#')) {
        spans.add(
          TextSpan(
            text: '$word$space',
            style: GoogleFonts.inter(color: const Color(0xFF00FF7F), fontWeight: FontWeight.bold),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '$word$space',
            style: GoogleFonts.inter(color: Colors.grey[300]),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(children: spans, style: const TextStyle(fontSize: 13.5, height: 1.4)),
    );
  }

  Widget _buildPostAction({
    required IconData icon,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            if (count.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                count,
                style: GoogleFonts.inter(
                  color: color == Colors.redAccent ? Colors.redAccent : Colors.grey[500],
                  fontSize: 11,
                  fontWeight: color == Colors.redAccent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreatePostDialog() {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool showPollInputs = false;
    final pollQuestionController = TextEditingController();
    final List<TextEditingController> optionControllers = [
      TextEditingController(text: 'Option 1'),
      TextEditingController(text: 'Option 2'),
    ];

    Map<String, dynamic>? attachedLineup;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 24.0),
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'new_arena_post'.tr().toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00FF7F),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.grey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: textController,
                                maxLines: 3,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                validator: (value) {
                                  if ((value == null || value.trim().isEmpty) && attachedLineup == null) {
                                    return 'Please enter some thoughts or attach a lineup';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "What's happening in sports today? Use #hashtags to tag...",
                                  hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Visual representation of attached lineup
                              if (attachedLineup != null)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C2C2C),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[850]!),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.sports, color: Color(0xFF00FF7F), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Attached: ${attachedLineup!['teamName']} (${attachedLineup!['sport']})',
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                                        onPressed: () {
                                          setDialogState(() {
                                            attachedLineup = null;
                                          });
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              if (attachedLineup != null) const SizedBox(height: 12),

                              // Interactive Poll fields
                              if (showPollInputs) ...[
                                const Divider(color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'POLL QUESTION',
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: pollQuestionController,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  validator: (value) {
                                    if (showPollInputs && (value == null || value.trim().isEmpty)) {
                                      return 'Please enter a poll question';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Enter question (e.g. Who wins?)',
                                    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                    isDense: true,
                                    filled: true,
                                    fillColor: const Color(0xFF2C2C2C),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'OPTIONS',
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: optionControllers.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    return TextFormField(
                                      controller: optionControllers[index],
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                      validator: (value) {
                                        if (showPollInputs && (value == null || value.trim().isEmpty)) {
                                          return 'Option cannot be empty';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Option ${index + 1}',
                                        hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                        isDense: true,
                                        filled: true,
                                        fillColor: const Color(0xFF2C2C2C),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                        suffixIcon: optionControllers.length > 2
                                            ? IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 16),
                                                onPressed: () {
                                                  setDialogState(() {
                                                    optionControllers.removeAt(index);
                                                  });
                                                },
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                                if (optionControllers.length < 4) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        optionControllers.add(TextEditingController(text: 'Option ${optionControllers.length + 1}'));
                                      });
                                    },
                                    icon: const Icon(Icons.add, size: 16, color: Color(0xFF00FF7F)),
                                    label: Text(
                                      'Add Option',
                                      style: GoogleFonts.inter(color: const Color(0xFF00FF7F), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Attachment triggers
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.poll_outlined,
                              color: showPollInputs ? const Color(0xFF00FF7F) : Colors.grey,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                showPollInputs = !showPollInputs;
                              });
                            },
                            tooltip: 'Add Voting Poll',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.sports_score,
                              color: attachedLineup != null ? const Color(0xFF00FF7F) : Colors.grey,
                            ),
                            onPressed: () async {
                              final result = await showDialog<Map<String, dynamic>>(
                                context: context,
                                builder: (context) => const LineupCreatorDialog(),
                              );
                              if (result != null) {
                                setDialogState(() {
                                  attachedLineup = result;
                                });
                              }
                            },
                            tooltip: 'Attach Fantasy Team Lineup',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Map<String, dynamic>? pollPayload;
                            if (showPollInputs) {
                              final opts = optionControllers.map((c) => c.text.trim()).where((opt) => opt.isNotEmpty).toList();
                              pollPayload = {
                                'question': pollQuestionController.text.trim(),
                                'options': opts,
                                'votes': List<int>.filled(opts.length, 0),
                                'userVotedIndex': -1,
                              };
                            }

                            _submitPost(
                              content: textController.text.trim(),
                              poll: pollPayload,
                              lineup: attachedLineup,
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF7F),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'post_to_arena'.tr().toUpperCase(),
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCommentsBottomSheet(dynamic initialPost) {
    final commentController = TextEditingController();
    final String postId = initialPost['id'].toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            final currentPost = _posts.firstWhere((p) => p['id'].toString() == postId, orElse: () => initialPost);
            final List<dynamic> comments = currentPost['comments'] ?? [];

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 16,
                right: 16,
              ),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'COMMENTS',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00FF7F),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${comments.length} comments',
                        style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 8),
                  Expanded(
                    child: comments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mode_comment_outlined, size: 40, color: Colors.grey[800]),
                                const SizedBox(height: 8),
                                Text(
                                  'No comments yet',
                                  style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              final String cName = comment['name'] ?? 'Anonymous';
                              final String cHandle = comment['handle'] ?? '@anonymous';
                              final String cContent = comment['content'] ?? '';
                              final String cTime = comment['time'] ?? 'Just now';

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DynamicUserAvatar(
                                      handle: cHandle,
                                      radius: 14,
                                      fallbackLetter: cName.isNotEmpty ? cName[0] : '?',
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                cName,
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                cHandle,
                                                style: GoogleFonts.inter(
                                                  color: Colors.grey[600],
                                                  fontSize: 9,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                cTime,
                                                style: GoogleFonts.inter(
                                                  color: Colors.grey[600],
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            cContent,
                                            style: GoogleFonts.inter(
                                              color: Colors.grey[300],
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(color: Colors.grey),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey[850]!),
                            ),
                            child: TextField(
                              controller: commentController,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Share your sports review...',
                                hintStyle: GoogleFonts.inter(color: Colors.grey[650], fontSize: 13),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          backgroundColor: const Color(0xFF00FF7F),
                          radius: 22,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.black, size: 18),
                            onPressed: () {
                              if (commentController.text.trim().isNotEmpty) {
                                _submitComment(postId, commentController.text.trim(), modalSetState);
                                commentController.clear();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ----------------- TAB 3: SPORTS NEWS TAB -----------------
class SportsNewsTab extends StatefulWidget {
  final String favoriteSports;
  final String favoritePlayers;

  const SportsNewsTab({
    super.key,
    required this.favoriteSports,
    required this.favoritePlayers,
  });

  @override
  State<SportsNewsTab> createState() => _SportsNewsTabState();
}

class _SportsNewsTabState extends State<SportsNewsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<dynamic> _news = [];
  bool _isLoadingNews = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _launchArticleUrl(String urlString) async {
    if (urlString.isEmpty) return;
    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch URL: $urlString');
      }
    } catch (e) {
      debugPrint('Error launching news URL: $e');
    }
  }

  Future<void> _fetchNews() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/community/news').replace(queryParameters: {
        if (widget.favoriteSports.isNotEmpty) 'sports': widget.favoriteSports,
        if (widget.favoritePlayers.isNotEmpty) 'players': widget.favoritePlayers,
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _news = jsonDecode(response.body);
          _isLoadingNews = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingNews = false);
      }
    } catch (e) {
      debugPrint('Error fetching news: $e');
      if (!mounted) return;
      setState(() => _isLoadingNews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoadingNews) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF7F)));
    }

    final filteredNews = _news.where((item) {
      if (_selectedFilter == 'All') return true;
      final category = item['category']?.toString().toLowerCase() ?? '';
      return category == _selectedFilter.toLowerCase();
    }).toList();

    return Column(
      children: [
        // Horizontal Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: ['All', 'Cricket', 'Kabaddi', 'Football'].map((sport) {
              final isSel = _selectedFilter == sport;
              final displayLabel = sport == 'All' ? 'all'.tr() : sport;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(displayLabel),
                  selected: isSel,
                  labelStyle: GoogleFonts.inter(
                    color: isSel ? Colors.black : Colors.grey[400],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  selectedColor: const Color(0xFF00FF7F),
                  backgroundColor: const Color(0xFF1E1E1E),
                  checkmarkColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSel ? const Color(0xFF00FF7F) : Colors.grey[850]!),
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedFilter = sport;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // News List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchNews,
            color: const Color(0xFF00FF7F),
            backgroundColor: const Color(0xFF1E1E1E),
            child: filteredNews.isEmpty
                ? Center(
                    child: Text(
                      'No sports news currently available.',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredNews.length,
                    itemBuilder: (context, index) {
                      final newsItem = filteredNews[index];
                      final title = newsItem['title'] ?? 'Sports Update';
                      final summary = newsItem['summary'] ?? '';
                      final category = newsItem['category'] ?? 'General';
                      final time = newsItem['time'] ?? '';
                      final imageUrl = newsItem['imageUrl'];
                      final link = newsItem['link'] ?? '';

                      return InkWell(
                        onTap: () => _launchArticleUrl(link),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[850]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 16:9 Thumbnail Image
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => _buildDefaultNewsPlaceholder(category),
                                            )
                                          : _buildDefaultNewsPlaceholder(category),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.8),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00FF7F),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            category.toUpperCase(),
                                            style: GoogleFonts.inter(
                                              color: Colors.black,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Headline and content layout with overflow controls
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      summary,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: Colors.grey[400],
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.access_time_filled, size: 12, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              time,
                                              style: GoogleFonts.inter(
                                                fontSize: 10.5,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextButton.icon(
                                          onPressed: () => _launchArticleUrl(link),
                                          icon: const Text('Read More', style: TextStyle(fontSize: 11, color: Color(0xFF00FF7F))),
                                          label: const Icon(Icons.arrow_forward, size: 12, color: Color(0xFF00FF7F)),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }


  Widget _buildDefaultNewsPlaceholder(String category) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'football':
        icon = Icons.sports_soccer;
        break;
      case 'cricket':
        icon = Icons.sports_cricket;
        break;
      case 'kabaddi':
        icon = Icons.sports_kabaddi;
        break;
      default:
        icon = Icons.sports;
    }
    return Container(
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: Icon(icon, size: 48, color: const Color(0xFF00FF7F).withValues(alpha: 0.3)),
      ),
    );
  }
}
