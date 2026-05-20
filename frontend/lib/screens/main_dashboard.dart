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

  Future<void> _fetchLiveCricketMatches() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/cricket/matches/live'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          // Handle our mock format {"data": [...]}
          if (data['data'] != null) {
             _cricketMatches = data['data'] is List ? data['data'] : [data];
          } 
          // Handle Cricbuzz RapidAPI raw format {"typeMatches": [...]}
          else if (data['typeMatches'] != null) {
             List<dynamic> allMatches = [];
             for (var typeMatch in data['typeMatches']) {
               if (typeMatch['seriesMatches'] != null) {
                 for (var series in typeMatch['seriesMatches']) {
                   if (series['seriesAdWrapper'] != null && series['seriesAdWrapper']['matches'] != null) {
                     allMatches.addAll(series['seriesAdWrapper']['matches']);
                   }
                 }
               }
             }
             _cricketMatches = allMatches;
          } else {
             // Fallback if we just got a list or some unknown dict
             _cricketMatches = data is List ? data : [data];
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching matches: $e');
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
        child: Text('No Live Matches Found (or API error)', style: GoogleFonts.inter(color: Colors.white)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cricketMatches.length,
      itemBuilder: (context, index) {
        final match = _cricketMatches[index];
        // Handling both our mock format and a potential raw rapidapi format roughly
        final team1 = match['matchInfo']?['team1']?['teamName'] ?? match['team1']?['name'] ?? 'Team A';
        final team2 = match['matchInfo']?['team2']?['teamName'] ?? match['team2']?['name'] ?? 'Team B';
        final status = match['matchInfo']?['status'] ?? match['status'] ?? 'Live';
        
        // Extract scores if available (Cricbuzz format)
        String t1Score = '-';
        if (match['matchScore']?['team1Score']?['inngs1'] != null) {
          final runs = match['matchScore']['team1Score']['inngs1']['runs'];
          final wickets = match['matchScore']['team1Score']['inngs1']['wickets'] ?? 0;
          t1Score = '$runs/$wickets';
        }
        
        String t2Score = '-';
        if (match['matchScore']?['team2Score']?['inngs1'] != null) {
          final runs = match['matchScore']['team2Score']['inngs1']['runs'];
          final wickets = match['matchScore']['team2Score']['inngs1']['wickets'] ?? 0;
          t2Score = '$runs/$wickets';
        }
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchDetailScreen(
                  homeTeam: team1,
                  awayTeam: team2,
                  statusText: status,
                  scoreText: (t1Score == '-' && t2Score == '-') ? 'VS' : '$t1Score - $t2Score',
                  isLive: status.toUpperCase().contains('LIVE') || !status.toUpperCase().contains('WON'),
                  venue: match['matchInfo']?['venueInfo']?['ground'] ?? 'Cricket Ground',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Using a CircleAvatar as a placeholder until you add the flag assets!
                    CircleAvatar(radius: 12, backgroundColor: Colors.grey[800], child: Text(team1.isNotEmpty ? team1[0] : '?', style: const TextStyle(fontSize: 10, color: Colors.white))),
                    const SizedBox(width: 8),
                    Text(team1, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                    const Spacer(),
                    Text(t1Score, style: GoogleFonts.inter(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(radius: 12, backgroundColor: Colors.grey[800], child: Text(team2.isNotEmpty ? team2[0] : '?', style: const TextStyle(fontSize: 10, color: Colors.white))),
                    const SizedBox(width: 8),
                    Text(team2, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white60)),
                    const Spacer(),
                    Text(t2Score, style: GoogleFonts.inter(color: Colors.white60)),
                  ],
                ),
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
