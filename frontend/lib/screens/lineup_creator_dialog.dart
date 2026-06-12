import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class LineupCreatorDialog extends StatefulWidget {
  const LineupCreatorDialog({super.key});

  @override
  State<LineupCreatorDialog> createState() => _LineupCreatorDialogState();
}

class _LineupCreatorDialogState extends State<LineupCreatorDialog> {
  String _selectedSport = 'Cricket';
  late String _selectedFormation;
  final TextEditingController _teamNameController = TextEditingController(text: 'Dream Team XI');

  final Map<String, List<String>> _formations = {
    'Cricket': ['Balanced (1-4-2-4)', 'Batting Heavy (1-5-2-3)', 'Bowling Heavy (1-3-2-5)'],
    'Football': ['4-3-3', '4-4-2', '3-5-2', '5-3-2'],
    'Kabaddi': ['Standard (7 Players)']
  };

  // Squad Pool fetched dynamically
  List<Map<String, String>> _squadPool = [];
  bool _isLoadingSquad = false;
  String _matchName = '';

  // User's selections
  List<String> _selectedPlayers = [];
  String? _selectedCaptain;
  String? _selectedViceCaptain;

  int get maxPlayers => _selectedSport == 'Kabaddi' ? 7 : 11;

  @override
  void initState() {
    super.initState();
    _selectedFormation = _formations[_selectedSport]![0];
    _fetchSquadForSport(_selectedSport);
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  void _onSportChanged(String sport) {
    setState(() {
      _selectedSport = sport;
      _selectedFormation = _formations[sport]![0];
    });
    _fetchSquadForSport(sport);
  }

  Future<void> _fetchSquadForSport(String sport) async {
    if (!mounted) return;
    setState(() {
      _isLoadingSquad = true;
      _squadPool = [];
      _selectedPlayers = [];
      _selectedCaptain = null;
      _selectedViceCaptain = null;
      _matchName = '';
    });

    try {
      if (sport == 'Football') {
        final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/football/matches/live-and-upcoming')).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final matches = data['matches'] is List ? data['matches'] : [];
          if (matches.isNotEmpty) {
            final m = matches[0];
            final matchId = m['id']?.toString() ?? m['matchId']?.toString();
            final t1 = m['home']?['name'] ?? 'Home';
            final t2 = m['away']?['name'] ?? 'Away';
            _matchName = '$t1 vs $t2';

            if (matchId != null) {
              final scResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/football/match/$matchId/scorecard')).timeout(const Duration(seconds: 5));
              if (scResponse.statusCode == 200) {
                final scData = jsonDecode(scResponse.body);
                final teams = scData['teams'] as Map<String, dynamic>?;
                if (teams != null) {
                  final List<Map<String, String>> fetchedPool = [];
                  teams.forEach((teamName, teamData) {
                    final playersList = teamData['players'] as List? ?? [];
                    final shortName = teamData['short'] ?? teamName;
                    for (var p in playersList) {
                      final name = p['name'] ?? 'Unknown';
                      final role = p['role'] ?? 'Player';
                      fetchedPool.add({
                        'name': name,
                        'role': role,
                        'team': shortName.toString(),
                      });
                    }
                  });
                  _squadPool = fetchedPool;
                }
              }
            }
          }
        }
        if (_squadPool.isEmpty) {
          _matchName = 'USA vs Mexico';
          _squadPool = _generateFootballSquad('USA', 'Mexico');
        }
      } else {
        // Cricket or Kabaddi
        final endpoint = sport == 'Cricket' 
            ? '/api/cricket/matches/live-and-upcoming'
            : '/api/kabaddi/matches/live-and-upcoming';
        
        final response = await http.get(Uri.parse('${ApiConfig.baseUrl}$endpoint')).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final matches = data['matches'] is List ? data['matches'] : [];
          if (matches.isNotEmpty) {
            final m = matches[0];
            final matchInfo = m['matchInfo'] ?? {};
            final matchId = matchInfo['matchId'];
            final t1 = matchInfo['team1']?['teamName'] ?? 'Team 1';
            final t2 = matchInfo['team2']?['teamName'] ?? 'Team 2';
            _matchName = '$t1 vs $t2';

            if (matchId != null) {
              final scorecardEndpoint = sport == 'Cricket'
                  ? '/api/cricket/match/$matchId/scorecard'
                  : '/api/kabaddi/match/$matchId/scorecard';
              
              final scResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}$scorecardEndpoint')).timeout(const Duration(seconds: 5));
              if (scResponse.statusCode == 200) {
                final scData = jsonDecode(scResponse.body);
                final teams = scData['teams'] as Map<String, dynamic>?;
                if (teams != null) {
                  final List<Map<String, String>> fetchedPool = [];
                  teams.forEach((teamName, teamData) {
                    final playersList = teamData['players'] as List? ?? [];
                    final shortName = teamData['short'] ?? teamName;
                    for (var p in playersList) {
                      final name = p['name'] ?? 'Unknown';
                      final role = p['role'] ?? 'Player';
                      fetchedPool.add({
                        'name': name,
                        'role': role,
                        'team': shortName.toString(),
                      });
                    }
                  });
                  _squadPool = fetchedPool;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching dynamic squads: $e');
    }

    // Fallbacks if list is still empty (e.g. offline or API error)
    if (_squadPool.isEmpty) {
      _loadFallbackSquad(sport);
    }

    if (mounted) {
      setState(() {
        _isLoadingSquad = false;
      });
    }
  }

  List<Map<String, String>> _generateFootballSquad(String t1, String t2) {
    final List<Map<String, String>> list = [];
    final t1Lower = t1.toLowerCase();
    final t2Lower = t2.toLowerCase();

    List<Map<String, String>> t1Players = [];
    List<Map<String, String>> t2Players = [];

    final Map<String, List<Map<String, String>>> nationalTeams = {
      'usa': [
        {'name': 'Christian Pulisic', 'role': 'FWD', 'team': 'USA'},
        {'name': 'Folarin Balogun', 'role': 'FWD', 'team': 'USA'},
        {'name': 'Timothy Weah', 'role': 'FWD', 'team': 'USA'},
        {'name': 'Weston McKennie', 'role': 'MID', 'team': 'USA'},
        {'name': 'Tyler Adams', 'role': 'MID', 'team': 'USA'},
        {'name': 'Yunus Musah', 'role': 'MID', 'team': 'USA'},
        {'name': 'Antonee Robinson', 'role': 'DEF', 'team': 'USA'},
        {'name': 'Tim Ream', 'role': 'DEF', 'team': 'USA'},
        {'name': 'Chris Richards', 'role': 'DEF', 'team': 'USA'},
        {'name': 'Sergiño Dest', 'role': 'DEF', 'team': 'USA'},
        {'name': 'Matt Turner', 'role': 'GK', 'team': 'USA'},
      ],
      'mexico': [
        {'name': 'Santiago Giménez', 'role': 'FWD', 'team': 'MEX'},
        {'name': 'Hirving Lozano', 'role': 'FWD', 'team': 'MEX'},
        {'name': 'Uriel Antuna', 'role': 'FWD', 'team': 'MEX'},
        {'name': 'Edson Álvarez', 'role': 'MID', 'team': 'MEX'},
        {'name': 'Luis Chávez', 'role': 'MID', 'team': 'MEX'},
        {'name': 'Orbelín Pineda', 'role': 'MID', 'team': 'MEX'},
        {'name': 'Jesús Gallardo', 'role': 'DEF', 'team': 'MEX'},
        {'name': 'Johan Vásquez', 'role': 'DEF', 'team': 'MEX'},
        {'name': 'César Montes', 'role': 'DEF', 'team': 'MEX'},
        {'name': 'Jorge Sánchez', 'role': 'DEF', 'team': 'MEX'},
        {'name': 'Guillermo Ochoa', 'role': 'GK', 'team': 'MEX'},
      ],
      'argentina': [
        {'name': 'Lionel Messi', 'role': 'FWD', 'team': 'ARG'},
        {'name': 'Lautaro Martínez', 'role': 'FWD', 'team': 'ARG'},
        {'name': 'Julián Álvarez', 'role': 'FWD', 'team': 'ARG'},
        {'name': 'Rodrigo De Paul', 'role': 'MID', 'team': 'ARG'},
        {'name': 'Enzo Fernández', 'role': 'MID', 'team': 'ARG'},
        {'name': 'Alexis Mac Allister', 'role': 'MID', 'team': 'ARG'},
        {'name': 'Nicolás Tagliafico', 'role': 'DEF', 'team': 'ARG'},
        {'name': 'Nicolás Otamendi', 'role': 'DEF', 'team': 'ARG'},
        {'name': 'Cristian Romero', 'role': 'DEF', 'team': 'ARG'},
        {'name': 'Nahuel Molina', 'role': 'DEF', 'team': 'ARG'},
        {'name': 'Emiliano Martínez', 'role': 'GK', 'team': 'ARG'},
      ],
      'france': [
        {'name': 'Kylian Mbappé', 'role': 'FWD', 'team': 'FRA'},
        {'name': 'Antoine Griezmann', 'role': 'MID', 'team': 'FRA'},
        {'name': 'Ousmane Dembélé', 'role': 'FWD', 'team': 'FRA'},
        {'name': 'Bradley Barcola', 'role': 'FWD', 'team': 'FRA'},
        {'name': 'N\'Golo Kanté', 'role': 'MID', 'team': 'FRA'},
        {'name': 'Aurélien Tchouaméni', 'role': 'MID', 'team': 'FRA'},
        {'name': 'Theo Hernández', 'role': 'DEF', 'team': 'FRA'},
        {'name': 'William Saliba', 'role': 'DEF', 'team': 'FRA'},
        {'name': 'Dayot Upamecano', 'role': 'DEF', 'team': 'FRA'},
        {'name': 'Jules Koundé', 'role': 'DEF', 'team': 'FRA'},
        {'name': 'Mike Maignan', 'role': 'GK', 'team': 'FRA'},
      ],
      'portugal': [
        {'name': 'Cristiano Ronaldo', 'role': 'FWD', 'team': 'POR'},
        {'name': 'Rafael Leão', 'role': 'FWD', 'team': 'POR'},
        {'name': 'Bernardo Silva', 'role': 'FWD', 'team': 'POR'},
        {'name': 'Bruno Fernandes', 'role': 'MID', 'team': 'POR'},
        {'name': 'João Palhinha', 'role': 'MID', 'team': 'POR'},
        {'name': 'João Neves', 'role': 'MID', 'team': 'POR'},
        {'name': 'João Cancelo', 'role': 'DEF', 'team': 'POR'},
        {'name': 'António Silva', 'role': 'DEF', 'team': 'POR'},
        {'name': 'Rúben Dias', 'role': 'DEF', 'team': 'POR'},
        {'name': 'Diogo Dalot', 'role': 'DEF', 'team': 'POR'},
        {'name': 'Diogo Costa', 'role': 'GK', 'team': 'POR'},
      ],
      'spain': [
        {'name': 'Lamine Yamal', 'role': 'FWD', 'team': 'ESP'},
        {'name': 'Álvaro Morata', 'role': 'FWD', 'team': 'ESP'},
        {'name': 'Nico Williams', 'role': 'FWD', 'team': 'ESP'},
        {'name': 'Pedri', 'role': 'MID', 'team': 'ESP'},
        {'name': 'Rodri', 'role': 'MID', 'team': 'ESP'},
        {'name': 'Fabián Ruiz', 'role': 'MID', 'team': 'ESP'},
        {'name': 'Marc Cucurella', 'role': 'DEF', 'team': 'ESP'},
        {'name': 'Aymeric Laporte', 'role': 'DEF', 'team': 'ESP'},
        {'name': 'Robin Le Normand', 'role': 'DEF', 'team': 'ESP'},
        {'name': 'Dani Carvajal', 'role': 'DEF', 'team': 'ESP'},
        {'name': 'Unai Simón', 'role': 'GK', 'team': 'ESP'},
      ],
      'brazil': [
        {'name': 'Vinícius Júnior', 'role': 'FWD', 'team': 'BRA'},
        {'name': 'Rodrygo', 'role': 'FWD', 'team': 'BRA'},
        {'name': 'Raphinha', 'role': 'FWD', 'team': 'BRA'},
        {'name': 'Lucas Paquetá', 'role': 'MID', 'team': 'BRA'},
        {'name': 'João Gomes', 'role': 'MID', 'team': 'BRA'},
        {'name': 'Bruno Guimarães', 'role': 'MID', 'team': 'BRA'},
        {'name': 'Wendell', 'role': 'DEF', 'team': 'BRA'},
        {'name': 'Gabriel Magalhães', 'role': 'DEF', 'team': 'BRA'},
        {'name': 'Marquinhos', 'role': 'DEF', 'team': 'BRA'},
        {'name': 'Danilo', 'role': 'DEF', 'team': 'BRA'},
        {'name': 'Alisson Becker', 'role': 'GK', 'team': 'BRA'},
      ],
      'england': [
        {'name': 'Harry Kane', 'role': 'FWD', 'team': 'ENG'},
        {'name': 'Phil Foden', 'role': 'FWD', 'team': 'ENG'},
        {'name': 'Bukayo Saka', 'role': 'FWD', 'team': 'ENG'},
        {'name': 'Jude Bellingham', 'role': 'MID', 'team': 'ENG'},
        {'name': 'Declan Rice', 'role': 'MID', 'team': 'ENG'},
        {'name': 'Kobbie Mainoo', 'role': 'MID', 'team': 'ENG'},
        {'name': 'Kieran Trippier', 'role': 'DEF', 'team': 'ENG'},
        {'name': 'Marc Guéhi', 'role': 'DEF', 'team': 'ENG'},
        {'name': 'John Stones', 'role': 'DEF', 'team': 'ENG'},
        {'name': 'Kyle Walker', 'role': 'DEF', 'team': 'ENG'},
        {'name': 'Jordan Pickford', 'role': 'GK', 'team': 'ENG'},
      ],
      'germany': [
        {'name': 'Florian Wirtz', 'role': 'FWD', 'team': 'GER'},
        {'name': 'Kai Havertz', 'role': 'FWD', 'team': 'GER'},
        {'name': 'Jamal Musiala', 'role': 'FWD', 'team': 'GER'},
        {'name': 'Ilkay Gündogan', 'role': 'MID', 'team': 'GER'},
        {'name': 'Toni Kroos', 'role': 'MID', 'team': 'GER'},
        {'name': 'Robert Andrich', 'role': 'MID', 'team': 'GER'},
        {'name': 'Maximilian Mittelstädt', 'role': 'DEF', 'team': 'GER'},
        {'name': 'Jonathan Tah', 'role': 'DEF', 'team': 'GER'},
        {'name': 'Antonio Rüdiger', 'role': 'DEF', 'team': 'GER'},
        {'name': 'Joshua Kimmich', 'role': 'DEF', 'team': 'GER'},
        {'name': 'Manuel Neuer', 'role': 'GK', 'team': 'GER'},
      ],
      'japan': [
        {'name': 'Ayase Ueda', 'role': 'FWD', 'team': 'JPN'},
        {'name': 'Kaoru Mitoma', 'role': 'FWD', 'team': 'JPN'},
        {'name': 'Takumi Minamino', 'role': 'FWD', 'team': 'JPN'},
        {'name': 'Takefusa Kubo', 'role': 'FWD', 'team': 'JPN'},
        {'name': 'Hidemasa Morita', 'role': 'MID', 'team': 'JPN'},
        {'name': 'Wataru Endo', 'role': 'MID', 'team': 'JPN'},
        {'name': 'Hiroki Ito', 'role': 'DEF', 'team': 'JPN'},
        {'name': 'Koki Machida', 'role': 'DEF', 'team': 'JPN'},
        {'name': 'Ko Itakura', 'role': 'DEF', 'team': 'JPN'},
        {'name': 'Yukinari Sugawara', 'role': 'DEF', 'team': 'JPN'},
        {'name': 'Zion Suzuki', 'role': 'GK', 'team': 'JPN'},
      ],
    };

    final String key1 = nationalTeams.keys.firstWhere(
      (k) => t1Lower.contains(k),
      orElse: () => '',
    );
    if (key1.isNotEmpty) {
      t1Players = nationalTeams[key1]!;
    } else if (t1Lower.contains('real madrid') || t1Lower.contains('madrid') || t1Lower.contains('rm')) {
      t1Players = [
        {'name': 'T. Courtois', 'role': 'GK', 'team': 'RM'},
        {'name': 'D. Carvajal', 'role': 'DEF', 'team': 'RM'},
        {'name': 'E. Militão', 'role': 'DEF', 'team': 'RM'},
        {'name': 'A. Rüdiger', 'role': 'DEF', 'team': 'RM'},
        {'name': 'F. Mendy', 'role': 'DEF', 'team': 'RM'},
        {'name': 'F. Valverde', 'role': 'MID', 'team': 'RM'},
        {'name': 'A. Tchouaméni', 'role': 'MID', 'team': 'RM'},
        {'name': 'J. Bellingham', 'role': 'MID', 'team': 'RM'},
        {'name': 'K. Mbappé', 'role': 'FWD', 'team': 'RM'},
        {'name': 'Vinícius Jr.', 'role': 'FWD', 'team': 'RM'},
        {'name': 'Rodrygo', 'role': 'FWD', 'team': 'RM'},
      ];
    } else {
      t1Players = [
        {'name': 'E. Martinez', 'role': 'GK', 'team': 'T1'},
        {'name': 'K. Walker', 'role': 'DEF', 'team': 'T1'},
        {'name': 'V. van Dijk', 'role': 'DEF', 'team': 'T1'},
        {'name': 'W. Saliba', 'role': 'DEF', 'team': 'T1'},
        {'name': 'K. De Bruyne', 'role': 'MID', 'team': 'T1'},
        {'name': 'L. Messi', 'role': 'FWD', 'team': 'T1'},
        {'name': 'B. Saka', 'role': 'FWD', 'team': 'T1'},
      ];
    }

    final String key2 = nationalTeams.keys.firstWhere(
      (k) => t2Lower.contains(k),
      orElse: () => '',
    );
    if (key2.isNotEmpty) {
      t2Players = nationalTeams[key2]!;
    } else if (t2Lower.contains('manchester city') || t2Lower.contains('city') || t2Lower.contains('mc')) {
      t2Players = [
        {'name': 'Ederson', 'role': 'GK', 'team': 'MC'},
        {'name': 'M. Akanji', 'role': 'DEF', 'team': 'MC'},
        {'name': 'R. Dias', 'role': 'DEF', 'team': 'MC'},
        {'name': 'J. Gvardiol', 'role': 'DEF', 'team': 'MC'},
        {'name': 'Rodri', 'role': 'MID', 'team': 'MC'},
        {'name': 'M. Kovacic', 'role': 'MID', 'team': 'MC'},
        {'name': 'B. Silva', 'role': 'MID', 'team': 'MC'},
        {'name': 'P. Foden', 'role': 'MID', 'team': 'MC'},
        {'name': 'E. Haaland', 'role': 'FWD', 'team': 'MC'},
        {'name': 'J. Grealish', 'role': 'FWD', 'team': 'MC'},
        {'name': 'J. Doku', 'role': 'FWD', 'team': 'MC'},
      ];
    } else {
      t2Players = [
        {'name': 'L. Oblak', 'role': 'GK', 'team': 'T2'},
        {'name': 'J. Gimenez', 'role': 'DEF', 'team': 'T2'},
        {'name': 'R. De Paul', 'role': 'MID', 'team': 'T2'},
        {'name': 'A. Griezmann', 'role': 'FWD', 'team': 'T2'},
        {'name': 'A. Morata', 'role': 'FWD', 'team': 'T2'},
      ];
    }

    list.addAll(t1Players);
    list.addAll(t2Players);
    return list;
  }

  void _loadFallbackSquad(String sport) {
    if (sport == 'Cricket') {
      _matchName = 'RCB vs KKR (Upcoming)';
      _squadPool = [
        {'name': 'Virat Kohli', 'role': 'Batter', 'team': 'RCB'},
        {'name': 'Faf du Plessis', 'role': 'Batter', 'team': 'RCB'},
        {'name': 'Rajat Patidar', 'role': 'Batter', 'team': 'RCB'},
        {'name': 'Glenn Maxwell', 'role': 'All-Rounder', 'team': 'RCB'},
        {'name': 'Cameron Green', 'role': 'All-Rounder', 'team': 'RCB'},
        {'name': 'Dinesh Karthik', 'role': 'Wicketkeeper', 'team': 'RCB'},
        {'name': 'Mohammed Siraj', 'role': 'Bowler', 'team': 'RCB'},
        {'name': 'Yash Dayal', 'role': 'Bowler', 'team': 'RCB'},
        {'name': 'Lockie Ferguson', 'role': 'Bowler', 'team': 'RCB'},
        {'name': 'Shreyas Iyer', 'role': 'Batter', 'team': 'KKR'},
        {'name': 'Phil Salt', 'role': 'Wicketkeeper', 'team': 'KKR'},
        {'name': 'Sunil Narine', 'role': 'All-Rounder', 'team': 'KKR'},
        {'name': 'Andre Russell', 'role': 'All-Rounder', 'team': 'KKR'},
        {'name': 'Rinku Singh', 'role': 'Batter', 'team': 'KKR'},
        {'name': 'Mitchell Starc', 'role': 'Bowler', 'team': 'KKR'},
        {'name': 'Varun Chakaravarthy', 'role': 'Bowler', 'team': 'KKR'},
      ];
    } else if (sport == 'Kabaddi') {
      _matchName = 'Patna Pirates vs U Mumba (Upcoming)';
      _squadPool = [
        {'name': 'Sudhakar M', 'role': 'Raider', 'team': 'PAT'},
        {'name': 'Sachin Tanwar', 'role': 'Raider', 'team': 'PAT'},
        {'name': 'Manjeet', 'role': 'Raider', 'team': 'PAT'},
        {'name': 'Ankit Jaglan', 'role': 'Defender', 'team': 'PAT'},
        {'name': 'Krishan Dhull', 'role': 'Defender', 'team': 'PAT'},
        {'name': 'Guman Singh', 'role': 'Raider', 'team': 'MUM'},
        {'name': 'Amirmohammad Zafardanesh', 'role': 'All-Rounder', 'team': 'MUM'},
        {'name': 'Sombir', 'role': 'Defender', 'team': 'MUM'},
        {'name': 'Rinku Sharma', 'role': 'Defender', 'team': 'MUM'},
        {'name': 'Mahender Singh', 'role': 'Defender', 'team': 'MUM'},
      ];
    } else {
      _matchName = 'USA vs Mexico (Upcoming)';
      _squadPool = _generateFootballSquad('USA', 'Mexico');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        // Lineup Creation Widget layout width increased to 96%
        width: MediaQuery.of(context).size.width * 0.96,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'CREATE LINEUP',
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
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),

            // Dialog content (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team Name
                    Text(
                      'TEAM NAME',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _teamNameController,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Enter Team Name...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFF2D2D2D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sport Selection with Layout Fixes to prevent horizontal pixel overflow
                    Text(
                      'SPORT',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Cricket', 'Football', 'Kabaddi'].map((sport) {
                        final isSel = _selectedSport == sport;
                        return ChoiceChip(
                          label: Text(sport),
                          selected: isSel,
                          labelStyle: GoogleFonts.inter(
                            color: isSel ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          selectedColor: const Color(0xFF00FF7F),
                          backgroundColor: const Color(0xFF2C2C2C),
                          checkmarkColor: Colors.black,
                          onSelected: (val) {
                            if (val) _onSportChanged(sport);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Formation Selection
                    Text(
                      'FORMATION / LAYOUT',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey('formation_$_selectedFormation'),
                      initialValue: _selectedFormation,
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFF2D2D2D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedFormation = val;
                          });
                        }
                      },
                      items: _formations[_selectedSport]!
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Squad Pool Selection with Checkboxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'SQUAD POOL${_matchName.isNotEmpty ? ' ($_matchName)' : ''}',
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _selectedPlayers.length == maxPlayers
                                ? const Color(0xFF00FF7F).withValues(alpha: 0.2)
                                : Colors.grey[850],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedPlayers.length == maxPlayers
                                  ? const Color(0xFF00FF7F)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '${_selectedPlayers.length} / $maxPlayers SELECTED',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _selectedPlayers.length == maxPlayers
                                  ? const Color(0xFF00FF7F)
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingSquad)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
                        ),
                      )
                    else if (_squadPool.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            'No squad data available.',
                            style: GoogleFonts.inter(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[850]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(8),
                            itemCount: _squadPool.length,
                            separatorBuilder: (context, index) => Divider(color: Colors.grey[850], height: 8),
                            itemBuilder: (context, index) {
                              final player = _squadPool[index];
                              final pName = player['name'] ?? 'Unknown';
                              final pRole = player['role'] ?? 'Player';
                              final pTeam = player['team'] ?? '';
                              final isSelected = _selectedPlayers.contains(pName);

                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  unselectedWidgetColor: Colors.grey[600],
                                ),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  title: Text(
                                    pName,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$pTeam • $pRole',
                                    style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
                                  ),
                                  checkColor: Colors.black,
                                  activeColor: const Color(0xFF00FF7F),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  controlAffinity: ListTileControlAffinity.trailing,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        // Strict Validation: Avoid duplicate selection
                                        if (_selectedPlayers.contains(pName)) return;
                                        
                                        // Strict Validation: Cap selections to maximum players
                                        if (_selectedPlayers.length >= maxPlayers) {
                                          ScaffoldMessenger.of(context).clearSnackBars();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('You can only select up to $maxPlayers players'),
                                              backgroundColor: Colors.redAccent,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                          return;
                                        }
                                        _selectedPlayers.add(pName);
                                      } else {
                                        _selectedPlayers.remove(pName);
                                        if (_selectedCaptain == pName) _selectedCaptain = null;
                                        if (_selectedViceCaptain == pName) _selectedViceCaptain = null;
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Captain and Vice-Captain Selector (Retained assignment logic, dynamically populated)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CAPTAIN (C)',
                                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                key: ValueKey('captain_$_selectedCaptain'),
                                initialValue: _selectedPlayers.contains(_selectedCaptain) ? _selectedCaptain : null,
                                hint: Text('Select Captain', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12)),
                                dropdownColor: const Color(0xFF1E1E1E),
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: const Color(0xFF2D2D2D),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: _selectedPlayers.length < 2
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedCaptain = val;
                                            if (_selectedCaptain == _selectedViceCaptain) {
                                              _selectedViceCaptain = null;
                                            }
                                          });
                                        }
                                      },
                                items: _selectedPlayers
                                    .map((name) => DropdownMenuItem<String>(
                                          value: name,
                                          child: Text(
                                            name,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(fontSize: 13),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VICE CAPTAIN (VC)',
                                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                key: ValueKey('vice_captain_$_selectedViceCaptain'),
                                initialValue: _selectedPlayers.contains(_selectedViceCaptain) ? _selectedViceCaptain : null,
                                hint: Text('Select Vice-Captain', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12)),
                                dropdownColor: const Color(0xFF1E1E1E),
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: const Color(0xFF2D2D2D),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: _selectedPlayers.length < 2
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedViceCaptain = val;
                                            if (_selectedViceCaptain == _selectedCaptain) {
                                              _selectedCaptain = null;
                                            }
                                          });
                                        }
                                      },
                                items: _selectedPlayers
                                    .map((name) => DropdownMenuItem<String>(
                                          value: name,
                                          child: Text(
                                            name,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(fontSize: 13),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Validation check: ensure exactly the required number of players are selected
                    if (_selectedPlayers.length != maxPlayers) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please select exactly $maxPlayers players to attach lineup.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    // Validation check: ensure Captain and Vice Captain are assigned
                    if (_selectedCaptain == null || _selectedViceCaptain == null) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please assign a Captain and Vice-Captain.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    final lineupData = {
                      'teamName': _teamNameController.text.trim(),
                      'sport': _selectedSport,
                      'formation': _selectedFormation,
                      'captain': _selectedCaptain!,
                      'viceCaptain': _selectedViceCaptain!,
                      'players': _selectedPlayers,
                    };
                    Navigator.pop(context, lineupData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF7F),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: Text(
                    'ATTACH LINEUP',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
