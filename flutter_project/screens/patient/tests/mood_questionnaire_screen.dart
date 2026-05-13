// lib/screens/patient/tests/mood_questionnaire_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../services/app_provider.dart';
import '../../../services/test_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/shared_widgets.dart';

// ─── Shared questionnaire widget ─────────────────────────────

class _QuestionnaireScreen extends StatefulWidget {
  final String title;
  final List<String> questions;
  final TestType testType;
  final Color color;
  final IconData icon;

  const _QuestionnaireScreen({
    required this.title,
    required this.questions,
    required this.testType,
    required this.color,
    required this.icon,
  });

  @override
  State<_QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<_QuestionnaireScreen> {
  late List<int?> _answers;
  bool _submitted = false;
  double? _score;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.questions.length, null);
  }

  bool get _allAnswered => _answers.every((a) => a != null);

  Future<void> _submit() async {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('يرجى الإجابة على جميع الأسئلة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _saving = true);

    final avg = _answers.fold(0, (s, a) => s + (a ?? 0)) / _answers.length;
    final score = avg * 20.0; // 1–5 scale → 0–100

    final user = context.read<AppProvider>().currentUser!;
    await TestService().saveResult(
      patientId: user.id,
      patientName: user.name,
      doctorId: user.doctorId ?? '',
      testType: widget.testType,
      score: score,
      metadata: {
        'answers': _answers,
        'avgRating': avg,
      },
    );

    setState(() { _submitted = true; _score = score; _saving = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(widget.title), leading: const BackButton()),
      body: _submitted ? _buildResult() : _buildQuestions(),
    );
  }

  Widget _buildQuestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                      color: widget.color,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(widget.icon, color: widget.color, size: 28),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أجب على الأسئلة التالية على مقياس من 1 إلى 5',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 20),

          ...widget.questions.asMap().entries.map((e) =>
            _QuestionCard(
              index: e.key + 1,
              question: e.value,
              answer: _answers[e.key],
              color: widget.color,
              onAnswered: (v) => setState(() => _answers[e.key] = v),
            )
          ),

          const SizedBox(height: 28),
          GradientButton(
            label: 'تقديم الإجابات',
            isLoading: _saving,
            onTap: _submit,
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
                Text(
                  'نتيجة ${widget.title}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 130, height: 130,
                  child: Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(
                      value: (_score ?? 0) / 100,
                      strokeWidth: 10,
                      backgroundColor: widget.color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(widget.color),
                    ),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('${_score?.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                          color: widget.color, fontFamily: 'Cairo')),
                      const Text('النتيجة', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'Cairo')),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),
                Text(
                  _score! >= 70
                    ? 'حالتك جيدة 😊 استمر في المتابعة'
                    : _score! >= 40
                        ? 'حالتك متوسطة - تحدث مع طبيبك'
                        : 'يُنصح بالتواصل مع طبيبك',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontFamily: 'Cairo', color: Color(0xFF475569)),
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

class _QuestionCard extends StatelessWidget {
  final int index;
  final String question;
  final int? answer;
  final Color color;
  final ValueChanged<int> onAnswered;

  const _QuestionCard({
    required this.index, required this.question, required this.answer,
    required this.color, required this.onAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: answer != null ? color.withOpacity(0.3) : const Color(0xFFE2E8F0),
          width: answer != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$index. $question',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontFamily: 'Cairo', fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final v = i + 1;
              final selected = answer == v;
              return GestureDetector(
                onTap: () => onAnswered(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? color : color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$v',
                      style: TextStyle(
                        color: selected ? Colors.white : color,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ممتاز جداً', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontFamily: 'Cairo')),
              const Text('سيئ جداً', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontFamily: 'Cairo')),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Mood Screen ──────────────────────────────────────────────
class MoodQuestionnaireScreen extends StatelessWidget {
  const MoodQuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) => _QuestionnaireScreen(
    title: AppStrings.mood,
    testType: TestType.mood,
    color: const Color(0xFF6366F1),
    icon: Icons.mood_outlined,
    questions: const [
      'كيف تشعر بمزاجك اليوم؟',
      'هل تشعر بالحزن أو الاكتئاب؟',
      'هل تشعر بالقلق أو التوتر؟',
      'هل لديك طاقة للقيام بالأنشطة اليومية؟',
      'هل تنام جيداً؟',
    ],
  );
}

// ─── Fatigue Screen ───────────────────────────────────────────
class FatigueQuestionnaireScreen extends StatelessWidget {
  const FatigueQuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) => _QuestionnaireScreen(
    title: AppStrings.fatigue,
    testType: TestType.fatigue,
    color: const Color(0xFFEC4899),
    icon: Icons.battery_alert_outlined,
    questions: const [
      'إلى أي مدى تشعر بالإرهاق اليوم؟',
      'هل تشعر بالتعب عند القيام بأنشطة بسيطة؟',
      'هل يؤثر الإرهاق على تركيزك؟',
      'هل تحتاج للراحة أكثر من المعتاد؟',
      'هل تشعر بالإرهاق عند الاستيقاظ؟',
    ],
  );
}
