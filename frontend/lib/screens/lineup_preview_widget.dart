import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LineupPreviewWidget extends StatelessWidget {
  final Map<String, dynamic> lineup;

  const LineupPreviewWidget({super.key, required this.lineup});

  @override
  Widget build(BuildContext context) {
    final String teamName = lineup['teamName'] ?? 'Dream Team XI';
    final String sport = lineup['sport'] ?? 'Cricket';
    final String formation = lineup['formation'] ?? '';
    final String captain = lineup['captain'] ?? '';
    final String viceCaptain = lineup['viceCaptain'] ?? '';
    final List<dynamic> playersRaw = lineup['players'] ?? [];
    final List<String> players = playersRaw.map((p) => p.toString()).toList();

    if (players.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  sport.toLowerCase() == 'football'
                      ? Icons.sports_soccer
                      : (sport.toLowerCase() == 'cricket' ? Icons.sports_cricket : Icons.sports_kabaddi),
                  color: const Color(0xFF00FF7F),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamName,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$sport • $formation',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Visual Field representation
          Container(
            height: 180,
            margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E3F20),
                  const Color(0xFF132B14),
                ],
              ),
              border: Border.all(color: Colors.green[800]!.withValues(alpha: 0.5), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Tactical lines
                  _buildFieldLines(sport),
                  
                  // Players positioning
                  ..._buildPlayerPositions(sport, players, captain, viceCaptain),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLines(String sport) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        
        if (sport.toLowerCase() == 'football') {
          return CustomPaint(
            size: Size(w, h),
            painter: FootballFieldPainter(),
          );
        } else if (sport.toLowerCase() == 'cricket') {
          return CustomPaint(
            size: Size(w, h),
            painter: CricketFieldPainter(),
          );
        } else {
          return CustomPaint(
            size: Size(w, h),
            painter: KabaddiMatPainter(),
          );
        }
      },
    );
  }

  List<Widget> _buildPlayerPositions(String sport, List<String> players, String captain, String viceCaptain) {
    final List<Widget> widgets = [];
    final alignments = _getAlignments(sport, players.length);

    for (int i = 0; i < players.length && i < alignments.length; i++) {
      final player = players[i];
      final align = alignments[i];
      final isCap = player == captain;
      final isVc = player == viceCaptain;

      widgets.add(
        Align(
          alignment: align,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bubble
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isCap 
                          ? const Color(0xFF00FF7F) 
                          : (isVc ? Colors.orangeAccent : Colors.white.withValues(alpha: 0.9)),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getPlayerInitials(player),
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isCap || isVc ? Colors.black : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  if (isCap || isVc)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isCap ? const Color(0xFF00FF7F) : Colors.orangeAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Text(
                          isCap ? 'C' : 'VC',
                          style: const TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              // Name text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                constraints: const BoxConstraints(maxWidth: 55),
                child: Text(
                  _getPlayerLastName(player),
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  String _getPlayerInitials(String name) {
    final clean = name.replaceAll(RegExp(r'\((.*?)\)'), '').trim(); // Remove roles like (WK)
    final parts = clean.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _getPlayerLastName(String name) {
    final clean = name.replaceAll(RegExp(r'\((.*?)\)'), '').trim();
    final parts = clean.split(' ');
    if (parts.isEmpty) return '';
    return parts.last;
  }

  List<Alignment> _getAlignments(String sport, int count) {
    if (sport.toLowerCase() == 'football') {
      return const [
        Alignment(0, 0.85), // GK (aligned bottom for standard representation)
        Alignment(-0.7, 0.45), Alignment(-0.25, 0.45), Alignment(0.25, 0.45), Alignment(0.7, 0.45), // DEF
        Alignment(-0.55, -0.05), Alignment(0, -0.1), Alignment(0.55, -0.05), // MID
        Alignment(-0.6, -0.65), Alignment(0, -0.72), Alignment(0.6, -0.65), // FWD
      ];
    } else if (sport.toLowerCase() == 'cricket') {
      return const [
        Alignment(0, 0.85), // WK
        Alignment(-0.6, 0.45), Alignment(-0.2, 0.45), Alignment(0.2, 0.45), Alignment(0.6, 0.45), // BAT
        Alignment(-0.35, -0.05), Alignment(0.35, -0.05), // ALL
        Alignment(-0.6, -0.58), Alignment(-0.2, -0.58), Alignment(0.2, -0.58), Alignment(0.6, -0.58), // BOWL
      ];
    } else {
      // Kabaddi 7 players
      return const [
        Alignment(-0.75, 0.35), // Left Corner
        Alignment(-0.4, 0.15),  // Left Cover
        Alignment(0.4, 0.15),   // Right Cover
        Alignment(0.75, 0.35),  // Right Corner
        Alignment(-0.5, -0.4),  // Left In
        Alignment(0, -0.55),     // Center Raider
        Alignment(0.5, -0.4),   // Right In
      ];
    }
  }
}

// Custom Painters for premium graphics
class FootballFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Boundary
    canvas.drawRect(Rect.fromLTWH(4, 4, size.width - 8, size.height - 8), paint);

    // Center line
    canvas.drawLine(Offset(4, size.height / 2), Offset(size.width - 4, size.height / 2), paint);

    // Center circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 22, paint);

    // Penalty Boxes (Top and Bottom)
    final boxW = size.width * 0.45;
    final boxH = 30.0;
    canvas.drawRect(Rect.fromLTWH((size.width - boxW) / 2, 4, boxW, boxH), paint);
    canvas.drawRect(Rect.fromLTWH((size.width - boxW) / 2, size.height - 4 - boxH, boxW, boxH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CricketFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Pitch (Center rectangle)
    final pitchW = 14.0;
    final pitchH = 34.0;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: pitchW, height: pitchH),
      paint..style = PaintingStyle.fill..color = Colors.brown[700]!.withValues(alpha: 0.2),
    );
    paint.color = Colors.white.withValues(alpha: 0.12);
    paint.style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: pitchW, height: pitchH),
      paint,
    );

    // Outer Boundary Oval
    canvas.drawOval(Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), paint);

    // 30 yard circle
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width * 0.65, height: size.height * 0.65),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class KabaddiMatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Boundary
    canvas.drawRect(Rect.fromLTWH(6, 6, size.width - 12, size.height - 12), paint);

    // Midline
    canvas.drawLine(Offset(6, size.height / 2), Offset(size.width - 6, size.height / 2), paint);

    // Baulk Lines
    final baulkDist = size.height * 0.18;
    canvas.drawLine(Offset(6, size.height / 2 - baulkDist), Offset(size.width - 6, size.height / 2 - baulkDist), paint);
    canvas.drawLine(Offset(6, size.height / 2 + baulkDist), Offset(size.width - 6, size.height / 2 + baulkDist), paint);

    // Bonus Lines
    final bonusDist = size.height * 0.26;
    canvas.drawLine(Offset(6, size.height / 2 - bonusDist), Offset(size.width - 6, size.height / 2 - bonusDist), paint..strokeWidth = 0.8);
    canvas.drawLine(Offset(6, size.height / 2 + bonusDist), Offset(size.width - 6, size.height / 2 + bonusDist), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
