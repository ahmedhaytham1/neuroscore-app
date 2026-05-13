// lib/screens/patient/tests/drawing_test_screen.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../services/app_provider.dart';
import '../../../services/test_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/shared_widgets.dart';

class DrawingTestScreen extends StatefulWidget {
  const DrawingTestScreen({super.key});
  @override
  State<DrawingTestScreen> createState() => _DrawingTestScreenState();
}

class _DrawingTestScreenState extends State<DrawingTestScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _submitted = false;
  double? _score;

  void _onPanStart(DragStartDetails d) {
    setState(() => _currentStroke = [d.localPosition]);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _currentStroke.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _strokes.add(List.from(_currentStroke));
      _currentStroke = [];
    });
  }

  void _clear() => setState(() { _strokes.clear(); _currentStroke = []; });

  Future<void> _submit() async {
    if (_strokes.isEmpty) return;

    // Score: based on smoothness + coverage
    final score = _calculateScore();

    final user = context.read<AppProvider>().currentUser!;
    await TestService().saveResult(
      patientId: user.id,
      patientName: user.name,
      doctorId: user.doctorId ?? '',
      testType: TestType.drawing,
      score: score,
      metadata: {
        'strokeCount': _strokes.length,
        'totalPoints': _strokes.fold(0, (s, st) => s + st.length),
      },
    );

    setState(() { _submitted = true; _score = score; });
  }

  double _calculateScore() {
    if (_strokes.isEmpty) return 0;
    final allPoints = _strokes.expand((s) => s).toList();
    if (allPoints.length < 10) return 30;

    // Smoothness: average distance between consecutive points
    double totalDist = 0;
    int count = 0;
    for (final stroke in _strokes) {
      for (int i = 1; i < stroke.length; i++) {
        totalDist += (stroke[i] - stroke[i - 1]).distance;
        count++;
      }
    }
    final avgDist = count > 0 ? totalDist / count : 0;
    // Lower avg distance = smoother = better
    final smoothness = (1 - (avgDist / 20).clamp(0.0, 1.0)) * 50;

    // Coverage: spread of points
    final xs = allPoints.map((p) => p.dx).toList();
    final ys = allPoints.map((p) => p.dy).toList();
    final spread = (xs.reduce(max) - xs.reduce(min) + ys.reduce(max) - ys.reduce(min)) / 2;
    final coverage = (spread / 150).clamp(0.0, 1.0) * 50;

    return (smoothness + coverage).clamp(0.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text(AppStrings.drawing), leading: const BackButton()),
      body: _submitted ? _buildResult() : _buildCanvas(),
    );
  }

  Widget _buildCanvas() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'ارسم شكلاً حلزونياً من المركز للخارج',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontFamily: 'Cairo', color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'ارسم بإصبعك على الشاشة',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 20),

          // Canvas
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              ),
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(
                    painter: _DrawingPainter(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.clear),
                  label: const Text('مسح', style: TextStyle(fontFamily: 'Cairo')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: GradientButton(
                  label: 'تقديم الرسم',
                  onTap: _strokes.isEmpty ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Text('نتيجة اختبار الرسم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
                const SizedBox(height: 24),
                SizedBox(
                  width: 120, height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: (_score ?? 0) / 100,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                      ),
                      Text(
                        '${_score?.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981), fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _score! >= 80
                    ? 'ممتاز! سلاسة وتحكم حركي ممتاز'
                    : _score! >= 60
                        ? 'جيد - بعض الاهتزاز في الرسم'
                        : 'يحتاج متابعة - ضعف في التحكم الحركي',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontFamily: 'Cairo'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(label: 'العودة للاختبارات', onTap: () => context.pop()),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _DrawingPainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw spiral guide (faint)
    final guidePaint = Paint()
      ..color = Colors.blue.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();
    for (double t = 0; t < 4 * pi; t += 0.05) {
      final r = 10 + t * 12;
      final x = center.dx + r * cos(t);
      final y = center.dy + r * sin(t);
      if (t == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, guidePaint);

    final paint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> pts) {
      if (pts.isEmpty) return;
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final pt in pts.skip(1)) p.lineTo(pt.dx, pt.dy);
      canvas.drawPath(p, paint);
    }

    for (final s in strokes) drawStroke(s);
    drawStroke(currentStroke);
  }

  @override
  bool shouldRepaint(_DrawingPainter old) => true;
}
