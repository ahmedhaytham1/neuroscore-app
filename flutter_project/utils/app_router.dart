// lib/utils/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/user_model.dart';

// Screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/doctor/doctor_dashboard.dart';
import '../screens/doctor/patient_detail_screen.dart';
import '../screens/patient/patient_dashboard.dart';
import '../screens/patient/progress_screen.dart';
import '../screens/patient/tests/tandem_walk_screen.dart';
import '../screens/patient/tests/finger_nose_screen.dart';
import '../screens/patient/tests/romberg_screen.dart';
import '../screens/patient/tests/drawing_test_screen.dart';
import '../screens/patient/tests/memory_test_screen.dart';
import '../screens/patient/tests/finger_tapping_screen.dart';
import '../screens/patient/tests/mood_questionnaire_screen.dart';
import '../screens/patient/tests/fatigue_questionnaire_screen.dart';
import '../screens/patient/tests/gait_analysis_screen.dart';

class AppRouter {
  static GoRouter router(AppProvider provider) => GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = provider.currentUser != null;
      final isAuth = state.matchedLocation == '/' ||
          state.matchedLocation == '/signup';
      if (!loggedIn && !isAuth) return '/';
      if (loggedIn && isAuth) {
        return provider.isDoctor ? '/doctor' : '/patient';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),

      // Doctor routes
      GoRoute(
        path: '/doctor',
        builder: (_, __) => const DoctorDashboard(),
        routes: [
          GoRoute(
            path: 'patient/:id',
            builder: (_, state) =>
                PatientDetailScreen(patientId: state.pathParameters['id']!),
          ),
        ],
      ),

      // Patient routes
      GoRoute(
        path: '/patient',
        builder: (_, __) => const PatientDashboard(),
        routes: [
          GoRoute(path: 'progress', builder: (_, __) => const ProgressScreen()),
          GoRoute(path: 'test/tandem', builder: (_, __) => const TandemWalkScreen()),
          GoRoute(path: 'test/finger-nose', builder: (_, __) => const FingerNoseScreen()),
          GoRoute(path: 'test/romberg', builder: (_, __) => const RombergScreen()),
          GoRoute(path: 'test/drawing', builder: (_, __) => const DrawingTestScreen()),
          GoRoute(path: 'test/memory', builder: (_, __) => const MemoryTestScreen()),
          GoRoute(path: 'test/tapping', builder: (_, __) => const FingerTappingScreen()),
          GoRoute(path: 'test/mood', builder: (_, __) => const MoodQuestionnaireScreen()),
          GoRoute(path: 'test/fatigue', builder: (_, __) => const FatigueQuestionnaireScreen()),
          GoRoute(path: 'test/gait', builder: (_, __) => const GaitAnalysisScreen()),
        ],
      ),
    ],
  );
}
