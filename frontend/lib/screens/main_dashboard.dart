import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/api_config.dart';
import 'profile_screen.dart';
import 'analysis_screen.dart';
import 'community_screen.dart';
import 'match_detail_screen.dart';

String? getIplLogoAsset(String teamName) {
  final name = teamName.toLowerCase().trim();
  if (name.contains("chennai") || name.contains("super kings") || name.contains("csk")) {
    return "assets/logos/csk logo.png";
  } else if (name.contains("mumbai") || name == "mi" || name.contains("mumbai indians")) {
    return "assets/logos/MI logo.jpg";
  } else if (name.contains("royal challengers") || name.contains("rcb") || name.contains("bengaluru") || name.contains("bangalore")) {
    return "assets/logos/RCB logo.jpg";
  } else if (name.contains("kolkata") || name.contains("knight riders") || name.contains("kkr")) {
    return "assets/logos/kkr logo.jpg";
  } else if (name.contains("rajasthan") || name == "rr" || name.contains("rajasthan royals")) {
    return "assets/logos/Rajasthan royal.jpg";
  } else if (name.contains("delhi") || name == "dc" || name.contains("delhi capitals")) {
    return "assets/logos/delhi capitals logo.png";
  } else if (name.contains("punjab") || name.contains("kings xi") || name == "pbks" || name.contains("punjab kings")) {
    return "assets/logos/Punjab kings logo.jpg";
  } else if (name.contains("sunrisers") || name.contains("hyderabad") || name == "srh") {
    return "assets/logos/sunrisers hyderabad logo.png";
  } else if (name.contains("gujarat") || name == "gt" || name.contains("gujarat titans")) {
    return "assets/logos/GT logo.png";
  } else if (name.contains("lucknow") || name.contains("super giants") || name == "lsg") {
    return "assets/logos/LSG logo.jpg";
  }
  return null;
}

String? getKabaddiLogoAsset(String teamName) {
  final name = teamName.toLowerCase().trim();
  if (name.contains("patna") || name.contains("pirates") || name == "pat") {
    return "assets/logos/patna_pirates.png";
  } else if (name.contains("mumba") || name == "mum") {
    return "assets/logos/u_mumba.png";
  } else if (name.contains("jaipur") || name.contains("panthers") || name == "jai") {
    return "assets/logos/jaipur_pink_panthers.png";
  } else if (name.contains("bengaluru") || name.contains("bulls") || name == "blr") {
    return "assets/logos/bengaluru_bulls.png";
  } else if (name.contains("delhi") || name.contains("dabang") || name == "del") {
    return "assets/logos/dabang_delhi.png";
  } else if (name.contains("puneri") || name.contains("paltan") || name == "pun") {
    return "assets/logos/puneri_paltan.png";
  }
  return null;
}


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
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_filled), label: 'home'.tr()),
            BottomNavigationBarItem(icon: const Icon(Icons.analytics), label: 'analysis'.tr()),
            BottomNavigationBarItem(icon: const Icon(Icons.people_alt), label: 'community'.tr()),
            BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'profile'.tr()),
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
  List<dynamic> _kabaddiMatches = [];
  bool _isLoading = true;
  bool _isFootballLoading = true;
  bool _isKabaddiLoading = true;
  Timer? _liveMatchesTimer;

  @override
  void initState() {
    super.initState();
    _fetchLiveCricketMatches();
    _fetchFootballMatches();
    _fetchKabaddiMatches();
    _startLiveMatchesPolling();
  }

  void _startLiveMatchesPolling() {
    _liveMatchesTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchLiveCricketMatches();
        _fetchFootballMatches();
        _fetchKabaddiMatches();
      }
    });
  }

  @override
  void dispose() {
    _liveMatchesTimer?.cancel();
    super.dispose();
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
        Uri.parse('${ApiConfig.baseUrl}/api/cricket/matches/live-and-upcoming'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFootballMatches() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/football/matches/live-and-upcoming'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['matches'] != null) {
            _footballMatches = data['matches'] is List ? data['matches'] : [];
          } else if (data['response'] != null && data['response']['matches'] != null) {
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
      debugPrint('Error fetching football matches: $e');
      if (mounted) setState(() => _isFootballLoading = false);
    }
  }

  Future<void> _fetchKabaddiMatches() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/kabaddi/matches/live-and-upcoming'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['matches'] != null) {
            _kabaddiMatches = data['matches'] is List ? data['matches'] : [];
          } else {
            _kabaddiMatches = [];
          }
          _isKabaddiLoading = false;
        });
      } else {
        setState(() => _isKabaddiLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching kabaddi matches: $e');
      if (mounted) setState(() => _isKabaddiLoading = false);
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
            'app_title'.tr(),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: const Color(0xFF00FF7F),
            ),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF00FF7F),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'cricket'.tr().toUpperCase(), icon: const Icon(Icons.sports_cricket)),
              Tab(text: 'kabaddi'.tr().toUpperCase(), icon: const Icon(Icons.sports_kabaddi)),
              Tab(text: 'football'.tr().toUpperCase(), icon: const Icon(Icons.sports_soccer)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCricketTab(),
            _buildKabaddiTab(),
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
              'no_matches_found'.tr(),
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'check_back_soon'.tr(),
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

        // Cricket team image IDs for logo proxy
        final team1ImageId = info['team1']?['imageId'];
        final team2ImageId = info['team2']?['imageId'];
        final homeLogoUrl = team1ImageId != null
            ? '${ApiConfig.baseUrl}/api/cricket/img/team/$team1ImageId?teamName=${Uri.encodeComponent(team1)}'
            : null;
        final awayLogoUrl = team2ImageId != null
            ? '${ApiConfig.baseUrl}/api/cricket/img/team/$team2ImageId?teamName=${Uri.encodeComponent(team2)}'
            : null;

        final isLive = state.toLowerCase() != 'preview' && state.toLowerCase() != 'complete';
        final isUpcoming = state.toLowerCase() == 'preview';

        // Format start time in IST for upcoming matches
        final startMs = info['startDate'];
        final istTime = startMs != null ? _toIST(startMs) : '';
        final displayStatus = isUpcoming && istTime.isNotEmpty
            ? 'starts_at'.tr(namedArgs: {'time': istTime})
            : (isLive ? '● ${'live'.tr().toUpperCase()} — $state' : matchStatus);

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
            final matchId = info['matchId'];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchDetailScreen(
                  homeTeam: team1,
                  awayTeam: team2,
                  homeLogoUrl: homeLogoUrl,
                  awayLogoUrl: awayLogoUrl,
                  statusText: isLive ? '● LIVE - $state' : displayStatus,
                  scoreText: scoreText,
                  isLive: isLive,
                  venue: '$venue${city.isNotEmpty ? ', $city' : ''}',
                  isCricket: true,
                  matchId: matchId?.toString(),
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
                            isLive ? 'live'.tr().toUpperCase() : 'upcoming'.tr().toUpperCase(),
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
                    Builder(builder: (context) {
                      final iplAsset = getIplLogoAsset(team1);
                      if (iplAsset != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            iplAsset,
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        );
                      }
                      return homeLogoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                homeLogoUrl,
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.grey[800],
                                  child: Text(
                                    team1Short.isNotEmpty ? team1Short[0] : '?',
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                team1Short.isNotEmpty ? team1Short[0] : '?',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            );
                    }),
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
                    Builder(builder: (context) {
                      final iplAsset = getIplLogoAsset(team2);
                      if (iplAsset != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            iplAsset,
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        );
                      }
                      return awayLogoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                awayLogoUrl,
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.grey[800],
                                  child: Text(
                                    team2Short.isNotEmpty ? team2Short[0] : '?',
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                team2Short.isNotEmpty ? team2Short[0] : '?',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                            );
                    }),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, color: Colors.grey[700], size: 64),
            const SizedBox(height: 16),
            Text(
              'No Live or Upcoming Matches Found',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeMatches.length,
      itemBuilder: (context, index) {
        final match = activeMatches[index];
        final homeTeam = match['home']?['name'] ?? 'Home Team';
        final homeShort = match['home']?['short'] ?? homeTeam[0];
        final awayTeam = match['away']?['name'] ?? 'Away Team';
        final awayShort = match['away']?['short'] ?? awayTeam[0];
        final homeTeamId = match['home']?['id'];
        final awayTeamId = match['away']?['id'];
        
        final statusObj = match['status'];
        final isFinished = statusObj?['finished'] ?? false;
        final notStarted = match['notStarted'] ?? false;
        
        final homeScore = match['home']?['score']?.toString() ?? '0';
        final awayScore = match['away']?['score']?.toString() ?? '0';
        
        final homeLogoUrl = homeTeamId != null ? 'https://images.fotmob.com/image_resources/logo/teamlogo/$homeTeamId.png' : null;
        final awayLogoUrl = awayTeamId != null ? 'https://images.fotmob.com/image_resources/logo/teamlogo/$awayTeamId.png' : null;

        final tourneyName = match['tournamentName'] ?? 'FIFA World Cup 2026';
        final venue = match['venue'] ?? '';

        final isLive = !isFinished && !notStarted;
        final isUpcoming = notStarted;

        // Start time formatting
        final startMs = match['startDate'];
        final istTime = startMs != null ? _toIST(startMs) : '';
        final statusText = statusObj?['reason']?['long'] ?? (isLive ? 'Live' : 'Upcoming');
        
        final displayStatus = isUpcoming && istTime.isNotEmpty
            ? 'starts_at'.tr(namedArgs: {'time': istTime})
            : (isLive ? '● ${'live'.tr().toUpperCase()} — $statusText' : statusText);

        final scoreText = isFinished ? '$homeScore - $awayScore' : (isUpcoming ? 'VS' : '$homeScore - $awayScore');

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
                  statusText: isLive ? '● LIVE - $statusText' : displayStatus,
                  scoreText: scoreText,
                  isLive: isLive,
                  venue: venue,
                  isCricket: false,
                  isKabaddi: false,
                  matchId: match['id']?.toString(),
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
                // Header: Live/Upcoming badge + tournament name
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
                            isLive ? 'live'.tr().toUpperCase() : 'upcoming'.tr().toUpperCase(),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'FIFA WC',
                        style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tourneyName,
                  style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                // Home Team row
                Row(
                  children: [
                    homeLogoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              homeLogoUrl,
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey[800],
                                child: Text(
                                  homeShort.isNotEmpty ? homeShort[0] : '?',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey[800],
                            child: Text(
                              homeShort.isNotEmpty ? homeShort[0] : '?',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            homeTeam,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            homeShort,
                            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isUpcoming ? '-' : homeScore,
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
                // Away Team row
                Row(
                  children: [
                    awayLogoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              awayLogoUrl,
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey[800],
                                child: Text(
                                  awayShort.isNotEmpty ? awayShort[0] : '?',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey[800],
                            child: Text(
                              awayShort.isNotEmpty ? awayShort[0] : '?',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                            ),
                          ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            awayTeam,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            awayShort,
                            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isUpcoming ? '-' : awayScore,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Status footer
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
                          venue,
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

  Widget _buildKabaddiTab() {
    if (_isKabaddiLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF7F)));
    }

    if (_kabaddiMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_kabaddi, color: Colors.grey[700], size: 64),
            const SizedBox(height: 16),
            Text(
              'No Live or Upcoming Matches',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _kabaddiMatches.length,
      itemBuilder: (context, index) {
        final match = _kabaddiMatches[index];
        final info = match['matchInfo'] ?? {};
        final team1 = info['team1']?['teamName'] ?? 'Team A';
        final team1Short = info['team1']?['teamSName'] ?? 'T1';
        final team2 = info['team2']?['teamName'] ?? 'Team B';
        final team2Short = info['team2']?['teamSName'] ?? 'T2';
        final state = info['state'] ?? 'Preview';
        final isLive = state.toLowerCase() == 'live';
        final statusText = info['status'] ?? '';
        final venue = '${info['venueInfo']?['ground'] ?? ''}, ${info['venueInfo']?['city'] ?? ''}';
        
        final homeScore = info['team1']?['score']?.toString() ?? '-';
        final awayScore = info['team2']?['score']?.toString() ?? '-';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchDetailScreen(
                  homeTeam: team1,
                  awayTeam: team2,
                  statusText: statusText.toUpperCase(),
                  scoreText: isLive ? '$homeScore - $awayScore' : 'VS',
                  isLive: isLive,
                  venue: venue,
                  isCricket: false,
                  isKabaddi: true,
                  matchId: info['matchId']?.toString(),
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
                      child: Text(
                        isLive ? 'LIVE' : 'UPCOMING',
                        style: GoogleFonts.inter(
                          color: isLive ? Colors.redAccent : Colors.blueAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'Pro Kabaddi League',
                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildKabaddiLogoAvatar(team1, team1Short, 14),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        team1,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      isLive ? homeScore : '-',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildKabaddiLogoAvatar(team2, team2Short, 14),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        team2,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      isLive ? awayScore : '-',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      color: isLive ? const Color(0xFF00FF7F) : Colors.grey[400],
                      fontSize: 11,
                      fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                    ),
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
                          venue,
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

  Widget _buildKabaddiLogoAvatar(String teamName, String teamSName, double radius) {
    final asset = getKabaddiLogoAsset(teamName);
    
    final fallbackAvatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: Text(
        teamSName.toUpperCase().trim().isNotEmpty ? teamSName.toUpperCase().trim()[0] : '?',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: radius - 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (asset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          asset,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => fallbackAvatar,
        ),
      );
    }
    
    return fallbackAvatar;
  }
}
