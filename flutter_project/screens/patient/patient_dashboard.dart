// lib/screens/patient/patient_dashboard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  static const List<_TestCardData> _tests = [
    _TestCardData(
      route: '/patient/test/tandem',
      label: AppStrings.tandemWalk,
      desc: AppStrings.tandemWalkDesc,
      icon: Icons.directions_walk,
      colorIndex: 0,
    ),
    _TestCardData(
      route: '/patient/test/finger-nose',
      label: AppStrings.fingerToNose,
      desc: AppStrings.fingerToNoseDesc,
      icon: Icons.back_hand_outlined,
      colorIndex: 1,
    ),
    _TestCardData(
      route: '/patient/test/romberg',
      label: AppStrings.romberg,
      desc: AppStrings.rombergDesc,
      icon: Icons.remove_red_eye_outlined,
      colorIndex: 2,
    ),
    _TestCardData(
      route: '/patient/test/drawing',
      label: AppStrings.drawing,
      desc: AppStrings.drawingDesc,
      icon: Icons.draw_outlined,
      colorIndex: 3,
    ),
    _TestCardData(
      route: '/patient/test/memory',
      label: AppStrings.memory,
      desc: AppStrings.memoryDesc,
      icon: Icons.psychology_outlined,
      colorIndex: 4,
    ),
    _TestCardData(
      route: '/patient/test/tapping',
      label: AppStrings.fingerTapping,
      desc: AppStrings.fingerTappingDesc,
      icon: Icons.touch_app_outlined,
      colorIndex: 5,
    ),
    _TestCardData(
      route: '/patient/test/mood',
      label: AppStrings.mood,
      desc: AppStrings.moodDesc,
      icon: Icons.mood_outlined,
      colorIndex: 6,
    ),
    _TestCardData(
      route: '/patient/test/fatigue',
      label: AppStrings.fatigue,
      desc: AppStrings.fatigueDesc,
      icon: Icons.battery_alert_outlined,
      colorIndex: 7,
    ),
    _TestCardData(
      route: '/patient/test/gait',
      label: AppStrings.gaitAnalysis,
      desc: AppStrings.gaitAnalysisDesc,
      icon: Icons.accessibility_new_outlined,
      colorIndex: 8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppProvider>().currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Progress button
                    GestureDetector(
                      onTap: () => context.push('/patient/progress'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up, size: 16, color: AppTheme.secondary),
                            const SizedBox(width: 6),
                            const Text(
                              AppStrings.progressPage,
                              style: TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const NeuroScoreLogo(fontSize: 15),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await context.read<AppProvider>().signOut();
                            if (context.mounted) context.go('/');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Welcome
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${AppStrings.welcomePatient} ${user.name}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Text(
                      AppStrings.chooseTest,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Test cards
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _TestCard(data: _tests[index]),
                  childCount: _tests.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestCardData {
  final String route;
  final String label;
  final String desc;
  final IconData icon;
  final int colorIndex;
  const _TestCardData({
    required this.route,
    required this.label,
    required this.desc,
    required this.icon,
    required this.colorIndex,
  });
}

class _TestCard extends StatelessWidget {
  final _TestCardData data;
  const _TestCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.testColors[data.colorIndex];
    return GestureDetector(
      onTap: () => context.push(data.route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Start button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withBlue(color.blue + 30)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                AppStrings.startTest,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.label,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      fontFamily: 'Cairo',
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.desc,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: color, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}
