import 'package:flutter/material.dart';
import 'package:frontend/screens/table_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const _bg = Color(0xFF0D1117);
const _card = Color(0xFF161B22);
const _border = Color(0xFF30363D);
const _textPrimary = Color(0xFFE6EDF3);
const _textSecondary = Color(0xFF8B949E);
const _green = Color(0xFF238636);
const _orange = Color(0xFFF78166);
const _blue = Color(0xFF388BFD);

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? summary;
  List<Map<String, dynamic>> winCounts = [];
  List<Map<String, dynamic>> voteDist = [];
  List<Map<String, dynamic>> elimRounds = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<void> fetchAll() async {
    final results = await Future.wait([
      http.get(Uri.parse('http://localhost:8000/analytics/summary')),
      http.get(Uri.parse('http://localhost:8000/analytics/wins')),
      http.get(Uri.parse('http://localhost:8000/analytics/votes')),
      http.get(Uri.parse('http://localhost:8000/analytics/eliminations')),
    ]);
    setState(() {
      summary = jsonDecode(results[0].body);
      winCounts = List<Map<String, dynamic>>.from(jsonDecode(results[1].body));
      voteDist = List<Map<String, dynamic>>.from(jsonDecode(results[2].body));
      elimRounds = List<Map<String, dynamic>>.from(jsonDecode(results[3].body));
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : Column(
              children: [
                _TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary cards row
                        Row(
                          children: [
                            _StatCard(
                              icon: "🎮",
                              title: "TOTAL GAMES",
                              value: "${summary?['total_games'] ?? 0}",
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              icon: "🏆",
                              title: "MOST WINS",
                              value:
                                  summary?['most_frequent_winner']?['winner'] ??
                                  "N/A",
                              subtitle:
                                  "${summary?['most_frequent_winner']?['count'] ?? 0} wins",
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              icon: "🔄",
                              title: "AVG ROUNDS",
                              value: "${summary?['avg_rounds'] ?? 0}",
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Two charts side by side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ChartCard(
                                title: "Win Count",
                                subtitle:
                                    "Wins per personality across all games",
                                child: SizedBox(
                                  height: 200,
                                  child: _BarChart(
                                    data: winCounts,
                                    labelKey: 'winner',
                                    valueKey: 'count',
                                    color: _green,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ChartCard(
                                title: "Votes Received",
                                subtitle: "Times each personality was targeted",
                                child: SizedBox(
                                  height: 200,
                                  child: _BarChart(
                                    data: voteDist,
                                    labelKey: 'voted_for',
                                    valueKey: 'count',
                                    color: _orange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Full width survival chart
                        _ChartCard(
                          title: "Avg Round Survived",
                          subtitle:
                              "Higher = eliminated later = stronger performer",
                          child: SizedBox(
                            height: 200,
                            child: _BarChart(
                              data: elimRounds,
                              labelKey: 'agent',
                              valueKey: 'avg_elimination_round',
                              color: _blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "AI HUNGER GAMES",
            style: GoogleFonts.jersey10(color: _textPrimary, fontSize: 22),
          ),
          Row(
            children: [
              Text(
                "Analytics",
                style: GoogleFonts.jersey10(
                  color: _textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TableScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Data Explorer",
                    style: GoogleFonts.jersey10(
                      color: _textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "← Back",
                    style: GoogleFonts.jersey10(
                      color: _textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final String? subtitle;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.jersey10(
                    color: _textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.jersey10(color: _textPrimary, fontSize: 28),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: GoogleFonts.jersey10(
                  color: _textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.jersey10(color: _textPrimary, fontSize: 16),
          ),
          Text(
            subtitle,
            style: GoogleFonts.jersey10(color: _textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String labelKey;
  final String valueKey;
  final Color color;

  const _BarChart({
    required this.data,
    required this.labelKey,
    required this.valueKey,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "No data",
          style: GoogleFonts.jersey10(color: _textSecondary),
        ),
      );
    }

    return BarChart(
      BarChartData(
        backgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: _border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[index][labelKey],
                    style: GoogleFonts.jersey10(
                      color: _textSecondary,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: data.asMap().entries.map((e) {
          final val = e.value[valueKey];
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (val as num).toDouble(),
                color: color,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
