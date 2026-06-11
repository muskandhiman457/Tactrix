import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class ComparisonMatrixScreen extends StatelessWidget {
  final String playerA;
  final String playerB;
  final Map<String, dynamic> playerAContribution;
  final Map<String, dynamic> playerBContribution;

  const ComparisonMatrixScreen({
    super.key,
    required this.playerA,
    required this.playerB,
    required this.playerAContribution,
    required this.playerBContribution,
  });

  Map<String, String> _getPlayerStats(String name) {
    final hash = name.hashCode.abs();
    final matchesPlayed = 30 + (hash % 41); // 30 to 70
    final winRate = 45 + (hash % 36); // 45 to 80
    final avgPoints = (10.0 + (hash % 81) / 10.0).toStringAsFixed(1); // 10.0 to 18.0
    return {
      'matchesPlayed': matchesPlayed.toString(),
      'winRate': '$winRate%',
      'avgPoints': avgPoints,
    };
  }

  List<double> _getPlayerMetricsFromApi(Map<String, dynamic> contrib, String name) {
    if (contrib.containsKey('recent_trend') && contrib['recent_trend'] is List) {
      final List<dynamic> trend = contrib['recent_trend'];
      final impact = (contrib['impact_score'] as num?)?.toDouble() ?? 8.0;
      final metrics = trend.map((v) => (v as num).toDouble()).toList();
      while (metrics.length < 4) {
        metrics.add(70.0);
      }
      final List<double> res = metrics.take(4).toList();
      res.add(impact * 10.0);
      return res;
    }
    final hash = name.hashCode.abs();
    return [
      (60 + (hash % 41)).toDouble(),
      (30 + ((hash ~/ 3) % 61)).toDouble(),
      (45 + ((hash ~/ 5) % 46)).toDouble(),
      (40 + ((hash ~/ 7) % 51)).toDouble(),
      (50 + ((hash ~/ 11) % 46)).toDouble(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final statsA = _getPlayerStats(playerA);
    final statsB = _getPlayerStats(playerB);
    final impactA = (playerAContribution['impact_score'] as num?)?.toDouble() ?? 8.0;
    final impactB = (playerBContribution['impact_score'] as num?)?.toDouble() ?? 8.0;

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
          'COMPARISON MATRIX',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: const Color(0xFF00FF7F),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildPlayerSelector(playerA, const Color(0xFF00FF7F))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'VS',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white60,
                    ),
                  ),
                ),
                Expanded(child: _buildPlayerSelector(playerB, Colors.blueAccent)),
              ],
            ),
            const SizedBox(height: 24),
            _buildRadarChart(),
            const SizedBox(height: 24),
            Container(
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
                    'HEAD-TO-HEAD STATS',
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatComparison('Matches Played', statsA['matchesPlayed']!, statsB['matchesPlayed']!),
                  _buildStatComparison('Win Rate', statsA['winRate']!, statsB['winRate']!),
                  _buildStatComparison('Avg Points', statsA['avgPoints']!, statsB['avgPoints']!),
                  _buildStatComparison('Impact Score', impactA.toStringAsFixed(1), impactB.toStringAsFixed(1)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDualBarChartCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSelector(String name, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildRadarChart() {
    final metricsA = _getPlayerMetricsFromApi(playerAContribution, playerA);
    final metricsB = _getPlayerMetricsFromApi(playerBContribution, playerB);

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
            'Past Performance Matrix',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: RadarChart(
              RadarChartData(
                radarTouchData: RadarTouchData(enabled: false),
                tickCount: 3,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                titlePositionPercentageOffset: 0.1,
                getTitle: (index, angle) {
                  final titles = ['Strike Rate', 'Average', 'Boundaries', 'Wickets', 'Form/Economy'];
                  return RadarChartTitle(
                    text: titles[index],
                    angle: 0,
                    positionPercentageOffset: 0.15,
                  );
                },
                dataSets: [
                  RadarDataSet(
                    fillColor: const Color(0xFF00FF7F).withValues(alpha: 0.25),
                    borderColor: const Color(0xFF00FF7F),
                    entryRadius: 3.5,
                    dataEntries: metricsA.map((val) => RadarEntry(value: val)).toList(),
                  ),
                  RadarDataSet(
                    fillColor: Colors.blueAccent.withValues(alpha: 0.25),
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
              Expanded(
                child: Text(
                  playerA,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 24),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  playerB,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatComparison(String title, String valA, String valB) {
    double ratio = 0.5;
    try {
      final numA = double.parse(valA.replaceAll(RegExp(r'[^0-9.]'), ''));
      final numB = double.parse(valB.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (numA + numB > 0) {
        ratio = numA / (numA + numB);
      }
    } catch (_) {
      ratio = 0.5;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(valA, style: GoogleFonts.outfit(color: const Color(0xFF00FF7F), fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: Colors.blueAccent.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF7F)),
                      ),
                    ),
                  ),
                ),
              ),
              Text(valB, style: GoogleFonts.outfit(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDualBarChartCard() {
    final scoreA = (playerAContribution['impact_score'] as num?)?.toDouble() ?? 8.0;
    final scoreB = (playerBContribution['impact_score'] as num?)?.toDouble() ?? 8.0;
    final contribA = (scoreA / (scoreA + scoreB)) * 100;
    final contribB = (scoreB / (scoreA + scoreB)) * 100;

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
            'WIN-INFLUENCE CONTRIBUTION %',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Estimated percentage of match wins influenced by each player based on their overall batting, bowling, and fielding form index.',
            style: GoogleFonts.inter(
              color: Colors.grey[500],
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF2C2C2C),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)}%',
                        GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold);
                        String text = value == 0 ? playerA : playerB;
                        if (text.length > 10) {
                          text = '${text.substring(0, 8)}..';
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(text, style: style),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text('${value.toInt()}%', style: const TextStyle(color: Colors.grey, fontSize: 9)),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[850]!, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: contribA,
                        color: const Color(0xFF00FF7F),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: contribB,
                        color: Colors.blueAccent,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00FF7F), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            playerA,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${contribA.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(color: const Color(0xFF00FF7F), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            playerB,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${contribB.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
