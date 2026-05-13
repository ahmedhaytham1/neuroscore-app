// lib/screens/patient/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/app_provider.dart';
import '../../services/test_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppProvider>().currentUser!;
    final testService = TestService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(AppStrings.progressPage),
        leading: const BackButton(),
      ),
      body: StreamBuilder<List<TestResult>>(
        stream: testService.getPatientTests(user.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tests = snap.data ?? [];
          return _ProgressBody(tests: tests);
        },
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  final List<TestResult> tests;
  const _ProgressBody({required this.tests});

  Map<TestType, List<TestResult>> get _byType {
    final map = <TestType, List<TestResult>>{};
    for (final t in tests) {
      map.putIfAbsent(t.testType, () => []).add(t);
    }
    // Sort each list by date
    for (final list in map.values) {
      list.sort((a, b) => a.completedAt.compareTo(b.completedAt));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final byType = _byType;
    final lastTest = tests.isNotEmpty
        ? tests.reduce((a, b) => a.completedAt.isAfter(b.completedAt) ? a : b)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Stats
          Row(
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
                label: AppStrings.lastTest,
                value: lastTest != null
                    ? DateFormat('d/M').format(lastTest.completedAt)
                    : '—',
                icon: Icons.calendar_today_outlined,
                color: AppTheme.warning,
              )),
            ],
          ),
          const SizedBox(height: 28),

          if (tests.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: EmptyState(
                message: AppStrings.noTestsYet,
                icon: Icons.bar_chart_outlined,
              ),
            )
          else ...[
            // Line charts per test type
            ...byType.entries.map((e) => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SectionHeader(title: e.key.label),
                const SizedBox(height: 10),
                _buildLineChart(e.value, AppTheme.testColors[e.key.index % AppTheme.testColors.length]),
                const SizedBox(height: 20),
              ],
            )),

            // History list
            const SectionHeader(title: AppStrings.testHistory),
            const SizedBox(height: 14),
            ...tests.reversed.map((t) => _HistoryTile(result: t)),
          ],
        ],
      ),
    );
  }

  Widget _buildLineChart(List<TestResult> results, Color color) {
    if (results.length == 1) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ScoreBadge(score: results.first.score),
            Text(
              'اختبار واحد فقط - أجرِ المزيد لرؤية التطور',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontFamily: 'Cairo'),
            ),
          ],
        ),
      );
    }

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
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}%',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= results.length) return const SizedBox();
                  return Text(
                    DateFormat('d/M').format(results[idx].completedAt),
                    style: const TextStyle(fontSize: 9, fontFamily: 'Cairo', color: Color(0xFF94A3B8)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: results.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.score))
                  .toList(),
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

class _HistoryTile extends StatelessWidget {
  final TestResult result;
  const _HistoryTile({required this.result});

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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
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
                Text(
                  DateFormat('dd/MM/yyyy • HH:mm').format(result.completedAt),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
