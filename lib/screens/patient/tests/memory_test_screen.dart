// lib/screens/patient/tests/memory_test_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../services/app_provider.dart';
import '../../../services/test_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/shared_widgets.dart';

class MemoryTestScreen extends StatefulWidget {
  const MemoryTestScreen({super.key});
  @override
  State<MemoryTestScreen> createState() => _MemoryTestScreenState();
}

class _MemoryTestScreenState extends State<MemoryTestScreen> {
  static const List<String> _symbols = ['🧠', '⚡', '🌊', '🔥', '🌿', '💎', '🎯', '🌙'];

  late List<String> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;

  int _first = -1, _second = -1;
  bool _canFlip = true;
  int _attempts = 0;
  int _matches = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _started = false;
  bool _done = false;
  double? _score;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final pairs = [..._symbols, ..._symbols]..shuffle();
    _cards = pairs;
    _flipped = List.filled(16, false);
    _matched = List.filled(16, false);
    _first = -1; _second = -1;
    _canFlip = true;
    _attempts = 0; _matches = 0; _elapsedSeconds = 0;
    _started = false; _done = false; _score = null;
    _timer?.cancel();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
    _started = true;
  }

  void _flip(int idx) {
    if (!_canFlip) return;
    if (_flipped[idx] || _matched[idx]) return;

    if (!_started) _startTimer();

    setState(() => _flipped[idx] = true);

    if (_first == -1) {
      _first = idx;
    } else {
      _second = idx;
      _canFlip = false;
      _attempts++;

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          if (_cards[_first] == _cards[_second]) {
            _matched[_first] = true;
            _matched[_second] = true;
            _matches++;
            if (_matches == 8) _finish();
          } else {
            _flipped[_first] = false;
            _flipped[_second] = false;
          }
          _first = -1; _second = -1;
          _canFlip = true;
        });
      });
    }
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final score = (100 - (_attempts - 8) * 2).clamp(0, 100).toDouble();

    final user = context.read<AppProvider>().currentUser!;
    await TestService().saveResult(
      patientId: user.id,
      patientName: user.name,
      doctorId: user.doctorId ?? '',
      testType: TestType.memory,
      score: score,
      metadata: {'attempts': _attempts, 'timeSeconds': _elapsedSeconds},
    );

    setState(() { _done = true; _score = score; });
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
      appBar: AppBar(
        title: const Text(AppStrings.memory),
        leading: const BackButton(),
        actions: [
          if (!_done) Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_elapsedSeconds ~/ 60}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: _done ? _buildResult() : _buildGame(),
    );
  }

  Widget _buildGame() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المحاولات: $_attempts',
                style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B)),
              ),
              Text(
                'الأزواج: $_matches / 8',
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 16,
              itemBuilder: (_, idx) => _CardTile(
                symbol: _cards[idx],
                flipped: _flipped[idx],
                matched: _matched[idx],
                onTap: () => _flip(idx),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _initGame()),
            child: const Text('إعادة اللعبة', style: TextStyle(fontFamily: 'Cairo')),
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
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Text('نتيجة اختبار الذاكرة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
                const SizedBox(height: 24),
                SizedBox(
                  width: 120, height: 120,
                  child: Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(
                      value: (_score ?? 0) / 100,
                      strokeWidth: 10,
                      backgroundColor: AppTheme.warning.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(AppTheme.warning),
                    ),
                    Text('${_score?.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                        color: AppTheme.warning, fontFamily: 'Cairo')),
                  ]),
                ),
                const SizedBox(height: 20),
                _statRow('عدد المحاولات', '$_attempts محاولة'),
                const SizedBox(height: 8),
                _statRow('الوقت المستغرق',
                  '${_elapsedSeconds ~/ 60}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')} دقيقة'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(label: 'العودة للاختبارات', onTap: () => context.pop()),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _initGame()),
            child: const Text('إعادة الاختبار', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
      Text(label, style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Cairo')),
    ],
  );
}

class _CardTile extends StatelessWidget {
  final String symbol;
  final bool flipped;
  final bool matched;
  final VoidCallback onTap;

  const _CardTile({
    required this.symbol, required this.flipped,
    required this.matched, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: matched
            ? AppTheme.secondary.withOpacity(0.15)
            : flipped
                ? Colors.white
                : AppTheme.primary.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: matched
              ? AppTheme.secondary
              : flipped
                  ? const Color(0xFFE2E8F0)
                  : AppTheme.primary,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            flipped || matched ? symbol : '?',
            style: TextStyle(
              fontSize: 24,
              color: flipped || matched ? null : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
