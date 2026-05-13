// lib/screens/patient/tests/finger_tapping_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../services/app_provider.dart';
import '../../../services/test_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/shared_widgets.dart';

class FingerTappingScreen extends StatefulWidget {
  const FingerTappingScreen({super.key});
  @override
  State<FingerTappingScreen> createState() => _FingerTappingScreenState();
}

enum _TapPhase { ready, running, done }

class _FingerTappingScreenState extends State<FingerTappingScreen> {
  static const int _totalSeconds = 10;

  _TapPhase _phase = _TapPhase.ready;
  int _taps = 0;
  int _remaining = _totalSeconds;
  Timer? _timer;
  double? _score;

  void _start() {
    setState(() { _phase = _TapPhase.running; _taps = 0; _remaining = _totalSeconds; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        _finish();
      }
    });
  }

  void _tap() {
    if (_phase != _TapPhase.running) return;
    HapticFeedback.lightImpact();
    setState(() => _taps++);
  }

  Future<void> _finish() async {
    // Score: normalize to 0–100 based on expected ~60 taps in 10s for healthy adults
    final score = (_taps / 60 * 100).clamp(0.0, 100.0);

    final user = context.read<AppProvider>().currentUser!;
    await TestService().saveResult(
      patientId: user.id,
      patientName: user.name,
      doctorId: user.doctorId ?? '',
      testType: TestType.fingerTapping,
      score: score,
      metadata: {'tapCount': _taps, 'durationSeconds': _totalSeconds},
    );

    setState(() { _phase = _TapPhase.done; _score = score; });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text(AppStrings.fingerTapping), leading: const BackButton()),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _phase == _TapPhase.ready
            ? _buildReady()
            : _phase == _TapPhase.running
                ? _buildRunning()
                : _buildResult(),
      ),
    );
  }

  Widget _buildReady() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.touch_app_outlined, color: Color(0xFFEF4444), size: 40),
        ),
        const SizedBox(height: 24),
        const Text(
          'اضغط بإصبعك بأسرع ما يمكن',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 12),
        const Text(
          'ستبدأ مؤقت 10 ثوانٍ عند الضغط على "ابدأ"\nاضغط على الزر الكبير بأسرع ما يمكن',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Cairo', height: 1.6),
        ),
        const SizedBox(height: 40),
        GradientButton(label: 'ابدأ الاختبار', onTap: _start),
      ],
    );
  }

  Widget _buildRunning() {
    final progress = _remaining / _totalSeconds;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Timer ring
        SizedBox(
          width: 120, height: 120,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(
                _remaining <= 3 ? AppTheme.error : AppTheme.primary,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_remaining',
                  style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                    color: _remaining <= 3 ? AppTheme.error : const Color(0xFF1E293B),
                  )),
                const Text('ثانية', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'Cairo')),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 32),
        // Tap count
        Text(
          '$_taps',
          style: const TextStyle(
            fontSize: 64, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: AppTheme.primary,
          ),
        ),
        const Text('نقرة', style: TextStyle(fontSize: 16, color: Color(0xFF64748B), fontFamily: 'Cairo')),
        const SizedBox(height: 40),
        // Big tap button
        GestureDetector(
          onTap: _tap,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'اضغط\nهنا',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo', height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              const Text('نتيجة اختبار النقر',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
              const SizedBox(height: 24),
              SizedBox(
                width: 120, height: 120,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: (_score ?? 0) / 100,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFEF4444)),
                  ),
                  Text('${_score?.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444), fontFamily: 'Cairo')),
                ]),
              ),
              const SizedBox(height: 20),
              Text(
                '$_taps نقرة في 10 ثوانٍ',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 8),
              Text(
                _taps >= 50
                  ? 'ممتاز! سرعة نقر عالية'
                  : _taps >= 35
                      ? 'جيد - سرعة نقر طبيعية'
                      : 'يحتاج متابعة - سرعة نقر منخفضة',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Cairo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(label: 'العودة للاختبارات', onTap: () => context.pop()),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _phase = _TapPhase.ready),
          child: const Text('إعادة الاختبار', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    );
  }
}
