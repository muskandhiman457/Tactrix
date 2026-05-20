import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_screen.dart';
import 'analysis_screen.dart';
import 'community_screen.dart';
import 'match_detail_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreenPlaceholder(),
    const AnalysisScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[800]!, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: const Color(0xFF00FF7F),
          unselectedItemColor: Colors.grey[600],
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analysis'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Community'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}



class HomeScreenPlaceholder extends StatefulWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  State<HomeScreenPlaceholder> createState() => _HomeScreenPlaceholderState();
}

class _HomeScreenPlaceholderState extends State<HomeScreenPlaceholder> {
  List<dynamic> _cricketMatches = [];
  List<dynamic> _footballMatches = [];
  bool _isLoading = true;
  bool _isFootballLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveCricketMatches();
    _fetchFootballMatches();
  }

  /// Converts a Unix millisecond timestamp to IST (UTC+5:30).
  /// Returns formatted string like "20 May, 19:30 IST"
  String _toIST(dynamic msTimestamp) {
    if (msTimestamp == null) return '';
    try {
      final ms = msTimestamp is String ? int.parse(msTimestamp) : (msTimestamp as int);
      final utc = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      final ist = utc.add(const Duration(hours: 5, minutes: 30));
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final day   = ist.day.toString().padLeft(2, '0');
      final month = months[ist.month - 1];
      final hour  = ist.hour.toString().padLeft(2, '0');
      final min   = ist.minute.toString().padLeft(2, '0');
      return '$day $month, $hour:$min IST';
    } catch (_) {
      return '';
    }
  }

  Future<void> _fetchLiveCricketMatches() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/cricket/matches/live-and-upcoming'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // New endpoint returns {"status": "success", "matches": [...]}
          if (data['matches'] != null) {
            _cricketMatches = data['matches'] is List ? data['matches'] : [];
          } else {
            _cricketMatches = [];
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching cricket matches: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFootballMatches() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/football/matches/by-league?leagueid=42'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['response'] != null && data['response']['matches'] != null) {
            _footballMatches = data['response']['matches'];
          } else {
            _footballMatches = [];
          }
          _isFootballLoading = false;
        });
      } else {
        setState(() => _isFootballLoading = false);
      }
    } catch (e) {
      print('Error fetching football matches: $e');
      setState(() => _isFootballLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          title: Text(
            'SPORTS HUB',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: const Color(0xFF00FF7F),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00FF7F),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'CRICKET', icon: Icon(Icons.sports_cricket)),
              Tab(text: 'KABADDI', icon: Icon(Icons.sports_kabaddi)),
              Tab(text: 'FOOTBALL', icon: Icon(Icons.sports_soccer)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCricketTab(),
            _buildMockTab(context, 'Live & Upcoming Kabaddi Matches'),
            _buildFootballTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCricketTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF7F)));
    }

    if (_cricketMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_cricket, color: Colors.grey[700], size: 64),
            const SizedBox(height: 16),
            Text(
              'No Live or Upcoming Matches',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon for upcoming fixtures.',
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cricketMatches.length,
      itemBuilder: (context, index) {
        final match = _cricketMatches[index];
        final info = match['matchInfo'] ?? {};
        final team1 = info['team1']?['teamName'] ?? 'Team A';
        final team1Short = info['team1']?['teamSName'] ?? team1[0];
        final team2 = info['team2']?['teamName'] ?? 'Team B';
        final team2Short = info['team2']?['teamSName'] ?? team2[0];
        final matchStatus = info['status'] ?? 'Upcoming';
        final state = info['state'] ?? 'Preview';
        final venue = info['venueInfo']?['ground'] ?? 'Cricket Ground';
        final city = info['venueInfo']?['city'] ?? '';
        final format = info['matchFormat'] ?? '';
        final seriesName = match['_seriesName'] ?? info['seriesName'] ?? '';

        final isLive = state.toLowerCase() != 'preview' && state.toLowerCase() != 'complete';
        final isUpcoming = state.toLowerCase() == 'preview';

        // Format start time in IST for upcoming matches
        final startMs = info['startDate'];
        final istTime = startMs != null ? _toIST(startMs) : '';
        final displayStatus = isUpcoming && istTime.isNotEmpty
            ? 'Starts $istTime'
            : (isLive ? '● LIVE — $state' : matchStatus);

        // Extract scores (Cricbuzz format)
        String t1Score = '';
        final t1Inngs1 = match['matchScore']?['team1Score']?['inngs1'];
        if (t1Inngs1 != null) {
          final runs = t1Inngs1['runs'];
          final wkts = t1Inngs1['wickets'] ?? 0;
          final overs = t1Inngs1['overs'];
          t1Score = '$runs/$wkts${overs != null ? ' ($overs)' : ''}';
        }

        String t2Score = '';
        final t2Inngs1 = match['matchScore']?['team2Score']?['inngs1'];
        if (t2Inngs1 != null) {
          final runs = t2Inngs1['runs'];
          final wkts = t2Inngs1['wickets'] ?? 0;
          final overs = t2Inngs1['overs'];
          t2Score = '$runs/$wkts${overs != null ? ' ($overs)' : ''}';
        }

        final scoreText = (t1Score.isEmpty && t2Score.isEmpty) ? 'VS' : '$t1Score / $t2Score';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchDetailScreen(
                  homeTeam: team1,
                  awayTeam: team2,
                  statusText: isLive ? '● LIVE - $state' : displayStatus,
                  scoreText: scoreText,
                  isLive: isLive,
                  venue: '$venue${city.isNotEmpty ? ', $city' : ''}',
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLive ? Colors.redAccent.withValues(alpha: 0.4) : Colors.grey[800]!,
                width: isLive ? 1.5 : 1.0,
              ),
              boxShadow: isLive
                  ? [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.08), blurRadius: 12, spreadRadius: 1)]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: badge + series name + format
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLive
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            isLive ? 'LIVE' : 'UPCOMING',
                            style: GoogleFonts.inter(
                              color: isLive ? Colors.redAccent : Colors.blueAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (format.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          format,
                          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                if (seriesName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    seriesName,
                    style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                // Team 1 row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey[800],
                      child: Text(
                        team1Short.isNotEmpty ? team1Short[0] : '?',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team1,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            team1Short,
                            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      t1Score.isNotEmpty ? t1Score : (isUpcoming ? '-' : '-'),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // VS divider
                Row(
                  children: [
                    const SizedBox(width: 38),
                    Expanded(child: Divider(color: Colors.grey[800], height: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'VS',
                        style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[800], height: 1)),
                  ],
                ),
                const SizedBox(height: 10),
                // Team 2 row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey[800],
                      child: Text(
                        team2Short.isNotEmpty ? team2Short[0] : '?',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team2,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            team2Short,
                            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      t2Score.isNotEmpty ? t2Score : (isUpcoming ? '-' : '-'),
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Status / venue footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayStatus,
                    style: GoogleFonts.inter(
                      color: isLive ? const Color(0xFF00FF7F) : (isUpcoming ? Colors.blueAccent[100] : Colors.grey[400]),
                      fontSize: 11,
                      fontWeight: isLive || isUpcoming ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (venue.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$venue${city.isNotEmpty ? ', $city' : ''}',
                          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFootballTab() {
    if (_isFootballLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF7F)));
    }
    
    // Filter to only include live or upcoming matches
    final activeMatches = _footballMatches.where((match) {
      final statusObj = match['status'];
      final isFinished = statusObj?['finished'] ?? false;
      return !isFinished;
    }).toList();

    if (activeMatches.isEmpty) {
      return Center(
        child: Text('No Live or Upcoming Matches Found', style: GoogleFonts.inter(color: Colors.white)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeMatches.length,
      itemBuilder: (context, index) {
        final match = activeMatches[index];
        final homeTeam = match['home']?['name'] ?? 'Home Team';
        final awayTeam = match['away']?['name'] ?? 'Away Team';
        final homeTeamId = match['home']?['id'];
        final awayTeamId = match['away']?['id'];
        
        final statusObj = match['status'];
        final isFinished = statusObj?['finished'] ?? false;
        final notStarted = match['notStarted'] ?? false;
        final statusText = statusObj?['reason']?['long'] ?? (notStarted ? 'Not Started' : 'Live');
        
        final homeScore = match['home']?['score']?.toString() ?? '-';
        final awayScore = match['away']?['score']?.toString() ?? '-';
        
        final homeLogoUrl = homeTeamId != null ? 'https://images.fotmob.com/image_resources/logo/teamlogo/$homeTeamId.png' : null;
        final awayLogoUrl = awayTeamId != null ? 'https://images.fotmob.com/image_resources/logo/teamlogo/$awayTeamId.png' : null;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchDetailScreen(
                  homeTeam: homeTeam,
                  awayTeam: awayTeam,
                  homeLogoUrl: homeLogoUrl,
                  awayLogoUrl: awayLogoUrl,
                  statusText: statusText.toUpperCase(),
                  scoreText: isFinished ? '$homeScore - $awayScore' : (notStarted ? 'VS' : '$homeScore - $awayScore'),
                  isLive: !isFinished && !notStarted,
                  venue: 'Champions League',
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFinished 
                            ? Colors.grey[800]!.withOpacity(0.4)
                            : (notStarted ? Colors.blueAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText.toUpperCase(), 
                        style: GoogleFonts.inter(
                          color: isFinished 
                              ? Colors.grey[400]
                              : (notStarted ? Colors.blueAccent : Colors.redAccent), 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    Text(
                      'Champions League',
                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    homeLogoUrl != null
                        ? Image.network(
                            homeLogoUrl,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                homeTeam.isNotEmpty ? homeTeam[0] : '?',
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey[800],
                            child: Text(
                              homeTeam.isNotEmpty ? homeTeam[0] : '?',
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        homeTeam, 
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, 
                          color: Colors.white,
                          fontSize: 14
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      homeScore, 
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: isFinished ? Colors.grey[400] : Colors.white,
                        fontSize: 14
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    awayLogoUrl != null
                        ? Image.network(
                            awayLogoUrl,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                awayTeam.isNotEmpty ? awayTeam[0] : '?',
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey[800],
                            child: Text(
                              awayTeam.isNotEmpty ? awayTeam[0] : '?',
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        awayTeam, 
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, 
                          color: Colors.white,
                          fontSize: 14
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      awayScore, 
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: isFinished ? Colors.grey[400] : Colors.white,
                        fontSize: 14
                      )
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMockTab(BuildContext context, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, style: GoogleFonts.inter(fontSize: 18, color: Colors.white)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MatchDetailScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF7F),
              foregroundColor: Colors.black,
            ),
            child: const Text('View Match Detail'),
          )
        ],
      ),
    );
  }
}
