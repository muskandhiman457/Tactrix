import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dynamic_user_avatar.dart';

class LiveChatRoom extends StatefulWidget {
  final String roomId;
  final String roomName;

  const LiveChatRoom({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<LiveChatRoom> createState() => _LiveChatRoomState();
}

class _LiveChatRoomState extends State<LiveChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _showEmojiPicker = false;
  bool _useLocalFallback = false;

  // Active user details
  String _senderName = 'Sports Fan';
  String _senderHandle = '@sports_fan';
  String? _senderProfilePic;
  List<dynamic> _senderBadges = ['⚡ Rookie'];

  // Local fallback list of messages for offline or permission issues
  final List<Map<String, dynamic>> _localMessages = [];

  final List<String> _emojis = [
    '😀', '😂', '😍', '😭', '👍', '🔥', '😮', '👏',
    '🎉', '❤️', '🙌', '💯', '👑', '🏏', '⚽', '🦁'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _setupLocalDummyMessages();
  }

  void _setupLocalDummyMessages() {
    _localMessages.addAll([
      {
        'id': 'msg_dummy_1',
        'senderName': 'Amit Patel',
        'senderHandle': '@amit_p',
        'senderProfilePic': null,
        'senderBadges': ['🏏 Fan', '🛡️ Analyst'],
        'content': 'This match is getting extremely intense! What a performance by the opening batters! 🏏🔥',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
        'reactions': {'👍': ['@rohan_cricket'], '🔥': ['@rohan_cricket']}
      },
      {
        'id': 'msg_dummy_2',
        'senderName': 'Rohan Sharma',
        'senderHandle': '@rohan_cricket',
        'senderProfilePic': null,
        'senderBadges': ['👑 Expert'],
        'content': 'Fully agree. That over-by-over momentum shift prediction is completely matching the actual play.',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 3)).millisecondsSinceEpoch,
        'reactions': {'👏': ['@amit_p']}
      },
      {
        'id': 'msg_dummy_3',
        'senderName': 'Sarah Jenkins',
        'senderHandle': '@sjenkins_sports',
        'senderProfilePic': null,
        'senderBadges': ['⚽ Fan', '📸 Contributor'],
        'content': 'Unbelievable strategy choice. Let\'s see how they execute the death overs!',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch,
        'reactions': {}
      }
    ]);
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final String name = data['name'] ?? user.displayName ?? 'Sports Fan';
        final String handle = data['username'] ?? '';
        final String? profilePic = data['profilePicture'];
        
        // Dynamic badges based on profile completeness and favorites
        final List<String> autoBadges = [];
        final String sports = data['sports'] ?? '';
        final String teams = data['teams'] ?? '';
        final String players = data['players'] ?? '';

        if (sports.isNotEmpty && teams.isNotEmpty && players.isNotEmpty) {
          autoBadges.add('🛡️ Analyst');
        }
        if (profilePic != null) {
          autoBadges.add('📸 Contributor');
        }
        if (sports.contains('Cricket')) autoBadges.add('🏏 Fan');
        if (sports.contains('Football')) autoBadges.add('⚽ Fan');
        if (sports.contains('Kabaddi')) autoBadges.add('🦁 Fan');

        // Check if manual badges exist
        final List<dynamic> manualBadges = data['badges'] ?? [];
        
        // Merge them uniquely by checking if name or string is already present
        final List<dynamic> finalBadges = [];
        final Set<String> seenNames = {};

        void addUniqueBadge(dynamic b) {
          String badgeName = '';
          if (b is Map) {
            badgeName = b['badge_name'] ?? '';
          } else {
            badgeName = b.toString();
          }
          if (badgeName.isNotEmpty && !seenNames.contains(badgeName)) {
            seenNames.add(badgeName);
            finalBadges.add(b);
          }
        }

        for (var b in manualBadges) {
          addUniqueBadge(b);
        }
        for (var b in autoBadges) {
          addUniqueBadge(b);
        }

        final cleanHandle = handle.isNotEmpty ? '@$handle' : '@sports_fan';
        if (cleanHandle == '@sports_fan' || cleanHandle == '@admin') {
          addUniqueBadge('👑 Expert');
        }

        if (finalBadges.isEmpty) {
          addUniqueBadge('⚡ Rookie');
        }

        if (!mounted) return;
        setState(() {
          _senderName = name;
          _senderHandle = cleanHandle;
          _senderProfilePic = profilePic;
          _senderBadges = finalBadges;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile for chat: $e');
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    // Hide picker after sending
    setState(() {
      _showEmojiPicker = false;
    });

    final messageData = {
      'senderId': FirebaseAuth.instance.currentUser?.uid ?? 'guest',
      'senderName': _senderName,
      'senderHandle': _senderHandle,
      'senderProfilePic': _senderProfilePic,
      'senderBadges': _senderBadges,
      'content': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'reactions': {},
    };

    if (_useLocalFallback) {
      setState(() {
        messageData['id'] = 'msg_local_${DateTime.now().millisecondsSinceEpoch}';
        _localMessages.add(messageData);
      });
      _scrollToBottom();
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId)
          .collection('messages')
          .add(messageData);
      _scrollToBottom();
    } catch (e) {
      debugPrint('Firestore failed to send, falling back to local chat: $e');
      setState(() {
        _useLocalFallback = true;
        messageData['id'] = 'msg_local_${DateTime.now().millisecondsSinceEpoch}';
        _localMessages.add(messageData);
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        // Unfocus keyboard if open
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _addReaction(String messageId, String emoji) async {
    if (_useLocalFallback) {
      setState(() {
        final index = _localMessages.indexWhere((m) => m['id'] == messageId);
        if (index != -1) {
          final Map<String, dynamic> msg = _localMessages[index];
          final Map<String, dynamic> reactions = Map<String, dynamic>.from(msg['reactions'] ?? {});
          final List<dynamic> users = List<dynamic>.from(reactions[emoji] ?? []);
          
          if (users.contains(_senderHandle)) {
            users.remove(_senderHandle);
          } else {
            users.add(_senderHandle);
          }
          
          if (users.isEmpty) {
            reactions.remove(emoji);
          } else {
            reactions[emoji] = users;
          }
          
          msg['reactions'] = reactions;
        }
      });
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.roomId)
          .collection('messages')
          .doc(messageId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final Map<String, dynamic> reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
        final List<dynamic> users = List<dynamic>.from(reactions[emoji] ?? []);

        if (users.contains(_senderHandle)) {
          users.remove(_senderHandle);
        } else {
          users.add(_senderHandle);
        }

        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }

        transaction.update(docRef, {'reactions': reactions});
      });
    } catch (e) {
      debugPrint('Firestore reaction transaction failed, updating locally: $e');
      // Set to local fallback on write failure
      setState(() {
        _useLocalFallback = true;
        // Apply locally
        final index = _localMessages.indexWhere((m) => m['id'] == messageId);
        if (index != -1) {
          final Map<String, dynamic> msg = _localMessages[index];
          final Map<String, dynamic> reactions = Map<String, dynamic>.from(msg['reactions'] ?? {});
          final List<dynamic> users = List<dynamic>.from(reactions[emoji] ?? []);
          if (users.contains(_senderHandle)) {
            users.remove(_senderHandle);
          } else {
            users.add(_senderHandle);
          }
          if (users.isEmpty) {
            reactions.remove(emoji);
          } else {
            reactions[emoji] = users;
          }
          msg['reactions'] = reactions;
        }
      });
    }
  }

  void _showReactionSheet(String messageId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quick Reactions',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['👍', '🔥', '😮', '👏'].map((emoji) {
                    return InkWell(
                      onTap: () {
                        _addReaction(messageId, emoji);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[850]!),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomName,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Color(0xFF00FF7F), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE CHAT',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF00FF7F), fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Stream
            Expanded(
              child: _useLocalFallback
                  ? _buildLocalChatStream()
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chat_rooms')
                          .doc(widget.roomId)
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          // Fail silently to local fallback
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _useLocalFallback = true;
                            });
                          });
                          return _buildLocalChatStream();
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF7F)));
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          reverse: true,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            data['id'] = doc.id;
                            return _buildChatBubble(data);
                          },
                        );
                      },
                    ),
            ),

            // Input panel
            _buildInputBar(),

            // Emoji selector grid
            if (_showEmojiPicker) _buildEmojiPickerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text(
            'No messages yet',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Start the discussion on this match!',
            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalChatStream() {
    // Reverse local list for standard bottom-up representation
    final reversedLocal = _localMessages.reversed.toList();

    if (reversedLocal.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      reverse: true,
      itemCount: reversedLocal.length,
      itemBuilder: (context, index) {
        final data = reversedLocal[index];
        return _buildChatBubble(data);
      },
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> message) {
    final String msgId = message['id'] ?? '';
    final String senderName = message['senderName'] ?? 'Anonymous';
    final String senderHandle = message['senderHandle'] ?? '@anonymous';
    final String content = message['content'] ?? '';
    final List<dynamic> badges = message['senderBadges'] ?? [];
    final Map<String, dynamic> reactions = Map<String, dynamic>.from(message['reactions'] ?? {});

    final isMe = message['senderId'] == (FirebaseAuth.instance.currentUser?.uid ?? 'guest');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(senderHandle, senderName, 13),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Header (Name + Handle + Badges)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                    ),
                    Text(
                      senderHandle,
                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 9),
                    ),
                    // Badges rendering
                    ...badges.map((badge) => _buildBadgeWidget(badge)),
                  ],
                ),
                const SizedBox(height: 4),
                // Message Bubble with Long-Press Reactions
                GestureDetector(
                  onLongPress: () => _showReactionSheet(msgId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF00FF7F).withValues(alpha: 0.15) : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: isMe ? const Radius.circular(14) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(14),
                      ),
                      border: Border.all(
                        color: isMe ? const Color(0xFF00FF7F).withValues(alpha: 0.3) : Colors.grey[850]!,
                      ),
                    ),
                    child: Text(
                      content,
                      style: GoogleFonts.inter(color: Colors.grey[200], fontSize: 13, height: 1.3),
                    ),
                  ),
                ),
                // Reactions Display below bubble
                if (reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Wrap(
                      spacing: 4,
                      children: reactions.entries.map((entry) {
                        final emoji = entry.key;
                        final List<dynamic> users = entry.value;
                        final didIReact = users.contains(_senderHandle);

                        return GestureDetector(
                          onTap: () => _addReaction(msgId, emoji),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: didIReact
                                  ? const Color(0xFF00FF7F).withValues(alpha: 0.15)
                                  : const Color(0xFF232323),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: didIReact ? const Color(0xFF00FF7F).withValues(alpha: 0.4) : Colors.grey[850]!,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 10)),
                                const SizedBox(width: 3),
                                Text(
                                  users.length.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: didIReact ? const Color(0xFF00FF7F) : Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(_senderHandle, _senderName, 13),
          ],
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

  Widget _buildAvatar(String handle, String name, double radius) {
    return DynamicUserAvatar(
      handle: handle,
      radius: radius,
      fallbackLetter: name.isNotEmpty ? name[0] : '?',
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.grey[850]!)),
      ),
      child: Row(
        children: [
          // Emoji Button
          IconButton(
            icon: Icon(
              _showEmojiPicker ? Icons.keyboard : Icons.sentiment_satisfied_alt,
              color: const Color(0xFF00FF7F),
            ),
            onPressed: _toggleEmojiPicker,
          ),
          
          // Field Input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[850]!),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                onTap: () {
                  // Hide picker when typing
                  setState(() {
                    _showEmojiPicker = false;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Send Button
          CircleAvatar(
            backgroundColor: const Color(0xFF00FF7F),
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.black, size: 16),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPickerWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.grey[850]!)),
      ),
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _emojis.length,
        itemBuilder: (context, index) {
          final emoji = _emojis[index];
          return InkWell(
            onTap: () {
              final text = _messageController.text;
              final val = text + emoji;
              _messageController.text = val;
            },
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}
