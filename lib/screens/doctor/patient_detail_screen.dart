// lib/screens/doctor/patient_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/test_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final testService = TestService();

    return FutureBuilder<AppUser>(
      future: authService.getUser(patientId),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final patient = userSnap.data!;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text('د. ${patient.name}'),
            leading: const BackButton(),
          ),
          body: StreamBuilder<List<TestResult>>(
            stream: testService.getPatientTests(patientId),
            builder: (context, snap) {
              final tests = snap.data ?? [];
              return _PatientDetailBody(patient: patient, tests: tests);
            },
          ),
        );
      },
    );
  }
}

class _PatientDetailBody extends StatelessWidget {
  final AppUser patient;
  final List<TestResult> tests;

  const _PatientDetailBody({required this.patient, required this.tests});

  Map<TestType, List<TestResult>> get _byType {
    final map = <TestType, List<TestResult>>{};
    for (final t in tests) {
      map.putIfAbsent(t.testType, () => []).add(t);
    }
    return map;
  }

  double get _avgScore {
    if (tests.isEmpty) return 0;
    return tests.fold(0.0, (s, t) => s + t.score) / tests.length;
  }

  @override
  Widget build(BuildContext context) {
    final byType = _byType;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Patient info card
          _buildInfoCard(),
          const SizedBox(height: 20),

          // Stats row
          _buildStatsRow(byType),
          const SizedBox(height: 24),

          // Bar chart - test distribution
          if (byType.isNotEmpty) ...[
            const SectionHeader(title: 'توزيع الاختبارات'),
            const SizedBox(height: 14),
            _buildBarChart(byType),
            const SizedBox(height: 24),
          ],

          // Line charts per test type
          ...byType.entries
              .where((e) => e.value.length > 1)
              .map((e) => Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SectionHeader(title: 'تطور ${e.key.label}'),
                      const SizedBox(height: 10),
                      _buildLineChart(e.value, AppTheme.testColors[e.key.index % AppTheme.testColors.length]),
                      const SizedBox(height: 20),
                    ],
                  )),

          // Test history
          const SectionHeader(title: AppStrings.testHistory),
          const SizedBox(height: 14),
          if (tests.isEmpty)
            const EmptyState(message: 'لم يجرِ هذا المريض أي اختبارات بعد', icon: Icons.assignment_outlined)
          else
            ...tests.map((t) => _TestHistoryTile(result: t)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${patient.age} سنة • ${patient.genderLabel}',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo', fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  patient.email,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontFamily: 'Cairo', fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              patient.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<TestType, List<TestResult>> byType) {
    return Row(
      children: [
        Expanded(child: StatCard(
          label: AppStrings.totalTests,
          value: tests.length.toString(),
          icon: Icons.assignment_outlined,
          color: AppTheme.primary,
        )),
        const SizedBox(width: 10),
        Expanded(child: StatCard(
          label: AppStrings.testTypes,
          value: byType.length.toString(),
          icon: Icons.category_outlined,
          color: AppTheme.secondary,
        )),
        const SizedBox(width: 10),
        Expanded(child: StatCard(
          label: 'متوسط النتائج',
          value: '${_avgScore.toStringAsFixed(0)}%',
          icon: Icons.bar_chart_rounded,
          color: AppTheme.warning,
        )),
      ],
    );
  }

  Widget _buildBarChart(Map<TestType, List<TestResult>> byType) {
    final entries = byType.entries.toList();
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= entries.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entries[idx].key.label.substring(0, 3),
                      style: const TextStyle(fontSize: 8, fontFamily: 'Cairo'),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((e) {
            final idx = e.key;
            final results = e.value.value;
            final avg = results.fold(0.0, (s, r) => s + r.score) / results.length;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: results.length.toDouble(),
                  color: AppTheme.primary.withOpacity(0.7),
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: avg,
                  color: AppTheme.secondary.withOpacity(0.7),
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<TestResult> results, Color color) {
    final sorted = List<TestResult>.from(results)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: const Color(0xFFE2E8F0),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= sorted.length) return const SizedBox();
                  return Text(
                    DateFormat('d/M').format(sorted[idx].completedAt),
                    style: const TextStyle(fontSize: 9, fontFamily: 'Cairo', color: Color(0xFF94A3B8)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: sorted.asMap().entries.map((e) =>
                FlSpot(e.key.toDouble(), e.value.score)).toList(),
              isCurved: true,
              color: color,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestHistoryTile extends StatelessWidget {
  final TestResult result;
  const _TestHistoryTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ScoreBadge(score: result.score),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.testName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('dd/MM/yyyy • HH:mm').format(result.completedAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
