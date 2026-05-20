import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        Container(
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
            height: 400, // Fixed height for tab content
            child: TabBarView(
              children: [
                _buildLineupsTab(),
                const Center(child: Text('Match Stats', style: TextStyle(color: Colors.white))),
                const Center(child: Text('AI Predictive Analysis', style: TextStyle(color: Colors.white))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLineupsTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTeamList('${homeTeam.toUpperCase()} STARTING XI')),
        Container(width: 1, color: Colors.grey[800]),
        Expanded(child: _buildTeamList('${awayTeam.toUpperCase()} STARTING XI')),
      ],
    );
  }

  Widget _buildTeamList(String title) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 11,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFF1E1E1E),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Player ${index + 1}',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
