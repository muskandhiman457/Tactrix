import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'comparison_matrix_screen.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ANALYSIS ENGINE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: const Color(0xFF00FF7F),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ComparisonMatrixScreen()),
                );
              },
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Open Comparison Matrix'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: const Color(0xFF00FF7F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF00FF7F)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Player Contribution Score',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI predictive metric based on historical form.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            _buildBarChart(),
            const SizedBox(height: 40),
            Text(
              'Team Win Probability',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Live match momentum and historical head-to-head.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            _buildPieChart(),
            const SizedBox(height: 40),
            Text(
              'Recent Performance Trend',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildLineChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(color: Colors.white, fontSize: 10);
                  String text;
                  switch (value.toInt()) {
                    case 0: text = 'P1'; break;
                    case 1: text = 'P2'; break;
                    case 2: text = 'P3'; break;
                    case 3: text = 'P4'; break;
                    case 4: text = 'P5'; break;
                    default: text = ''; break;
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(text, style: style),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 85, color: const Color(0xFF00FF7F), width: 16, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 70, color: const Color(0xFF00FF7F), width: 16, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 95, color: const Color(0xFF00FF7F), width: 16, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 60, color: const Color(0xFF00FF7F), width: 16, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 78, color: const Color(0xFF00FF7F), width: 16, borderRadius: BorderRadius.circular(4))]),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 60,
              sections: [
                PieChartSectionData(
                  color: const Color(0xFF00FF7F),
                  value: 65,
                  title: '65%',
                  radius: 20,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                PieChartSectionData(
                  color: Colors.redAccent,
                  value: 35,
                  title: '35%',
                  radius: 20,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('TEAM A', style: GoogleFonts.outfit(color: const Color(0xFF00FF7F), fontWeight: FontWeight.bold)),
              Text('vs', style: GoogleFonts.inter(color: Colors.grey, fontSize: 10)),
              Text('TEAM B', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 24, left: 16, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[800], strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text('M${value.toInt() + 1}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                },
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
              spots: const [
                FlSpot(0, 30),
                FlSpot(1, 50),
                FlSpot(2, 40),
                FlSpot(3, 80),
                FlSpot(4, 95),
              ],
              isCurved: true,
              color: const Color(0xFF00FF7F),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF00FF7F).withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
