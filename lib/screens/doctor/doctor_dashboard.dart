// lib/screens/doctor/doctor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/test_service.dart';
import '../../services/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'package:intl/intl.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});
  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final _authService = AuthService();
  final _testService = TestService();
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppProvider>().currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await context.read<AppProvider>().signOut();
                        if (mounted) context.go('/');
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF64748B)),
                      label: const Text(
                        AppStrings.logout,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'Cairo',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const NeuroScoreLogo(fontSize: 16),
                  ],
                ),
              ),
            ),

            // ── Welcome Header ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${AppStrings.welcomeDoctor} ${user.name}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Text(
                      AppStrings.doctorDashboard,
                      textAlign: TextAlign.right,
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

            // ── Stats + Patient List ──────────────────────
            SliverToBoxAdapter(
              child: StreamBuilder<List<AppUser>>(
                stream: _authService.getDoctorPatients(user.id),
                builder: (context, snapshot) {
                  final patients = snapshot.data ?? [];

                  return FutureBuilder<Map<String, dynamic>>(
                    future: _testService.getDoctorStats(
                      user.id,
                      patients.map((p) => p.id).toList(),
                    ),
                    builder: (context, statsSnap) {
                      final stats = statsSnap.data ?? {};
                      final totalTests = stats['totalTests'] ?? 0;
                      final activePatients = stats['activePatients'] ?? 0;
                      final avgTests = (stats['avgTests'] ?? 0.0) as double;

                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Stat cards
                            _buildStatCards(
                              patients.length, totalTests, activePatients, avgTests,
                            ),
                            const SizedBox(height: 28),

                            // Search + Patient list header
                            SectionHeader(title: AppStrings.patientsList),
                            const SizedBox(height: 14),
                            _buildSearchBar(),
                            const SizedBox(height: 16),

                            // Patient list
                            if (patients.isEmpty)
                              const EmptyState(
                                message: 'لا يوجد مرضى مسجلون بعد\nشارك رابط التسجيل مع مرضاك',
                                icon: Icons.people_outline,
                              )
                            else
                              _buildPatientList(patients),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(int total, int tests, int active, double avg) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: StatCard(
              label: AppStrings.totalPatients,
              value: total.toString(),
              icon: Icons.people_alt_outlined,
              color: AppTheme.primary,
            )),
            const SizedBox(width: 12),
            Expanded(child: StatCard(
              label: AppStrings.completedTests,
              value: tests.toString(),
              icon: Icons.assignment_outlined,
              color: AppTheme.secondary,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: StatCard(
              label: AppStrings.activeCases,
              value: active.toString(),
              icon: Icons.monitor_heart_outlined,
              color: AppTheme.warning,
            )),
            const SizedBox(width: 12),
            Expanded(child: StatCard(
              label: AppStrings.avgTests,
              value: avg.toStringAsFixed(1),
              icon: Icons.trending_up_rounded,
              color: AppTheme.accent,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      textAlign: TextAlign.right,
      onChanged: (v) => setState(() => _query = v.toLowerCase()),
      decoration: InputDecoration(
        hintText: AppStrings.searchPatient,
        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPatientList(List<AppUser> patients) {
    final filtered = _query.isEmpty
        ? patients
        : patients.where((p) =>
            p.name.toLowerCase().contains(_query) ||
            p.email.toLowerCase().contains(_query)).toList();

    if (filtered.isEmpty) {
      return const EmptyState(
        message: 'لا توجد نتائج مطابقة للبحث',
        icon: Icons.search_off,
      );
    }

    return Column(
      children: filtered.map((patient) => _PatientCard(
        patient: patient,
        onTap: () => context.push('/doctor/patient/${patient.id}'),
      )).toList(),
    );
  }
}

// ─── Patient Card ─────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final AppUser patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: Color(0xFFCBD5E1),
            ),
            const Spacer(),
            Expanded(
              flex: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    patient.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      fontFamily: 'Cairo',
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        patient.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${patient.age} سنة • ${patient.genderLabel}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AvatarCircle(initials: patient.initials, size: 44),
          ],
        ),
      ),
    );
  }
}
