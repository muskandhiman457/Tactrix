import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import '../services/api_config.dart';
import 'comparison_matrix_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  List<dynamic> _matches = [];
  bool _isLoadingMatches = true;
  Map<String, dynamic>? _selectedMatch;
  
  // H2H Selections
  String? _selectedPlayerA;
  String? _selectedPlayerB;
  List<Map<String, String>> _teamAPlayers = [];
  List<Map<String, String>> _teamBPlayers = [];

  // API State
  Map<String, dynamic>? _winPrediction;
  bool _isLoadingWinPrediction = false;
  Map<String, dynamic> _playerAContribution = {};
  Map<String, dynamic> _playerBContribution = {};
  bool _isLoadingPlayers = false;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/cricket/matches/live-and-upcoming'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['matches'] is List) {
          if (!mounted) return;
          setState(() {
            _matches = data['matches'];
            _isLoadingMatches = false;
            if (_matches.isNotEmpty) {
              _selectMatch(_matches[0]);
            }
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching matches in analysis: $e');
    }
    if (!mounted) return;
    setState(() => _isLoadingMatches = false);
  }

  void _selectMatch(Map<String, dynamic> match) {
    setState(() {
      _selectedMatch = match;
      _isLoadingPlayers = true;
    });
    
    final info = match['matchInfo'] ?? {};
    final matchId = info['matchId'];
    final team1 = info['team1']?['teamName'] ?? 'Team A';
    final team2 = info['team2']?['teamName'] ?? 'Team B';

    if (matchId != null) {
      _fetchPlayersForMatch(matchId, team1, team2);
    } else {
      setState(() {
        _teamAPlayers = _getPlayersForTeam(team1);
        _teamBPlayers = _getPlayersForTeam(team2);
        _selectedPlayerA = _teamAPlayers.isNotEmpty ? _teamAPlayers[0]['name'] : null;
        _selectedPlayerB = _teamBPlayers.isNotEmpty ? _teamBPlayers[0]['name'] : null;
        _isLoadingPlayers = false;
      });
      if (_selectedPlayerA != null) _fetchPlayerContribution(_selectedPlayerA!, true);
      if (_selectedPlayerB != null) _fetchPlayerContribution(_selectedPlayerB!, false);
    }
  }

  Future<void> _fetchWinPrediction(dynamic matchId) async {
    if (matchId == null) return;
    if (!mounted) return;
    setState(() => _isLoadingWinPrediction = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/analysis/predict-win/$matchId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _winPrediction = data['prediction'];
          _isLoadingWinPrediction = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error fetching win prediction: $e');
    }
    if (!mounted) return;
    setState(() {
      _winPrediction = null;
      _isLoadingWinPrediction = false;
    });
  }

  Future<void> _fetchPlayerContribution(String playerName, bool isPlayerA) async {
    try {
      final encodedName = Uri.encodeComponent(playerName);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/analysis/player-contribution/$encodedName'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          if (isPlayerA) {
            _playerAContribution = data;
          } else {
            _playerBContribution = data;
          }
        });
        return;
      }
    } catch (e) {
      debugPrint('Error fetching player contribution: $e');
    }
  }

  Future<void> _fetchPlayersForMatch(dynamic matchId, String team1, String team2) async {
    _fetchWinPrediction(matchId);
    final captains = {'MS Dhoni', 'Ruturaj Gaikwad', 'Rohit Sharma', 'Hardik Pandya', 'Virat Kohli', 'Faf du Plessis', 'Shreyas Iyer', 'Pat Cummins', 'Sanju Samson', 'Shubman Gill', 'Rishabh Pant', 'KL Rahul', 'Shikhar Dhawan', 'Sam Curran'};
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/cricket/match/$matchId/scorecard'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['teams'] != null) {
          final Map<String, dynamic> teamsData = data['teams'];
          
          List<Map<String, String>> teamAPlayersList = [];
          List<Map<String, String>> teamBPlayersList = [];

          // Try matching by team name
          String? keyA;
          String? keyB;
          teamsData.forEach((key, val) {
            final cleanedKey = key.toLowerCase().trim();
            if (cleanedKey.contains(team1.toLowerCase().trim()) || team1.toLowerCase().trim().contains(cleanedKey)) {
              keyA = key;
            }
            if (cleanedKey.contains(team2.toLowerCase().trim()) || team2.toLowerCase().trim().contains(cleanedKey)) {
              keyB = key;
            }
          });

          // Fallbacks if not matched by name
          if (keyA == null && teamsData.isNotEmpty) {
            keyA = teamsData.keys.first;
          }
          if (keyB == null && teamsData.length > 1) {
            keyB = teamsData.keys.elementAt(1);
          }

          if (keyA != null) {
            final tData = teamsData[keyA];
            final playingXI = tData['playingXI'] as List? ?? [];
            final bench = tData['bench'] as List? ?? [];
            final allPlayers = tData['players'] as List? ?? [];

            if (playingXI.isNotEmpty || bench.isNotEmpty) {
              for (var p in playingXI) {
                final isCap = p['captain'] == true || captains.contains(p['name']);
                teamAPlayersList.add({
                  'name': p['name'] ?? 'Unknown',
                  'role': p['role'] ?? 'Player',
                  'status': 'ACTIVE',
                  'isCaptain': isCap.toString(),
                });
              }
              for (var p in bench) {
                final isCap = p['captain'] == true || captains.contains(p['name']);
                teamAPlayersList.add({
                  'name': p['name'] ?? 'Unknown',
                  'role': p['role'] ?? 'Player',
                  'status': 'BENCH',
                  'isCaptain': isCap.toString(),
                });
              }
            } else {
              for (var p in allPlayers) {
                final isCap = p['captain'] == true || captains.contains(p['name']);
                teamAPlayersList.add({
                  'name': p['name'] ?? 'Unknown',
                  'role': p['role'] ?? 'Player',
                  'status': 'ACTIVE',
                  'isCaptain': isCap.toString(),
                });
              }
            }
          }

          if (keyB != null) {
            final tData = teamsData[keyB];
            final playingXI = tData['playingXI'] as List? ?? [];
            final bench = tData['bench'] as List? ?? [];
            final allPlayers = tData['players'] as List? ?? [];

            if (playingXI.isNotEmpty || bench.isNotEmpty) {
              for (var p in playingXI) {
                final isCap = p['captain'] == true || captains.contains(p['name']);
                teamBPlayersList.add({
                  'name': p['name'] ?? 'Unknown',
                  'role': p['role'] ?? 'Player',
                  'status': 'ACTIVE',
                  'isCaptain': isCap.toString(),
                });
              }
              for (var p in bench) {
                final isCap = p['captain'] == true || captains.contains(p['name']);
                teamBPlayersList.add({
                  'name': p['name'] ?? 'Unknown',
                  'role': p['role'] ?? 'Player',
                  'status': 'BENCH',
                  'isCaptain': isCap.toString(),
                });
              }
            } else {
              for (var p in allPlayers) {
                final isCap = p['captain'] == true || captains.contains(p['name']);
                teamBPlayersList.add({
                  'name': p['name'] ?? 'Unknown',
                  'role': p['role'] ?? 'Player',
                  'status': 'ACTIVE',
                  'isCaptain': isCap.toString(),
                });
              }
            }
          }

          // Sort so captains come first
          teamAPlayersList.sort((a, b) {
            final aCap = a['isCaptain'] == 'true' ? 1 : 0;
            final bCap = b['isCaptain'] == 'true' ? 1 : 0;
            return bCap.compareTo(aCap);
          });
          teamBPlayersList.sort((a, b) {
            final aCap = a['isCaptain'] == 'true' ? 1 : 0;
            final bCap = b['isCaptain'] == 'true' ? 1 : 0;
            return bCap.compareTo(aCap);
          });

          if (teamAPlayersList.isNotEmpty || teamBPlayersList.isNotEmpty) {
            if (!mounted) return;
            setState(() {
              _teamAPlayers = teamAPlayersList;
              _teamBPlayers = teamBPlayersList;
              _selectedPlayerA = _teamAPlayers.isNotEmpty ? _teamAPlayers[0]['name'] : null;
              _selectedPlayerB = _teamBPlayers.isNotEmpty ? _teamBPlayers[0]['name'] : null;
              _isLoadingPlayers = false;
            });
            if (_selectedPlayerA != null) _fetchPlayerContribution(_selectedPlayerA!, true);
            if (_selectedPlayerB != null) _fetchPlayerContribution(_selectedPlayerB!, false);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching players from scorecard: $e');
    }

    // Fallback if network call fails
    if (!mounted) return;
    setState(() {
      _teamAPlayers = _getPlayersForTeam(team1).map((p) => {
        'name': p['name'] ?? '',
        'role': p['role'] ?? '',
        'status': 'ACTIVE',
        'isCaptain': captains.contains(p['name']).toString(),
      }).toList();
      _teamBPlayers = _getPlayersForTeam(team2).map((p) => {
        'name': p['name'] ?? '',
        'role': p['role'] ?? '',
        'status': 'ACTIVE',
        'isCaptain': captains.contains(p['name']).toString(),
      }).toList();

      // Sort fallbacks so captains come first
      _teamAPlayers.sort((a, b) {
        final aCap = a['isCaptain'] == 'true' ? 1 : 0;
        final bCap = b['isCaptain'] == 'true' ? 1 : 0;
        return bCap.compareTo(aCap);
      });
      _teamBPlayers.sort((a, b) {
        final aCap = a['isCaptain'] == 'true' ? 1 : 0;
        final bCap = b['isCaptain'] == 'true' ? 1 : 0;
        return bCap.compareTo(aCap);
      });

      _selectedPlayerA = _teamAPlayers.isNotEmpty ? _teamAPlayers[0]['name'] : null;
      _selectedPlayerB = _teamBPlayers.isNotEmpty ? _teamBPlayers[0]['name'] : null;
      _isLoadingPlayers = false;
    });
    if (_selectedPlayerA != null) _fetchPlayerContribution(_selectedPlayerA!, true);
    if (_selectedPlayerB != null) _fetchPlayerContribution(_selectedPlayerB!, false);
  }

  String? getIplLogoAsset(String teamName) {
    final name = teamName.toLowerCase().trim();
    if (name.contains('chennai') || name.contains('super kings') || name.contains('csk')) return 'assets/logos/csk logo.png';
    if (name.contains('mumbai') || name.contains('mi') || name.contains('indians')) return 'assets/logos/MI logo.jpg';
    if (name.contains('royal challengers') || name.contains('rcb') || name.contains('bengaluru') || name.contains('bangalore')) return 'assets/logos/RCB logo.jpg';
    if (name.contains('kolkata') || name.contains('knight riders') || name.contains('kkr')) return 'assets/logos/kkr logo.jpg';
    if (name.contains('rajasthan') || name.contains('rr') || name.contains('royals')) return 'assets/logos/Rajasthan royal.jpg';
    if (name.contains('delhi') || name.contains('dc') || name.contains('capitals')) return 'assets/logos/delhi capitals logo.png';
    if (name.contains('punjab') || name.contains('kings') || name.contains('pbks')) return 'assets/logos/Punjab kings logo.jpg';
    if (name.contains('sunrisers') || name.contains('hyderabad') || name.contains('srh')) return 'assets/logos/sunrisers hyderabad logo.png';
    if (name.contains('gujarat') || name.contains('gt') || name.contains('titans')) return 'assets/logos/GT logo.png';
    if (name.contains('lucknow') || name.contains('super giants') || name.contains('lsg')) return 'assets/logos/LSG logo.jpg';
    return null;
  }

  List<Map<String, String>> _getPlayersForTeam(String teamName) {
    final cleaned = teamName.toLowerCase();
    if (cleaned.contains('chennai') || cleaned.contains('csk')) {
      return [
        {'name': 'MS Dhoni', 'role': 'Wicketkeeper-Batsman'},
        {'name': 'Ruturaj Gaikwad', 'role': 'Batsman'},
        {'name': 'Ravindra Jadeja', 'role': 'All-Rounder'},
        {'name': 'Shivam Dube', 'role': 'All-Rounder'},
        {'name': 'Matheesha Pathirana', 'role': 'Bowler'},
        {'name': 'Deepak Chahar', 'role': 'Bowler'},
        {'name': 'Ajinkya Rahane', 'role': 'Batsman'},
        {'name': 'Devon Conway', 'role': 'Batsman'},
        {'name': 'Mitchell Santner', 'role': 'All-Rounder'},
        {'name': 'Tushar Deshpande', 'role': 'Bowler'},
        {'name': 'Maheesh Theekshana', 'role': 'Bowler'},
      ];
    }
    if (cleaned.contains('mumbai') || cleaned.contains('mi')) {
      return [
        {'name': 'Rohit Sharma', 'role': 'Batsman'},
        {'name': 'Suryakumar Yadav', 'role': 'Batsman'},
        {'name': 'Hardik Pandya', 'role': 'All-Rounder'},
        {'name': 'Jasprit Bumrah', 'role': 'Bowler'},
        {'name': 'Ishan Kishan', 'role': 'Wicketkeeper-Batsman'},
        {'name': 'Tilak Varma', 'role': 'Batsman'},
        {'name': 'Tim David', 'role': 'Batsman'},
        {'name': 'Gerald Coetzee', 'role': 'Bowler'},
        {'name': 'Piyush Chawla', 'role': 'Bowler'},
        {'name': 'Akash Madhwal', 'role': 'Bowler'},
        {'name': 'Romario Shepherd', 'role': 'All-Rounder'},
      ];
    }
    if (cleaned.contains('royal challengers') || cleaned.contains('rcb') || cleaned.contains('bengaluru') || cleaned.contains('bangalore')) {
      return [
        {'name': 'Virat Kohli', 'role': 'Batsman'},
        {'name': 'Faf du Plessis', 'role': 'Batsman'},
        {'name': 'Glenn Maxwell', 'role': 'All-Rounder'},
        {'name': 'Mohammed Siraj', 'role': 'Bowler'},
        {'name': 'Dinesh Karthik', 'role': 'Wicketkeeper-Batsman'},
        {'name': 'Rajat Patidar', 'role': 'Batsman'},
        {'name': 'Will Jacks', 'role': 'All-Rounder'},
        {'name': 'Cameron Green', 'role': 'All-Rounder'},
        {'name': 'Lockie Ferguson', 'role': 'Bowler'},
        {'name': 'Yash Dayal', 'role': 'Bowler'},
        {'name': 'Karn Sharma', 'role': 'Bowler'},
      ];
    }
    if (cleaned.contains('kolkata') || cleaned.contains('kkr')) {
      return [
        {'name': 'Shreyas Iyer', 'role': 'Batsman'},
        {'name': 'Sunil Narine', 'role': 'All-Rounder'},
        {'name': 'Andre Russell', 'role': 'All-Rounder'},
        {'name': 'Rinku Singh', 'role': 'Batsman'},
        {'name': 'Mitchell Starc', 'role': 'Bowler'},
        {'name': 'Varun Chakaravarthy', 'role': 'Bowler'},
        {'name': 'Phil Salt', 'role': 'Wicketkeeper-Batsman'},
        {'name': 'Venkatesh Iyer', 'role': 'All-Rounder'},
        {'name': 'Ramandeep Singh', 'role': 'Batsman'},
        {'name': 'Harshit Rana', 'role': 'Bowler'},
        {'name': 'Vaibhav Arora', 'role': 'Bowler'},
      ];
    }
    if (cleaned.contains('rajasthan') || cleaned.contains('rr')) {
      return [
        {'name': 'Sanju Samson', 'role': 'Wicketkeeper-Batsman'},
        {'name': 'Yashasvi Jaiswal', 'role': 'Batsman'},
        {'name': 'Jos Butler', 'role': 'Batsman'},
        {'name': 'Yuzvendra Chahal', 'role': 'Bowler'},
        {'name': 'Riyan Parag', 'role': 'All-Rounder'},
        {'name': 'Trent Boult', 'role': 'Bowler'},
        {'name': 'Ravichandran Ashwin', 'role': 'All-Rounder'},
        {'name': 'Dhruv Jurel', 'role': 'Batsman'},
        {'name': 'Shimron Hetmyer', 'role': 'Batsman'},
        {'name': 'Sandeep Sharma', 'role': 'Bowler'},
        {'name': 'Avesh Khan', 'role': 'Bowler'},
      ];
    }
    if (cleaned.contains('sunrisers') || cleaned.contains('srh') || cleaned.contains('hyderabad')) {
      return [
        {'name': 'Pat Cummins', 'role': 'Bowler'},
        {'name': 'Travis Head', 'role': 'Batsman'},
        {'name': 'Abhishek Sharma', 'role': 'All-Rounder'},
        {'name': 'Heinrich Klaasen', 'role': 'Wicketkeeper-Batsman'},
        {'name': 'T Natarajan', 'role': 'Bowler'},
        {'name': 'Bhuvneshwar Kumar', 'role': 'Bowler'},
        {'name': 'Aiden Markram', 'role': 'Batsman'},
        {'name': 'Nitish Kumar Reddy', 'role': 'All-Rounder'},
        {'name': 'Shahbaz Ahmed', 'role': 'All-Rounder'},
        {'name': 'Jaydev Unadkat', 'role': 'Bowler'},
        {'name': 'Mayank Markande', 'role': 'Bowler'},
      ];
    }
    if (cleaned.contains('gujarat') || cleaned.contains('gt')) {
      return [
        {'name': 'Shubman Gill', 'role': 'Batsman'},
        {'name': 'Rashid Khan', 'role': 'All-Rounder'},
        {'name': 'Sai Sudharsan', 'role': 'Batsman'},
        {'name': 'Rahul Tewatia', 'role': 'All-Rounder'},
        {'name': 'Mohit Sharma', 'role': 'Bowler'},
        {'name': 'David Miller', 'role': 'Batsman'},
        {'name': 'Wriddhiman Saha', 'role': 'Wicketkeeper-Batsman'},
        {'name': 'Azmatullah Omarzai', 'role': 'All-Rounder'},
        {'name': 'Umesh Yadav', 'role': 'Bowler'},
        {'name': 'Spencer Johnson', 'role': 'Bowler'},
        {'name': 'Shahrukh Khan', 'role': 'Batsman'},
      ];
    }
    if (cleaned.contains('delhi') || cleaned.contains('dc')) {
      return [
        {'name': 'Rishabh Pant', 'role': 'Wicketkeeper-Batsman'},
        {'name': 'David Warner', 'role': 'Batsman'},
        {'name': 'Axar Patel', 'role': 'All-Rounder'},
        {'name': 'Kuldeep Yadav', 'role': 'Bowler'},
        {'name': 'Prithvi Shaw', 'role': 'Batsman'},
        {'name': 'Khaleel Ahmed', 'role': 'Bowler'},
        {'name': 'Jake Fraser-McGurk', 'role': 'Batsman'},
        {'name': 'Tristan Stubbs', 'role': 'Batsman'},
        {'name': 'Mukesh Kumar', 'role': 'Bowler'},
        {'name': 'Anrich Nortje', 'role': 'Bowler'},
        {'name': 'Abishek Porel', 'role': 'Wicketkeeper-Batsman'},
      ];
    }
    if (cleaned.contains('lucknow') || cleaned.contains('lsg')) {
      return [
        {'name': 'KL Rahul', 'role': 'Wicketkeeper-Batsman'},
        {'name': 'Nicholas Pooran', 'role': 'Batsman'},
        {'name': 'Marcus Stoinis', 'role': 'All-Rounder'},
        {'name': 'Ravi Bishnoi', 'role': 'Bowler'},
        {'name': 'Krunal Pandya', 'role': 'All-Rounder'},
        {'name': 'Ayush Badoni', 'role': 'Batsman'},
        {'name': 'Quinton de Kock', 'role': 'Wicketkeeper-Batsman'},
        {'name': 'Devdutt Padikkal', 'role': 'Batsman'},
        {'name': 'Naveen-ul-Haq', 'role': 'Bowler'},
        {'name': 'Yash Thakur', 'role': 'Bowler'},
        {'name': 'Mohsin Khan', 'role': 'Bowler'},
      ];
    }
    if (cleaned.contains('punjab') || cleaned.contains('pbks')) {
      return [
        {'name': 'Shikhar Dhawan', 'role': 'Batsman'},
        {'name': 'Sam Curran', 'role': 'All-Rounder'},
        {'name': 'Liam Livingstone', 'role': 'All-Rounder'},
        {'name': 'Arshdeep Singh', 'role': 'Bowler'},
        {'name': 'Kagiso Rabada', 'role': 'Bowler'},
        {'name': 'Jitesh Sharma', 'role': 'Wicketkeeper-Batsman'},
        {'name': 'Jonny Bairstow', 'role': 'Batsman'},
        {'name': 'Prabhsimran Singh', 'role': 'Batsman'},
        {'name': 'Shashank Singh', 'role': 'Batsman'},
        {'name': 'Ashutosh Sharma', 'role': 'Batsman'},
        {'name': 'Harshal Patel', 'role': 'Bowler'},
      ];
    }
    return [
      {'name': '$teamName Player 1', 'role': 'Batsman'},
      {'name': '$teamName Player 2', 'role': 'All-Rounder'},
      {'name': '$teamName Player 3', 'role': 'Bowler'},
      {'name': '$teamName Player 4', 'role': 'Wicketkeeper-Batsman'},
      {'name': '$teamName Player 5', 'role': 'Batsman'},
      {'name': '$teamName Player 6', 'role': 'Bowler'},
      {'name': '$teamName Player 7', 'role': 'All-Rounder'},
      {'name': '$teamName Player 8', 'role': 'Bowler'},
      {'name': '$teamName Player 9', 'role': 'Batsman'},
      {'name': '$teamName Player 10', 'role': 'Wicketkeeper-Batsman'},
      {'name': '$teamName Player 11', 'role': 'Bowler'},
    ];
  }

  List<double> _getTeamMetrics(String teamName) {
    final hash = teamName.hashCode.abs();
    return [
      (60 + (hash % 41)).toDouble(),
      (30 + ((hash ~/ 3) % 61)).toDouble(),
      (45 + ((hash ~/ 5) % 46)).toDouble(),
      (40 + ((hash ~/ 7) % 51)).toDouble(),
      (50 + ((hash ~/ 11) % 46)).toDouble(),
      (65 + ((hash ~/ 13) % 31)).toDouble(),
    ];
  }

  Widget _buildTeamLogoAvatar(String teamName, double radius) {
    final asset = getIplLogoAsset(teamName);
    if (asset != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(asset, fit: BoxFit.contain, width: radius * 2, height: radius * 2),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: Text(
        teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
        style: GoogleFonts.outfit(color: Colors.white, fontSize: radius, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'analytics_title'.tr(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: const Color(0xFF00FF7F),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingMatches
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF7F)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMatchSelectionHub(),
                  const SizedBox(height: 24),
                  if (_selectedMatch != null) ...[
                    _buildConditionalPerformanceTrend(),
                    const SizedBox(height: 24),
                    _buildAIWinPredictionCard(),
                    const SizedBox(height: 24),
                    _buildPlayerH2HProfileComponent(),
                    const SizedBox(height: 24),
                    _buildRadarChartCard(),
                  ] else ...[
                    SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'no_live_upcoming_matches'.tr(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),
    );
  }

  Widget _buildAIWinPredictionCard() {
    if (_isLoadingWinPrediction) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[850]!),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF7F)),
          ),
        ),
      );
    }

    if (_winPrediction == null || _selectedMatch == null) {
      return const SizedBox.shrink();
    }

    final info = _selectedMatch!['matchInfo'] ?? {};
    final team1 = info['team1']?['teamName'] ?? 'Team A';
    final team2 = info['team2']?['teamName'] ?? 'Team B';
    final team1S = info['team1']?['teamSName'] ?? team1;
    final team2S = info['team2']?['teamSName'] ?? team2;

    final team1Prob = (_winPrediction!['team1_probability'] as num?)?.toDouble() ?? 50.0;
    final team2Prob = (_winPrediction!['team2_probability'] as num?)?.toDouble() ?? 50.0;
    final momentum = _winPrediction!['momentum_shift'] ?? 'Predicting match dynamics...';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF7F).withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00FF7F),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ai_win_predictor'.tr(),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF7F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'live_simulation'.tr(),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00FF7F),
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team1S,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${team1Prob.toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF00FF7F),
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    team2S,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${team2Prob.toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: team1Prob.round(),
                    child: Container(color: const Color(0xFF00FF7F)),
                  ),
                  Expanded(
                    flex: team2Prob.round(),
                    child: Container(color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[850]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.psychology,
                  color: Color(0xFF00FF7F),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ai_insight_momentum_shift'.tr(),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF00FF7F),
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        momentum,
                        style: GoogleFonts.inter(
                          color: Colors.grey[300],
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchSelectionHub() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'match_selection_hub'.tr(),
          style: GoogleFonts.inter(
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 125,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _matches.length,
            itemBuilder: (context, index) {
              final match = _matches[index];
              final info = match['matchInfo'] ?? {};
              final team1 = info['team1']?['teamName'] ?? 'Team A';
              final team2 = info['team2']?['teamName'] ?? 'Team B';
              final state = info['state'] ?? 'Upcoming';
              final isLive = state.toLowerCase() == 'in progress' || state.toLowerCase() == 'live';
              final isSelected = _selectedMatch == match;

              return InkWell(
                onTap: () => _selectMatch(match),
                child: Container(
                  width: 190,
                  margin: const EdgeInsets.only(right: 12, bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00FF7F) : Colors.grey[800]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00FF7F).withValues(alpha: 0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTeamLogoAvatar(team1, 16),
                          Text(
                            'VS',
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          _buildTeamLogoAvatar(team2, 16),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${info['team1']?['teamSName'] ?? team1} vs ${info['team2']?['teamSName'] ?? team2}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLive ? Colors.redAccent.withValues(alpha: 0.2) : const Color(0xFF00FF7F).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isLive ? 'LIVE' : 'UPCOMING',
                          style: GoogleFonts.inter(
                            color: isLive ? Colors.redAccent : const Color(0xFF00FF7F),
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConditionalPerformanceTrend() {
    final info = _selectedMatch!['matchInfo'] ?? {};
    final state = info['state'] ?? 'Upcoming';
    final isLive = state.toLowerCase() == 'in progress' || state.toLowerCase() == 'live';
    final team1 = info['team1']?['teamName'] ?? 'Team A';
    final team2 = info['team2']?['teamName'] ?? 'Team B';

    final homeSeed = team1.codeUnits.fold(0, (a, b) => a + b);
    final awaySeed = team2.codeUnits.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLive ? 'live_performance_trend'.tr() : 'recent_performance_trend'.tr(),
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLive ? Colors.redAccent.withValues(alpha: 0.2) : const Color(0xFF00FF7F).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isLive ? 'over_by_over_live_index'.tr() : 'last_5_games_form_curve'.tr(),
                  style: GoogleFonts.inter(
                    color: isLive ? Colors.redAccent : const Color(0xFF00FF7F),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[850]!, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(isLive ? 'Ov ${value.toInt() * 4}' : 'G${value.toInt() + 1}', style: const TextStyle(color: Colors.grey, fontSize: 9)),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text('${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 8)),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 4,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: isLive
                        ? [
                            FlSpot(0, (30 + (homeSeed % 15)).toDouble()),
                            FlSpot(1, (45 + ((homeSeed * 2) % 20)).toDouble()),
                            FlSpot(2, (40 + ((homeSeed * 3) % 15)).toDouble()),
                            FlSpot(3, (75 + ((homeSeed * 4) % 10)).toDouble()),
                            FlSpot(4, (90 + ((homeSeed * 5) % 8)).toDouble()),
                          ]
                        : [
                            FlSpot(0, (50 + (homeSeed % 25)).toDouble()),
                            FlSpot(1, (60 - ((homeSeed * 2) % 15)).toDouble()),
                            FlSpot(2, (75 + ((homeSeed * 3) % 15)).toDouble()),
                            FlSpot(3, (65 - ((homeSeed * 4) % 10)).toDouble()),
                            FlSpot(4, (85 + ((homeSeed * 5) % 10)).toDouble()),
                          ],
                    isCurved: true,
                    color: const Color(0xFF00FF7F),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00FF7F).withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: isLive
                        ? [
                            FlSpot(0, (25 + (awaySeed % 15)).toDouble()),
                            FlSpot(1, (35 + ((awaySeed * 2) % 20)).toDouble()),
                            FlSpot(2, (55 + ((awaySeed * 3) % 15)).toDouble()),
                            FlSpot(3, (60 + ((awaySeed * 4) % 10)).toDouble()),
                            FlSpot(4, (82 + ((awaySeed * 5) % 8)).toDouble()),
                          ]
                        : [
                            FlSpot(0, (45 + (awaySeed % 25)).toDouble()),
                            FlSpot(1, (70 - ((awaySeed * 2) % 15)).toDouble()),
                            FlSpot(2, (50 + ((awaySeed * 3) % 15)).toDouble()),
                            FlSpot(3, (80 - ((awaySeed * 4) % 10)).toDouble()),
                            FlSpot(4, (75 + ((awaySeed * 5) % 10)).toDouble()),
                          ],
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00FF7F), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(info['team1']?['teamSName'] ?? team1, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(info['team2']?['teamSName'] ?? team2, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerH2HProfileComponent() {
    if (_isLoadingPlayers) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[850]!),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF7F)),
          ),
        ),
      );
    }

    final info = _selectedMatch!['matchInfo'] ?? {};
    final team1 = info['team1']?['teamName'] ?? 'Team A';
    final team2 = info['team2']?['teamName'] ?? 'Team B';

    final selectedPlayerARole = _teamAPlayers.firstWhere(
        (p) => p['name'] == _selectedPlayerA,
        orElse: () => {'role': 'All-Rounder'})['role'] ?? 'All-Rounder';
        
    final selectedPlayerBRole = _teamBPlayers.firstWhere(
        (p) => p['name'] == _selectedPlayerB,
        orElse: () => {'role': 'All-Rounder'})['role'] ?? 'All-Rounder';

    final selectedPlayerAStatus = _teamAPlayers.firstWhere(
        (p) => p['name'] == _selectedPlayerA,
        orElse: () => {'status': 'ACTIVE'})['status'] ?? 'ACTIVE';

    final selectedPlayerBStatus = _teamBPlayers.firstWhere(
        (p) => p['name'] == _selectedPlayerB,
        orElse: () => {'status': 'ACTIVE'})['status'] ?? 'ACTIVE';

    final selectedPlayerAIsCaptain = _teamAPlayers.firstWhere(
        (p) => p['name'] == _selectedPlayerA,
        orElse: () => {'isCaptain': 'false'})['isCaptain'] == 'true';

    final selectedPlayerBIsCaptain = _teamBPlayers.firstWhere(
        (p) => p['name'] == _selectedPlayerB,
        orElse: () => {'isCaptain': 'false'})['isCaptain'] == 'true';

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'h2h_player_profiles'.tr(),
              style: GoogleFonts.inter(
                color: Colors.grey[400],
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildPlayerASelector(team1, selectedPlayerARole, selectedPlayerAStatus, selectedPlayerAIsCaptain),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[800], thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'VS',
                    style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[800], thickness: 1)),
              ],
            ),
            const SizedBox(height: 16),
            _buildPlayerBSelector(team2, selectedPlayerBRole, selectedPlayerBStatus, selectedPlayerBIsCaptain),
            if (_selectedPlayerA != null && _selectedPlayerB != null) ...[
              const SizedBox(height: 20),
              _buildComparisonButton(context),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'h2h_player_profiles'.tr(),
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPlayerASelector(team1, selectedPlayerARole, selectedPlayerAStatus, selectedPlayerAIsCaptain),
              ),
              const SizedBox(width: 16),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[700]!, width: 1),
                ),
                child: Center(
                  child: Text(
                    'VS',
                    style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlayerBSelector(team2, selectedPlayerBRole, selectedPlayerBStatus, selectedPlayerBIsCaptain),
              ),
            ],
          ),
          if (_selectedPlayerA != null && _selectedPlayerB != null) ...[
            const SizedBox(height: 20),
            _buildComparisonButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FF7F),
          foregroundColor: const Color(0xFF121212),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF00FF7F).withValues(alpha: 0.3),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComparisonMatrixScreen(
                playerA: _selectedPlayerA!,
                playerB: _selectedPlayerB!,
                playerAContribution: _playerAContribution,
                playerBContribution: _playerBContribution,
              ),
            ),
          );
        },
        icon: const Icon(Icons.compare_arrows, fontWeight: FontWeight.bold),
        label: Text(
          'compare_players'.tr(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerASelector(String team1, String selectedPlayerARole, String selectedPlayerAStatus, bool selectedPlayerAIsCaptain) {
    return Column(
      children: [
        Row(
          children: [
            _buildTeamLogoAvatar(team1, 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                team1,
                style: GoogleFonts.inter(color: const Color(0xFF00FF7F), fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF1E1E1E),
              value: _selectedPlayerA,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              items: _teamAPlayers.map((p) {
                final isBench = p['status'] == 'BENCH';
                final isCap = p['isCaptain'] == 'true';
                String nameText = p['name']!;
                if (isCap) {
                  nameText += ' (C) 🧢';
                }
                if (isBench) {
                  nameText += ' (Bench)';
                }
                return DropdownMenuItem<String>(
                  value: p['name'],
                  child: Text(
                    nameText,
                    style: GoogleFonts.inter(
                      color: isBench ? Colors.white60 : Colors.white, 
                      fontSize: 12, 
                      fontWeight: isBench ? FontWeight.normal : (isCap ? FontWeight.bold : FontWeight.w600)
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedPlayerA = val);
                  _fetchPlayerContribution(val, true);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF00FF7F).withValues(alpha: 0.15),
              child: Text(
                _selectedPlayerA != null && _selectedPlayerA!.isNotEmpty ? _selectedPlayerA![0] : 'A',
                style: GoogleFonts.outfit(color: const Color(0xFF00FF7F), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedPlayerARole,
                    style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: selectedPlayerAStatus == 'ACTIVE'
                                ? const Color(0xFF00FF7F).withValues(alpha: 0.2)
                                : Colors.orangeAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            selectedPlayerAStatus,
                            style: GoogleFonts.inter(
                              color: selectedPlayerAStatus == 'ACTIVE'
                                  ? const Color(0xFF00FF7F)
                                  : Colors.orangeAccent,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      if (selectedPlayerAIsCaptain) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'CAPTAIN 🧢',
                              style: GoogleFonts.inter(
                                color: Colors.amber,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerBSelector(String team2, String selectedPlayerBRole, String selectedPlayerBStatus, bool selectedPlayerBIsCaptain) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                team2,
                style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 6),
            _buildTeamLogoAvatar(team2, 14),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF1E1E1E),
              value: _selectedPlayerB,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              items: _teamBPlayers.map((p) {
                final isBench = p['status'] == 'BENCH';
                final isCap = p['isCaptain'] == 'true';
                String nameText = p['name']!;
                if (isCap) {
                  nameText += ' (C) 🧢';
                }
                if (isBench) {
                  nameText += ' (Bench)';
                }
                return DropdownMenuItem<String>(
                  value: p['name'],
                  child: Text(
                    nameText,
                    style: GoogleFonts.inter(
                      color: isBench ? Colors.white60 : Colors.white, 
                      fontSize: 12, 
                      fontWeight: isBench ? FontWeight.normal : (isCap ? FontWeight.bold : FontWeight.w600)
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedPlayerB = val);
                  _fetchPlayerContribution(val, false);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
              child: Text(
                _selectedPlayerB != null && _selectedPlayerB!.isNotEmpty ? _selectedPlayerB![0] : 'B',
                style: GoogleFonts.outfit(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedPlayerBRole,
                    style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            selectedPlayerBStatus,
                            style: GoogleFonts.inter(
                              color: selectedPlayerBStatus == 'ACTIVE'
                                  ? Colors.blueAccent
                                  : Colors.orangeAccent,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      if (selectedPlayerBIsCaptain) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'CAPTAIN 🧢',
                              style: GoogleFonts.inter(
                                color: Colors.amber,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ],
    );
  }


  Widget _buildRadarChartCard() {
    if (_selectedMatch == null) {
      return const SizedBox.shrink();
    }

    final info = _selectedMatch!['matchInfo'] ?? {};
    final team1 = info['team1']?['teamName'] ?? 'Team A';
    final team2 = info['team2']?['teamName'] ?? 'Team B';
    final team1S = info['team1']?['teamSName'] ?? team1;
    final team2S = info['team2']?['teamSName'] ?? team2;

    final metricsA = _getTeamMetrics(team1);
    final metricsB = _getTeamMetrics(team2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TEAMS ATTRIBUTE MATRIX',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: RadarChart(
              RadarChartData(
                tickCount: 3,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                titlePositionPercentageOffset: 0.15,
                getTitle: (index, angle) {
                  final titles = ['Strike Rate', 'Average', 'Boundaries', 'Wickets', 'Economy', 'Form'];
                  return RadarChartTitle(
                    text: titles[index],
                    angle: 0,
                    positionPercentageOffset: 0.08,
                  );
                },
                dataSets: [
                  RadarDataSet(
                    fillColor: const Color(0xFF00FF7F).withValues(alpha: 0.2),
                    borderColor: const Color(0xFF00FF7F),
                    entryRadius: 3.5,
                    dataEntries: metricsA.map((val) => RadarEntry(value: val)).toList(),
                  ),
                  RadarDataSet(
                    fillColor: Colors.blueAccent.withValues(alpha: 0.2),
                    borderColor: Colors.blueAccent,
                    entryRadius: 3.5,
                    dataEntries: metricsB.map((val) => RadarEntry(value: val)).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00FF7F), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(team1S, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 24),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(team2S, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

}
