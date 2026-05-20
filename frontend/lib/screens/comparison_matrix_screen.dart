import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class ComparisonMatrixScreen extends StatelessWidget {
  const ComparisonMatrixScreen({super.key});

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPlayerSelector('Player A', Colors.blueAccent),
                Text('VS', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                _buildPlayerSelector('Player B', Colors.redAccent),
              ],
            ),
            const SizedBox(height: 40),
            _buildRadarChart(),
            const SizedBox(height: 40),
            _buildStatComparison('Matches Played', '45', '42'),
            _buildStatComparison('Win Rate', '62%', '58%'),
            _buildStatComparison('Avg Points', '14.5', '13.2'),
            _buildStatComparison('Impact Score', '8.9', '8.4'),
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
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.person, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildRadarChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: RadarChart(
        RadarChartData(
          tickCount: 3,
          ticksTextStyle: const TextStyle(color: Colors.transparent),
          titlePositionPercentageOffset: 0.1,
          getTitle: (index, angle) {
            final titles = ['Speed', 'Stamina', 'Accuracy', 'Strength', 'Agility'];
            return RadarChartTitle(
              text: titles[index],
              angle: 0,
              positionPercentageOffset: 0.2,
            );
          },
          dataSets: [
            RadarDataSet(
              fillColor: Colors.blueAccent.withOpacity(0.3),
              borderColor: Colors.blueAccent,
              entryRadius: 3,
              dataEntries: [
                const RadarEntry(value: 80),
                const RadarEntry(value: 65),
                const RadarEntry(value: 90),
                const RadarEntry(value: 70),
                const RadarEntry(value: 85),
              ],
            ),
            RadarDataSet(
              fillColor: Colors.redAccent.withOpacity(0.3),
              borderColor: Colors.redAccent,
              entryRadius: 3,
              dataEntries: [
                const RadarEntry(value: 70),
                const RadarEntry(value: 85),
                const RadarEntry(value: 75),
                const RadarEntry(value: 80),
                const RadarEntry(value: 75),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatComparison(String title, String valA, String valB) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(valA, style: GoogleFonts.outfit(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: Colors.redAccent.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
              ),
              Text(valB, style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
