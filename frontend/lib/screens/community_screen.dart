import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            _buildSportsFeed(),
            _buildNewsFeed(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Open Create Post Dialog
          },
          backgroundColor: const Color(0xFF00FF7F),
          foregroundColor: Colors.black,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSportsFeed() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (context, index) => Divider(color: Colors.grey[800]),
      itemBuilder: (context, index) {
        return _buildFeedPost(
          name: 'Sarah Jenkins',
          handle: '@sjenkins_sports',
          time: '${index + 1}h ago',
          content: 'What an incredible match! The comeback in the second half was absolutely legendary. This is why we love the sport! ⚽🔥 #Football #Comeback',
          likes: (124 - (index * 12)).toString(),
          comments: (45 - (index * 4)).toString(),
        );
      },
    );
  }

  Widget _buildFeedPost({
    required String name,
    required String handle,
    required String time,
    required String content,
    required String likes,
    required String comments,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF00FF7F).withOpacity(0.2),
            child: const Icon(Icons.person, color: Color(0xFF00FF7F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      handle,
                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      time,
                      style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPostAction(Icons.chat_bubble_outline, comments),
                    _buildPostAction(Icons.repeat, '12'),
                    _buildPostAction(Icons.favorite_border, likes),
                    _buildPostAction(Icons.share, ''),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        if (count.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(count, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildNewsFeed() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BREAKING: Major Transfer Deal Agreed',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The highly anticipated transfer has finally been confirmed after weeks of negotiations between the top clubs.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '2 hours ago • Football',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF00FF7F),
                      ),
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
}
