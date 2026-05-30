import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_config.dart';

// Base API configuration. If testing on a physical device, replace 'localhost' with your computer's local IP address (e.g., '192.168.1.5').
const String _baseUrl = ApiConfig.baseUrl;

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<dynamic> _posts = [];
  List<dynamic> _news = [];
  bool _isLoadingPosts = true;
  bool _isLoadingNews = true;
  bool _isLoadingProfile = true;

  String _currentUserHandle = "@sports_fan";
  String _currentUserName = "Sports Fan";
  String _favoriteSports = "";
  String _favoritePlayers = "";

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
      _fetchPosts();
      _fetchNews();
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
          _isLoadingProfile = false;
        });
      } else {
        // Document does not exist, initialize default profile
        final uid = user.uid;
        final suffix = uid.length >= 5 ? uid.substring(uid.length - 5) : uid;
        final tempUsername = 'fan_$suffix'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');

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
          _currentUserName = user.displayName ?? 'Sports Fan';
          _currentUserHandle = '@$tempUsername';
          _favoriteSports = 'Cricket, Football';
          _favoritePlayers = 'Virat Kohli, Lionel Messi';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile in community: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
      });
    }

    // Now load posts and personalized news
    _fetchPosts();
    _fetchNews();
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/community/posts'));
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _posts = jsonDecode(response.body);
          _isLoadingPosts = false;
        });
      } else {
        debugPrint('Failed to load posts: ${response.statusCode}');
        if (!mounted) return;
        setState(() => _isLoadingPosts = false);
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      if (!mounted) return;
      setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _fetchNews() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/community/news').replace(queryParameters: {
        if (_favoriteSports.isNotEmpty) 'sports': _favoriteSports,
        if (_favoritePlayers.isNotEmpty) 'players': _favoritePlayers,
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _news = jsonDecode(response.body);
          _isLoadingNews = false;
        });
      } else {
        debugPrint('Failed to load news: ${response.statusCode}');
        if (!mounted) return;
        setState(() => _isLoadingNews = false);
      }
    } catch (e) {
      debugPrint('Error fetching news: $e');
      if (!mounted) return;
      setState(() => _isLoadingNews = false);
    }
  }

  Future<void> _toggleLike(String postId) async {
    // Optimistic UI update
    setState(() {
      _posts = _posts.map((post) {
        if (post['id'] == postId) {
          final List<dynamic> likedBy = List.from(post['liked_by'] ?? []);
          int likes = post['likes'] ?? 0;
          if (likedBy.contains(_currentUserHandle)) {
            likedBy.remove(_currentUserHandle);
            likes = (likes > 0) ? likes - 1 : 0;
          } else {
            likedBy.add(_currentUserHandle);
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
        Uri.parse('$_baseUrl/api/community/posts/$postId/like?handle=${Uri.encodeComponent(_currentUserHandle)}'),
      );
      if (response.statusCode == 200) {
        final updatedPost = jsonDecode(response.body);
        setState(() {
          _posts = _posts.map((post) => post['id'] == postId ? updatedPost : post).toList();
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Revert if API fails
      _fetchPosts();
    }
  }

  Future<void> _submitPost(String content) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/community/posts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _currentUserName,
          'handle': _currentUserHandle,
          'content': content,
        }),
      );

      if (response.statusCode == 200) {
        final newPost = jsonDecode(response.body);
        setState(() {
          _posts.insert(0, newPost);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Post published successfully!', style: GoogleFonts.inter(color: Colors.black)),
              backgroundColor: const Color(0xFF00FF7F),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
    }
  }

  Future<void> _submitComment(String postId, String commentText, StateSetter modalSetState) async {
    if (commentText.trim().isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/community/posts/$postId/comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _currentUserName,
          'handle': _currentUserHandle,
          'content': commentText,
        }),
      );

      if (response.statusCode == 200) {
        final updatedPost = jsonDecode(response.body);
        
        // Update both screens: modal sheet state and main feed state
        modalSetState(() {
          _posts = _posts.map((post) {
            if (post['id'] == postId) {
              return updatedPost;
            }
            return post;
          }).toList();
        });

        setState(() {
          _posts = _posts.map((post) {
            if (post['id'] == postId) {
              return updatedPost;
            }
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
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
        ),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          title: Text(
            'COMMUNITY HUB',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: const Color(0xFF00FF7F),
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFF00FF7F),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'SPORTS FEED'),
              Tab(text: 'LATEST NEWS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _loadUserProfile,
              color: const Color(0xFF00FF7F),
              backgroundColor: const Color(0xFF1E1E1E),
              child: _buildSportsFeed(),
            ),
            RefreshIndicator(
              onRefresh: _loadUserProfile,
              color: const Color(0xFF00FF7F),
              backgroundColor: const Color(0xFF1E1E1E),
              child: _buildNewsFeed(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreatePostDialog,
          backgroundColor: const Color(0xFF00FF7F),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.edit_note, size: 28),
        ),
      ),
    );
  }

  Widget _buildSportsFeed() {
    if (_isLoadingPosts) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: GoogleFonts.outfit(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to start the conversation!',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      separatorBuilder: (context, index) => Divider(color: Colors.grey[850]),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildFeedPost(post);
      },
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
    final bool isLiked = likedBy.contains(_currentUserHandle);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF00FF7F).withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.outfit(color: const Color(0xFF00FF7F), fontWeight: FontWeight.bold),
            ),
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
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      handle,
                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                    ),
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
                
                const SizedBox(height: 16),
                
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
      text: TextSpan(children: spans, style: const TextStyle(fontSize: 14, height: 1.4)),
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
                  fontSize: 12,
                  fontWeight: color == Colors.redAccent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewsFeed() {
    if (_isLoadingNews) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
      );
    }

    if (_news.isEmpty) {
      return Center(
        child: Text(
          'No sports news currently available.',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _news.length,
      itemBuilder: (context, index) {
        final newsItem = _news[index];
        final title = newsItem['title'] ?? 'Sports Update';
        final summary = newsItem['summary'] ?? '';
        final category = newsItem['category'] ?? 'General';
        final time = newsItem['time'] ?? '';
        final imageUrl = newsItem['imageUrl'];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[850]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // News Header Image with Fallback/Overlay
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
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
                      // Gradient overlay for sleek styling
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
                      // Category Badge
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
                              fontSize: 10,
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      summary,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[400],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time_filled, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Text('Read More', style: TextStyle(fontSize: 12, color: Color(0xFF00FF7F))),
                          label: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF00FF7F)),
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
              )
            ],
          ),
        );
      },
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
        child: Icon(icon, size: 60, color: const Color(0xFF00FF7F).withValues(alpha: 0.3)),
      ),
    );
  }

  void _showCreatePostDialog() {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 280),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'NEW ARENA POST',
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
                    child: TextFormField(
                      controller: textController,
                      maxLines: 4,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Post content cannot be empty';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "What's happening in sports today? Use #hashtags to tag sports...",
                        hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        _submitPost(textController.text.trim());
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF7F),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'POST TO ARENA',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            // Find current state of the post in the _posts list
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
                  // Title Header
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00FF7F),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${comments.length} comments',
                        style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 8),

                  // Comments List
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
                                  style: GoogleFonts.inter(color: Colors.grey[550], fontSize: 13),
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
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFF00FF7F).withValues(alpha: 0.12),
                                      child: Text(
                                        cName.isNotEmpty ? cName[0].toUpperCase() : '?',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF00FF7F),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                cHandle,
                                                style: GoogleFonts.inter(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                cTime,
                                                style: GoogleFonts.inter(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            cContent,
                                            style: GoogleFonts.inter(
                                              color: Colors.grey[300],
                                              fontSize: 12.5,
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

                  // Comment Input Bar
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
                              border: Border.all(color: Colors.grey[800]!),
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
