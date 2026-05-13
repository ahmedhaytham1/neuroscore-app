// lib/screens/patient/tests/video_test_base.dart
//
// الشاشة الكاملة لكل اختبار فيديو + AI
// المريض يفتح الشاشة → يسجّل/يرفع فيديو → يضغط تحليل
// → Flutter يبعته للـ Python server → يستقبل النتيجة → يعرضها → يحفظها في Firebase

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../models/user_model.dart';
import '../../../services/ai_service.dart';
import '../../../services/app_provider.dart';
import '../../../services/test_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/shared_widgets.dart';

// مراحل الشاشة
enum _Phase { idle, previewing, analyzing, result, error }

class VideoTestScreen extends StatefulWidget {
  final String title;
  final String instruction;
  final String detail;
  final List<String> tips;   // نصائح قبل التسجيل
  final TestType testType;
  final Color color;
  final IconData icon;

  const VideoTestScreen({
    super.key,
    required this.title,
    required this.instruction,
    required this.detail,
    required this.testType,
    required this.color,
    required this.icon,
    this.tips = const [],
  });

  @override
  State<VideoTestScreen> createState() => _VideoTestScreenState();
}

class _VideoTestScreenState extends State<VideoTestScreen>
    with SingleTickerProviderStateMixin {
  final _picker      = ImagePicker();
  final _aiService   = AIService();
  final _testService = TestService();

  File?                    _videoFile;
  VideoPlayerController?   _playerCtrl;
  _Phase                   _phase = _Phase.idle;
  AIAnalysisResult?        _result;
  String?                  _errorMsg;
  String                   _analysisStep = 'جارٍ رفع الفيديو...';
  late AnimationController _spinCtrl;

  // خطوات التحليل التي تظهر للمريض أثناء الانتظار
  static const List<String> _analysisSteps = [
    'جارٍ رفع الفيديو...',
    'يتم استخراج الإطارات...',
    'تحليل حركة الجسم بـ MediaPipe...',
    'حساب المؤشرات الطبية...',
    'تشغيل نموذج الذكاء الاصطناعي...',
    'تجهيز النتيجة...',
  ];
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _playerCtrl?.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  // ── 1. اختيار الفيديو ──────────────────────────────────────
  Future<void> _pickVideo(ImageSource source) async {
    try {
      final xFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 90),
      );
      if (xFile == null) return;

      final file = File(xFile.path);
      final ctrl = VideoPlayerController.file(file);
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.play();

      setState(() {
        _videoFile = file;
        _playerCtrl?.dispose();
        _playerCtrl = ctrl;
        _phase      = _Phase.previewing;
        _errorMsg   = null;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'فشل في فتح الفيديو: $e';
        _phase = _Phase.error;
      });
    }
  }

  // ── 2. التحليل الكامل ──────────────────────────────────────
  Future<void> _analyze() async {
    if (_videoFile == null) return;

    // إيقاف الفيديو وبدء التحليل
    _playerCtrl?.pause();
    setState(() {
      _phase      = _Phase.analyzing;
      _stepIndex  = 0;
      _analysisStep = _analysisSteps[0];
    });

    // تحديث خطوات التحليل كل ثانيتين (UI feedback للمريض)
    final stepTimer = Stream.periodic(const Duration(seconds: 2), (i) => i)
        .take(_analysisSteps.length - 1)
        .listen((i) {
      if (mounted) {
        setState(() {
          _stepIndex    = i + 1;
          _analysisStep = _analysisSteps[i + 1];
        });
      }
    });

    try {
      // ── استدعاء Python server ─────────────────────────────
      final result = await _aiService.analyzeVideo(
        videoFile: _videoFile!,
        testType:  widget.testType,
      );

      stepTimer.cancel();

      if (!mounted) return;

      // ── حفظ النتيجة في Firebase ────────────────────────
      final user = context.read<AppProvider>().currentUser!;
      await _testService.saveResult(
        patientId:   user.id,
        patientName: user.name,
        doctorId:    user.doctorId ?? '',
        testType:    widget.testType,
        score:       result.score,
        videoFile:   _videoFile,
        aiAnalysis:  result.analysis,
        metadata: {
          'label':       result.label,
          'confidence':  result.confidence,
          'p_healthy':   result.pHealthy,
          'p_patient':   result.pPatient,
          'framesUsed':  result.framesUsed,
          'isDemoMode':  result.isDemoMode,
          'features':    result.features,
        },
      );

      setState(() {
        _result = result;
        _phase  = _Phase.result;
      });
    } catch (e) {
      stepTimer.cancel();
      if (!mounted) return;
      setState(() {
        _errorMsg = 'حدث خطأ أثناء التحليل:\n$e';
        _phase    = _Phase.error;
      });
    }
  }

  // ── إعادة البداية ────────────────────────────────────────
  void _reset() {
    _playerCtrl?.dispose();
    setState(() {
      _videoFile  = null;
      _playerCtrl = null;
      _phase      = _Phase.idle;
      _result     = null;
      _errorMsg   = null;
    });
  }

  // ════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.title),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _buildPhaseContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header (always visible) ───────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(widget.icon, color: widget.color, size: 38),
        ),
        const SizedBox(height: 14),
        Text(
          widget.instruction,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700,
            fontFamily: 'Cairo', color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.detail,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13, color: Color(0xFF64748B),
            fontFamily: 'Cairo', height: 1.55,
          ),
        ),
      ],
    );
  }

  // ── Phase router ─────────────────────────────────────────
  Widget _buildPhaseContent() {
    switch (_phase) {
      case _Phase.idle:       return _buildIdle();
      case _Phase.previewing: return _buildPreviewing();
      case _Phase.analyzing:  return _buildAnalyzing();
      case _Phase.result:     return _buildResult();
      case _Phase.error:      return _buildErrorState();
    }
  }

  // ────────────────────────────────────────────────────────
  // IDLE — نصائح + زراير الاختيار
  // ────────────────────────────────────────────────────────
  Widget _buildIdle() {
    return Column(
      key: const ValueKey('idle'),
      children: [
        // نصائح قبل التسجيل
        if (widget.tips.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  const Text('قبل التسجيل', style: TextStyle(
                    fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 14)),
                  const SizedBox(width: 8),
                  Icon(Icons.tips_and_updates_outlined, color: widget.color, size: 18),
                ]),
                const SizedBox(height: 10),
                ...widget.tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(child: Text(tip, textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569),
                          fontFamily: 'Cairo', height: 1.5))),
                      const SizedBox(width: 8),
                      Container(width: 6, height: 6,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: widget.color, shape: BoxShape.circle)),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // زر التسجيل
        _pickButton(
          label: 'تسجيل فيديو الآن',
          subtitle: 'استخدم الكاميرا الأمامية أو الخلفية',
          icon: Icons.videocam_rounded,
          source: ImageSource.camera,
        ),
        const SizedBox(height: 14),

        // زر الرفع من المعرض
        _pickButton(
          label: 'رفع فيديو من الهاتف',
          subtitle: 'اختر فيديو موجود في معرض الصور',
          icon: Icons.photo_library_outlined,
          source: ImageSource.gallery,
        ),
      ],
    );
  }

  Widget _pickButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required ImageSource source,
  }) {
    return GestureDetector(
      onTap: () => _pickVideo(source),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.color.withOpacity(0.35), width: 1.5),
          boxShadow: [BoxShadow(
            color: widget.color.withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: widget.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15,
                fontFamily: 'Cairo', color: widget.color)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(
                fontSize: 12, color: Color(0xFF94A3B8), fontFamily: 'Cairo')),
            ],
          )),
          Icon(Icons.arrow_forward_ios_rounded, color: widget.color, size: 16),
        ]),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // PREVIEWING — معاينة الفيديو + زر التحليل
  // ────────────────────────────────────────────────────────
  Widget _buildPreviewing() {
    return Column(
      key: const ValueKey('previewing'),
      children: [
        // مشغّل الفيديو
        if (_playerCtrl != null && _playerCtrl!.value.isInitialized)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: _playerCtrl!.value.aspectRatio,
              child: Stack(children: [
                VideoPlayer(_playerCtrl!),
                // زر play/pause على الفيديو
                Positioned.fill(child: GestureDetector(
                  onTap: () => setState(() {
                    _playerCtrl!.value.isPlaying
                        ? _playerCtrl!.pause()
                        : _playerCtrl!.play();
                  }),
                  child: Container(color: Colors.transparent),
                )),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'راجع الفيديو، ثم اضغط تحليل',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 20),

        // زر التحليل الرئيسي
        GradientButton(
          label: 'تحليل بالذكاء الاصطناعي',
          onTap: _analyze,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _reset,
          child: Text('اختر فيديو آخر',
            style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Cairo', fontSize: 13)),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // ANALYZING — شاشة الانتظار
  // ────────────────────────────────────────────────────────
  Widget _buildAnalyzing() {
    return Column(
      key: const ValueKey('analyzing'),
      children: [
        const SizedBox(height: 20),
        // دائرة الـ loading المتحركة
        SizedBox(
          width: 100, height: 100,
          child: Stack(alignment: Alignment.center, children: [
            RotationTransition(
              turns: _spinCtrl,
              child: CircularProgressIndicator(
                color: widget.color, strokeWidth: 4,
                value: null,
              ),
            ),
            Icon(widget.icon, color: widget.color, size: 36),
          ]),
        ),
        const SizedBox(height: 28),
        const Text(
          'جارٍ تحليل الفيديو',
          style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700,
            fontFamily: 'Cairo', color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'قد يستغرق التحليل من 10 إلى 30 ثانية',
          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 28),

        // خطوات التحليل
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: List.generate(_analysisSteps.length, (i) {
              final done    = i < _stepIndex;
              final current = i == _stepIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  // أيقونة الحالة
                  SizedBox(width: 24, height: 24, child: done
                      ? Icon(Icons.check_circle_rounded,
                          color: widget.color, size: 20)
                      : current
                          ? SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                color: widget.color, strokeWidth: 2))
                          : Icon(Icons.radio_button_unchecked,
                              color: Colors.grey.shade300, size: 20)),
                  const SizedBox(width: 10),
                  Text(
                    _analysisSteps[i],
                    style: TextStyle(
                      fontSize: 13, fontFamily: 'Cairo',
                      color: done || current
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFCBD5E1),
                      fontWeight: current ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ]),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // RESULT — عرض النتيجة الكاملة
  // ────────────────────────────────────────────────────────
  Widget _buildResult() {
    final r = _result!;
    final isHealthy = r.isHealthy;
    final scoreColor = r.score >= 80
        ? const Color(0xFF10B981)
        : r.score >= 60
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Column(
      key: const ValueKey('result'),
      children: [
        // ── بطاقة النتيجة الرئيسية ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(
            children: [
              // عنوان + شارة الحالة
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isHealthy
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
                      color: isHealthy
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isHealthy ? 'طبيعي' : 'يحتاج متابعة',
                      style: TextStyle(
                        color: isHealthy
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                        fontSize: 13, fontFamily: 'Cairo',
                      ),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),

              // دائرة الـ score
              SizedBox(
                width: 130, height: 130,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: r.score / 100,
                    strokeWidth: 11,
                    backgroundColor: scoreColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                    strokeCap: StrokeCap.round,
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${r.score.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                        color: scoreColor, fontFamily: 'Cairo')),
                    const Text('/100', style: TextStyle(fontSize: 11,
                      color: Color(0xFF94A3B8), fontFamily: 'Cairo')),
                  ]),
                ]),
              ),
              const SizedBox(height: 18),

              // التحليل النصي العربي
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  r.analysis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13, color: Color(0xFF374151),
                    fontFamily: 'Cairo', height: 1.7,
                  ),
                ),
              ),

              // وضع التجربة badge
              if (r.isDemoMode) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                  ),
                  child: const Text(
                    '⚠️ وضع تجريبي — السيرفر غير متصل',
                    style: TextStyle(color: Color(0xFFF59E0B),
                      fontSize: 11, fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── تفاصيل التحليل (قابلة للطي) ──
        if (r.features.isNotEmpty)
          _buildFeaturesCard(r),
        const SizedBox(height: 20),

        // ── الأزرار ──
        GradientButton(
          label: 'العودة للاختبارات',
          onTap: () => context.pop(),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _reset,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: widget.color.withOpacity(0.4)),
          ),
          child: Text('إعادة الاختبار',
            style: TextStyle(fontFamily: 'Cairo', color: widget.color)),
        ),
      ],
    );
  }

  // ── بطاقة الـ features التفصيلية ──
  Widget _buildFeaturesCard(AIAnalysisResult r) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text(
            'تفاصيل التحليل الطبي',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              fontFamily: 'Cairo', color: Color(0xFF1E293B)),
          ),
          subtitle: Text(
            '${r.framesUsed} إطار تم تحليله | ثقة ${r.confidence.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            // الـ P(healthy) / P(patient) bar
            _probBar('احتمال طبيعي', r.pHealthy, const Color(0xFF10B981)),
            const SizedBox(height: 8),
            _probBar('احتمال إصابة', r.pPatient, const Color(0xFFEF4444)),
            const SizedBox(height: 14),
            // Features list
            ...r.features.entries.take(8).map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.value.toString(),
                    style: const TextStyle(fontSize: 12, fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  Text(e.key,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B),
                      fontFamily: 'Cairo')),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _probBar(String label, double value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${(value * 100).toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: color, fontFamily: 'Cairo')),
        Text(label, style: const TextStyle(fontSize: 12,
          color: Color(0xFF64748B), fontFamily: 'Cairo')),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }

  // ────────────────────────────────────────────────────────
  // ERROR STATE
  // ────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Column(
      key: const ValueKey('error'),
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.error_outline_rounded,
          color: Color(0xFFEF4444), size: 56),
        const SizedBox(height: 16),
        Text(
          _errorMsg ?? 'حدث خطأ غير متوقع',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569),
            fontFamily: 'Cairo', height: 1.6),
        ),
        const SizedBox(height: 24),
        GradientButton(label: 'حاول مرة أخرى', onTap: _reset),
      ],
    );
  }
}
