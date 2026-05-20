import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerInfo {
  final String name;
  final String role;
  final String number;
  final String nationality;
  final String stats;

  const PlayerInfo({
    required this.name,
    required this.role,
    required this.number,
    required this.nationality,
    required this.stats,
  });
}

class MatchDetailScreen extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final String? homeLogoUrl;
  final String? awayLogoUrl;
  final String statusText;
  final String scoreText;
  final bool isLive;
  final String venue;

  const MatchDetailScreen({
    super.key,
    this.homeTeam = 'MUMBAI',
    this.awayTeam = 'CHENNAI',
    this.homeLogoUrl,
    this.awayLogoUrl,
    this.statusText = '● LIVE - 2nd Half',
    this.scoreText = '2 - 1',
    this.isLive = true,
    this.venue = 'Wankhede Stadium',
  });

  static const Map<String, List<PlayerInfo>> _teamSquads = {
    'arsenal': [
      PlayerInfo(name: 'David Raya', role: 'GK', number: '1', nationality: 'Spain', stats: 'Clean sheets: 16'),
      PlayerInfo(name: 'Ben White', role: 'DF', number: '4', nationality: 'England', stats: 'Goals: 4, Assists: 4'),
      PlayerInfo(name: 'William Saliba', role: 'DF', number: '2', nationality: 'France', stats: 'Interceptions: 45'),
      PlayerInfo(name: 'Gabriel Magalhães', role: 'DF', number: '6', nationality: 'Brazil', stats: 'Goals: 3'),
      PlayerInfo(name: 'Oleksandr Zinchenko', role: 'DF', number: '35', nationality: 'Ukraine', stats: 'Pass Accuracy: 89%'),
      PlayerInfo(name: 'Declan Rice', role: 'MF', number: '41', nationality: 'England', stats: 'Goals: 7, Assists: 8'),
      PlayerInfo(name: 'Martin Ødegaard', role: 'MF', number: '8', nationality: 'Norway', stats: 'Goals: 8, Assists: 10'),
      PlayerInfo(name: 'Kai Havertz', role: 'MF', number: '29', nationality: 'Germany', stats: 'Goals: 13, Assists: 7'),
      PlayerInfo(name: 'Bukayo Saka', role: 'FW', number: '7', nationality: 'England', stats: 'Goals: 16, Assists: 9'),
      PlayerInfo(name: 'Gabriel Martinelli', role: 'FW', number: '11', nationality: 'Brazil', stats: 'Goals: 6, Assists: 4'),
      PlayerInfo(name: 'Leandro Trossard', role: 'FW', number: '19', nationality: 'Belgium', stats: 'Goals: 12, Assists: 1'),
    ],
    'real madrid': [
      PlayerInfo(name: 'Thibaut Courtois', role: 'GK', number: '1', nationality: 'Belgium', stats: 'Saves: 78'),
      PlayerInfo(name: 'Dani Carvajal', role: 'DF', number: '2', nationality: 'Spain', stats: 'Goals: 6, Assists: 5'),
      PlayerInfo(name: 'Antonio Rüdiger', role: 'DF', number: '22', nationality: 'Germany', stats: 'Tackles: 38'),
      PlayerInfo(name: 'Éder Militão', role: 'DF', number: '3', nationality: 'Brazil', stats: 'Clearances: 52'),
      PlayerInfo(name: 'Ferland Mendy', role: 'DF', number: '23', nationality: 'France', stats: 'Interceptions: 34'),
      PlayerInfo(name: 'Aurelien Tchouaméni', role: 'MF', number: '18', nationality: 'France', stats: 'Pass Accuracy: 92%'),
      PlayerInfo(name: 'Federico Valverde', role: 'MF', number: '15', nationality: 'Uruguay', stats: 'Goals: 3, Assists: 7'),
      PlayerInfo(name: 'Jude Bellingham', role: 'MF', number: '5', nationality: 'England', stats: 'Goals: 19, Assists: 6'),
      PlayerInfo(name: 'Rodrygo Goes', role: 'FW', number: '11', nationality: 'Brazil', stats: 'Goals: 10, Assists: 5'),
      PlayerInfo(name: 'Vinícius Júnior', role: 'FW', number: '7', nationality: 'Brazil', stats: 'Goals: 15, Assists: 5'),
      PlayerInfo(name: 'Kylian Mbappé', role: 'FW', number: '9', nationality: 'France', stats: 'Goals: 28, Assists: 7'),
    ],
    'bayern münchen': [
      PlayerInfo(name: 'Manuel Neuer', role: 'GK', number: '1', nationality: 'Germany', stats: 'Saves: 65'),
      PlayerInfo(name: 'Joshua Kimmich', role: 'DF', number: '6', nationality: 'Germany', stats: 'Pass Accuracy: 91%'),
      PlayerInfo(name: 'Dayot Upamecano', role: 'DF', number: '2', nationality: 'France', stats: 'Tackles: 42'),
      PlayerInfo(name: 'Kim Min-jae', role: 'DF', number: '3', nationality: 'South Korea', stats: 'Clearances: 64'),
      PlayerInfo(name: 'Alphonso Davies', role: 'DF', number: '19', nationality: 'Canada', stats: 'Assists: 5'),
      PlayerInfo(name: 'Leon Goretzka', role: 'MF', number: '8', nationality: 'Germany', stats: 'Goals: 6, Assists: 7'),
      PlayerInfo(name: 'Konrad Laimer', role: 'MF', number: '27', nationality: 'Austria', stats: 'Interceptions: 29'),
      PlayerInfo(name: 'Jamal Musiala', role: 'MF', number: '42', nationality: 'Germany', stats: 'Goals: 10, Assists: 6'),
      PlayerInfo(name: 'Leroy Sané', role: 'FW', number: '10', nationality: 'Germany', stats: 'Goals: 8, Assists: 11'),
      PlayerInfo(name: 'Thomas Müller', role: 'FW', number: '25', nationality: 'Germany', stats: 'Goals: 5, Assists: 9'),
      PlayerInfo(name: 'Harry Kane', role: 'FW', number: '9', nationality: 'England', stats: 'Goals: 36, Assists: 8'),
    ],
    'psg': [
      PlayerInfo(name: 'Gianluigi Donnarumma', role: 'GK', number: '99', nationality: 'Italy', stats: 'Saves: 82'),
      PlayerInfo(name: 'Achraf Hakimi', role: 'DF', number: '2', nationality: 'Morocco', stats: 'Goals: 4, Assists: 5'),
      PlayerInfo(name: 'Marquinhos', role: 'DF', number: '5', nationality: 'Brazil', stats: 'Clearances: 75'),
      PlayerInfo(name: 'Milan Škriniar', role: 'DF', number: '37', nationality: 'Slovakia', stats: 'Interceptions: 48'),
      PlayerInfo(name: 'Nuno Mendes', role: 'DF', number: '25', nationality: 'Portugal', stats: 'Crosses: 34'),
      PlayerInfo(name: 'Warren Zaïre-Emery', role: 'MF', number: '33', nationality: 'France', stats: 'Pass Accuracy: 90%'),
      PlayerInfo(name: 'Vitinha', role: 'MF', number: '17', nationality: 'Portugal', stats: 'Goals: 7, Assists: 4'),
      PlayerInfo(name: 'Fabián Ruiz', role: 'MF', number: '8', nationality: 'Spain', stats: 'Goals: 3, Assists: 5'),
      PlayerInfo(name: 'Ousmane Dembélé', role: 'FW', number: '10', nationality: 'France', stats: 'Assists: 12'),
      PlayerInfo(name: 'Bradley Barcola', role: 'FW', number: '29', nationality: 'France', stats: 'Goals: 5, Assists: 7'),
      PlayerInfo(name: 'Gonçalo Ramos', role: 'FW', number: '9', nationality: 'Portugal', stats: 'Goals: 11, Assists: 1'),
    ],
    'athletic club': [
      PlayerInfo(name: 'Julen Agirrezabala', role: 'GK', number: '13', nationality: 'Spain', stats: 'Saves: 51'),
      PlayerInfo(name: 'Óscar de Marcos', role: 'DF', number: '18', nationality: 'Spain', stats: 'Assists: 3'),
      PlayerInfo(name: 'Dani Vivian', role: 'DF', number: '3', nationality: 'Spain', stats: 'Interceptions: 35'),
      PlayerInfo(name: 'Aitor Paredes', role: 'DF', number: '4', nationality: 'Spain', stats: 'Tackles: 28'),
      PlayerInfo(name: 'Yuri Berchiche', role: 'DF', number: '17', nationality: 'Spain', stats: 'Goals: 3'),
      PlayerInfo(name: 'Iñigo Ruiz de Galarreta', role: 'MF', number: '6', nationality: 'Spain', stats: 'Pass Accuracy: 87%'),
      PlayerInfo(name: 'Beñat Prados', role: 'MF', number: '24', nationality: 'Spain', stats: 'Tackles: 41'),
      PlayerInfo(name: 'Oihan Sancet', role: 'MF', number: '8', nationality: 'Spain', stats: 'Goals: 5, Assists: 4'),
      PlayerInfo(name: 'Iñaki Williams', role: 'FW', number: '9', nationality: 'Ghana', stats: 'Goals: 12, Assists: 8'),
      PlayerInfo(name: 'Nico Williams', role: 'FW', number: '11', nationality: 'Spain', stats: 'Goals: 8, Assists: 12'),
      PlayerInfo(name: 'Gorka Guruzeta', role: 'FW', number: '12', nationality: 'Spain', stats: 'Goals: 14, Assists: 5'),
    ],
    'atletico madrid': [
      PlayerInfo(name: 'Jan Oblak', role: 'GK', number: '13', nationality: 'Slovenia', stats: 'Saves: 85'),
      PlayerInfo(name: 'Nahuel Molina', role: 'DF', number: '16', nationality: 'Argentina', stats: 'Goals: 2, Assists: 3'),
      PlayerInfo(name: 'Axel Witsel', role: 'DF', number: '20', nationality: 'Belgium', stats: 'Clearances: 62'),
      PlayerInfo(name: 'Jose María Giménez', role: 'DF', number: '2', nationality: 'Uruguay', stats: 'Tackles: 31'),
      PlayerInfo(name: 'Mario Hermoso', role: 'DF', number: '22', nationality: 'Spain', stats: 'Interceptions: 40'),
      PlayerInfo(name: 'Koke', role: 'MF', number: '6', nationality: 'Spain', stats: 'Pass Accuracy: 90%'),
      PlayerInfo(name: 'Rodrigo De Paul', role: 'MF', number: '5', nationality: 'Argentina', stats: 'Goals: 3, Assists: 6'),
      PlayerInfo(name: 'Marcos Llorente', role: 'MF', number: '14', nationality: 'Spain', stats: 'Goals: 6, Assists: 5'),
      PlayerInfo(name: 'Antoine Griezmann', role: 'FW', number: '7', nationality: 'France', stats: 'Goals: 16, Assists: 6'),
      PlayerInfo(name: 'Álvaro Morata', role: 'FW', number: '19', nationality: 'Spain', stats: 'Goals: 15, Assists: 2'),
      PlayerInfo(name: 'Samuel Lino', role: 'FW', number: '12', nationality: 'Brazil', stats: 'Goals: 4, Assists: 5'),
    ],
    'mumbai indians': [
      PlayerInfo(name: 'Rohit Sharma', role: 'Batter', number: '45', nationality: 'India', stats: 'Runs: 417, Sixes: 23'),
      PlayerInfo(name: 'Ishan Kishan', role: 'Wicketkeeper', number: '23', nationality: 'India', stats: 'Runs: 320, Catches: 10'),
      PlayerInfo(name: 'Suryakumar Yadav', role: 'Batter', number: '63', nationality: 'India', stats: 'Strike Rate: 168.4'),
      PlayerInfo(name: 'Tilak Varma', role: 'Batter', number: '9', nationality: 'India', stats: 'Runs: 380, Avg: 42.2'),
      PlayerInfo(name: 'Hardik Pandya', role: 'All-Rounder', number: '33', nationality: 'India', stats: 'Wickets: 11, Runs: 210'),
      PlayerInfo(name: 'Tim David', role: 'Batter', number: '85', nationality: 'Australia', stats: 'Sixes: 18, Runs: 241'),
      PlayerInfo(name: 'Romario Shepherd', role: 'All-Rounder', number: '16', nationality: 'West Indies', stats: 'Runs: 115'),
      PlayerInfo(name: 'Gerald Coetzee', role: 'Bowler', number: '62', nationality: 'South Africa', stats: 'Wickets: 13, Econ: 8.9'),
      PlayerInfo(name: 'Jasprit Bumrah', role: 'Bowler', number: '93', nationality: 'India', stats: 'Wickets: 20, Econ: 6.48'),
      PlayerInfo(name: 'Piyush Chawla', role: 'Bowler', number: '11', nationality: 'India', stats: 'Wickets: 10'),
      PlayerInfo(name: 'Nuwan Thushara', role: 'Bowler', number: '54', nationality: 'Sri Lanka', stats: 'Wickets: 8'),
    ],
    'chennai super kings': [
      PlayerInfo(name: 'Ruturaj Gaikwad', role: 'Batter', number: '31', nationality: 'India', stats: 'Runs: 583, Avg: 58.3'),
      PlayerInfo(name: 'Rachin Ravindra', role: 'Batter', number: '17', nationality: 'New Zealand', stats: 'Runs: 222'),
      PlayerInfo(name: 'Ajinkya Rahane', role: 'Batter', number: '21', nationality: 'India', stats: 'Runs: 180'),
      PlayerInfo(name: 'Shivam Dube', role: 'All-Rounder', number: '25', nationality: 'India', stats: 'Sixes: 28, Runs: 396'),
      PlayerInfo(name: 'Ravindra Jadeja', role: 'All-Rounder', number: '8', nationality: 'India', stats: 'Wickets: 8, Runs: 220'),
      PlayerInfo(name: 'MS Dhoni', role: 'Wicketkeeper', number: '7', nationality: 'India', stats: 'Strike Rate: 220.5'),
      PlayerInfo(name: 'Mitchell Santner', role: 'All-Rounder', number: '74', nationality: 'New Zealand', stats: 'Wickets: 4'),
      PlayerInfo(name: 'Shardul Thakur', role: 'Bowler', number: '54', nationality: 'India', stats: 'Wickets: 5'),
      PlayerInfo(name: 'Tushar Deshpande', role: 'Bowler', number: '24', nationality: 'India', stats: 'Wickets: 16, Econ: 8.4'),
      PlayerInfo(name: 'Matheesha Pathirana', role: 'Bowler', number: '99', nationality: 'Sri Lanka', stats: 'Wickets: 13, Econ: 7.6'),
      PlayerInfo(name: 'Richard Gleeson', role: 'Bowler', number: '71', nationality: 'England', stats: 'Wickets: 2'),
    ],
    'royal challengers bengaluru': [
      PlayerInfo(name: 'Virat Kohli', role: 'Batter', number: '18', nationality: 'India', stats: 'Runs: 741, Avg: 61.75'),
      PlayerInfo(name: 'Faf du Plessis', role: 'Batter', number: '13', nationality: 'South Africa', stats: 'Runs: 430, Sixes: 21'),
      PlayerInfo(name: 'Will Jacks', role: 'All-Rounder', number: '20', nationality: 'England', stats: 'Strike Rate: 175.4, 100s: 1'),
      PlayerInfo(name: 'Rajat Patidar', role: 'Batter', number: '97', nationality: 'India', stats: 'Runs: 360, 50s: 5'),
      PlayerInfo(name: 'Glenn Maxwell', role: 'All-Rounder', number: '32', nationality: 'Australia', stats: 'Wickets: 6, Runs: 52'),
      PlayerInfo(name: 'Cameron Green', role: 'All-Rounder', number: '4', nationality: 'Australia', stats: 'Runs: 255, Wickets: 10'),
      PlayerInfo(name: 'Dinesh Karthik', role: 'Wicketkeeper', number: '19', nationality: 'India', stats: 'Strike Rate: 187.3'),
      PlayerInfo(name: 'Swapnil Singh', role: 'All-Rounder', number: '86', nationality: 'India', stats: 'Wickets: 6'),
      PlayerInfo(name: 'Karn Sharma', role: 'Bowler', number: '33', nationality: 'India', stats: 'Wickets: 7'),
      PlayerInfo(name: 'Mohammed Siraj', role: 'Bowler', number: '73', nationality: 'India', stats: 'Wickets: 15, Econ: 9.1'),
      PlayerInfo(name: 'Yash Dayal', role: 'Bowler', number: '12', nationality: 'India', stats: 'Wickets: 15, Econ: 8.8'),
    ],
    'delhi capitals': [
      PlayerInfo(name: 'Jake Fraser-McGurk', role: 'Batter', number: '24', nationality: 'Australia', stats: 'Strike Rate: 234.0, Runs: 330'),
      PlayerInfo(name: 'Abishek Porel', role: 'Batter', number: '22', nationality: 'India', stats: 'Runs: 280'),
      PlayerInfo(name: 'Shai Hope', role: 'Batter', number: '4', nationality: 'West Indies', stats: 'Runs: 190'),
      PlayerInfo(name: 'Rishabh Pant', role: 'Wicketkeeper', number: '17', nationality: 'India', stats: 'Runs: 446, Sixes: 25'),
      PlayerInfo(name: 'Tristan Stubbs', role: 'Batter', number: '30', nationality: 'South Africa', stats: 'Strike Rate: 190.9'),
      PlayerInfo(name: 'Axar Patel', role: 'All-Rounder', number: '20', nationality: 'India', stats: 'Wickets: 11, Runs: 235'),
      PlayerInfo(name: 'Kuldeep Yadav', role: 'Bowler', number: '23', nationality: 'India', stats: 'Wickets: 16, Econ: 7.9'),
      PlayerInfo(name: 'Rasikh Salam', role: 'Bowler', number: '77', nationality: 'India', stats: 'Wickets: 8'),
      PlayerInfo(name: 'Mukesh Kumar', role: 'Bowler', number: '19', nationality: 'India', stats: 'Wickets: 17'),
      PlayerInfo(name: 'Anrich Nortje', role: 'Bowler', number: '20', nationality: 'South Africa', stats: 'Wickets: 7'),
      PlayerInfo(name: 'Khaleel Ahmed', role: 'Bowler', number: '90', nationality: 'India', stats: 'Wickets: 17, Econ: 9.3'),
    ],
  };

  List<PlayerInfo> _getSquadForTeam(String name) {
    final cleaned = name.toLowerCase().trim();
    if (cleaned == 'mi' || cleaned.contains('mumbai')) return _teamSquads['mumbai indians']!;
    if (cleaned == 'csk' || cleaned.contains('chennai')) return _teamSquads['chennai super kings']!;
    if (cleaned == 'rcb' || cleaned.contains('bengaluru') || cleaned.contains('bangalore')) return _teamSquads['royal challengers bengaluru']!;
    if (cleaned == 'dc' || cleaned.contains('delhi')) return _teamSquads['delhi capitals']!;
    if (cleaned.contains('real') || (cleaned.contains('madrid') && !cleaned.contains('atletico'))) return _teamSquads['real madrid']!;
    if (cleaned.contains('atletico')) return _teamSquads['atletico madrid']!;
    if (cleaned.contains('arsenal')) return _teamSquads['arsenal']!;
    if (cleaned.contains('bayern') || cleaned.contains('münchen') || cleaned.contains('munchen')) return _teamSquads['bayern münchen']!;
    if (cleaned.contains('psg') || cleaned.contains('paris') || cleaned.contains('germain')) return _teamSquads['psg']!;
    if (cleaned.contains('athletic') || cleaned.contains('bilbao')) return _teamSquads['athletic club']!;

    // Fallback generated squad based on whether it seems like a football match or cricket match
    final isCricket = cleaned == 'mi' || cleaned == 'csk' || cleaned == 'rcb' || cleaned == 'dc' ||
                      cleaned.contains('indians') || cleaned.contains('kings') || cleaned.contains('challengers') || cleaned.contains('capitals') ||
                      (venue.toLowerCase().contains('stadium') && scoreText.contains('/'));
                      
    return List.generate(11, (index) {
      if (isCricket) {
        String role = 'Batter';
        if (index == 0) {
          role = 'Wicketkeeper';
        } else if (index > 3 && index < 7) {
          role = 'All-Rounder';
        } else if (index >= 7) {
          role = 'Bowler';
        }
        return PlayerInfo(
          name: 'Player ${index + 1}',
          role: role,
          number: '${index + 10}',
          nationality: 'International',
          stats: 'Matches: 12, Impact Rating: 8.5',
        );
      } else {
        String role = 'MF';
        if (index == 0) {
          role = 'GK';
        } else if (index > 0 && index < 5) {
          role = 'DF';
        } else if (index >= 8) {
          role = 'FW';
        }
        return PlayerInfo(
          name: 'Player ${index + 1}',
          role: role,
          number: '${index + 1}',
          nationality: 'International',
          stats: 'Form Rank: #${index + 1}',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isLive ? 'LIVE MATCH' : 'UPCOMING MATCH',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: isLive ? Colors.redAccent : const Color(0xFF00FF7F),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScoreboard(),
            const SizedBox(height: 24),
            _buildTabBarLayout(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreboard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: isLive ? Colors.redAccent.withOpacity(0.1) : const Color(0xFF00FF7F).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isLive 
                  ? Colors.redAccent.withOpacity(0.2) 
                  : const Color(0xFF00FF7F).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                color: isLive ? Colors.redAccent : const Color(0xFF00FF7F), 
                fontWeight: FontWeight.bold, 
                fontSize: 12
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTeamLogo(homeTeam, homeTeam.isNotEmpty ? homeTeam[0] : '?', homeLogoUrl),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      scoreText,
                      style: GoogleFonts.outfit(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      venue,
                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              _buildTeamLogo(awayTeam, awayTeam.isNotEmpty ? awayTeam[0] : '?', awayLogoUrl),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String name, String shortName, String? logoUrl) {
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.grey[800],
          child: logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: Image.network(
                    logoUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      shortName.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                )
              : Text(
                  shortName.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBarLayout(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF00FF7F),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'LINEUPS'),
              Tab(text: 'STATS'),
              Tab(text: 'ANALYSIS'),
            ],
          ),
          SizedBox(
            height: 480, // Expanded height for interactive list items
            child: TabBarView(
              children: [
                _buildLineupsTab(context),
                _buildStatsTab(),
                _buildAnalysisTab(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLineupsTab(BuildContext context) {
    final homeSquad = _getSquadForTeam(homeTeam);
    final awaySquad = _getSquadForTeam(awayTeam);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTeamList(context, '${homeTeam.toUpperCase()} XI', homeSquad)),
        Container(width: 1, color: Colors.grey[800]),
        Expanded(child: _buildTeamList(context, '${awayTeam.toUpperCase()} XI', awaySquad)),
      ],
    );
  }

  Widget _buildTeamList(BuildContext context, String title, List<PlayerInfo> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF00FF7F),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return InkWell(
                onTap: () => _showPlayerDetails(context, player),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF1E1E1E),
                        child: Text(
                          player.number,
                          style: GoogleFonts.inter(
                            fontSize: 9, 
                            color: const Color(0xFF00FF7F), 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              style: GoogleFonts.inter(
                                color: Colors.white, 
                                fontWeight: FontWeight.w600, 
                                fontSize: 13
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              player.role,
                              style: GoogleFonts.inter(
                                color: Colors.grey[500], 
                                fontSize: 10
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
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

  Widget _buildStatsTab() {
    final cleaned = homeTeam.toLowerCase();
    final isCricket = cleaned == 'mi' || cleaned == 'csk' || cleaned == 'rcb' || cleaned == 'dc' ||
                      cleaned.contains('indians') || cleaned.contains('kings') || cleaned.contains('challengers') || cleaned.contains('capitals') ||
                      (venue.toLowerCase().contains('stadium') && scoreText.contains('/'));

    if (isCricket) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatRow('Run Rate', 7.4, 6.8, '7.4', '6.8'),
          _buildStatRow('Sixes', 12.0, 9.0, '12', '9'),
          _buildStatRow('Fours', 18.0, 14.0, '18', '14'),
          _buildStatRow('Extras', 8.0, 12.0, '8', '12'),
          _buildStatRow('Projected Score', 185.0, 172.0, '185', '172'),
        ],
      );
    } else {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatRow('Possession', 58.0, 42.0, '58%', '42%'),
          _buildStatRow('Shots on Target', 7.0, 3.0, '7', '3'),
          _buildStatRow('Total Shots', 14.0, 8.0, '14', '8'),
          _buildStatRow('Corners', 6.0, 4.0, '6', '4'),
          _buildStatRow('Fouls', 9.0, 11.0, '9', '11'),
        ],
      );
    }
  }

  Widget _buildStatRow(String label, double homeVal, double awayVal, String homeText, String awayText) {
    final total = homeVal + awayVal;
    final homePct = total > 0 ? homeVal / total : 0.5;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(homeText, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(label.toUpperCase(), style: GoogleFonts.inter(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0)),
              Text(awayText, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (homePct * 100).round(),
                    child: Container(color: const Color(0xFF00FF7F)),
                  ),
                  Container(width: 2, color: Colors.grey[900]),
                  Expanded(
                    flex: ((1 - homePct) * 100).round(),
                    child: Container(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI WIN PREDICTION',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(homeTeam, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(awayTeam, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 12,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF7F)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('65% Probability', style: GoogleFonts.inter(color: const Color(0xFF00FF7F), fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('35% Probability', style: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'MOMENTUM & INSIGHTS',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Text(
              'Based on recent games, $homeTeam shows high momentum in attack phase (average speed of transition is up by 14%). $awayTeam is playing defensively with a low block structure, presenting opportunities for long shots.',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerDetails(BuildContext context, PlayerInfo player) {
    final randomTrend = [8.0, 7.5, 9.2, 8.8, 9.5];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(color: Colors.grey[800]!, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${player.role} • #${player.number}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF00FF7F),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          player.nationality,
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.grey, height: 32, thickness: 0.5),
              Text(
                'SEASON STATISTICS',
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Text(
                  player.stats,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AI PERFORMANCE TREND (LAST 5 MATCHES)',
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  height: 60,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomPaint(
                    painter: SparklinePainter(randomTrend),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> dataPoints;
  SparklinePainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF7F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = const Color(0xFF00FF7F).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final path = Path();
    final stepX = size.width / (dataPoints.length - 1);
    
    double minVal = dataPoints[0];
    double maxVal = dataPoints[0];
    for (var val in dataPoints) {
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }
    double range = maxVal - minVal;
    if (range == 0) range = 1.0;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final y = size.height - ((dataPoints[i] - minVal) / range * (size.height - 20) + 10);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
