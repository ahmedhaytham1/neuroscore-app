// lib/services/ai_service.dart — NeuroScore AI bridge (Flutter → Python server)
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/user_model.dart';

class AIAnalysisResult {
  final double score;
  final String label;
  final double confidence;
  final double pHealthy;
  final double pPatient;
  final Map<String, dynamic> features;
  final Map<String, dynamic> chartData;
  final int framesUsed;
  final String analysis;
  final bool isDemoMode;
  final String? error;

  const AIAnalysisResult({
    required this.score, required this.label, required this.confidence,
    required this.pHealthy, required this.pPatient, required this.features,
    this.chartData = const {}, required this.framesUsed, required this.analysis,
    this.isDemoMode = false, this.error,
  });

  bool get isHealthy => label == 'HEALTHY';

  AIAnalysisResult copyWithError(String message) => AIAnalysisResult(
    score: score, label: label, confidence: confidence,
    pHealthy: pHealthy, pPatient: pPatient, features: features,
    chartData: chartData, framesUsed: framesUsed,
    analysis: '$analysis\n\n⚠️ $message',
    isDemoMode: true, error: message,
  );

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json, TestType testType) {
    final score      = (json['score']      as num?)?.toDouble() ?? 0.0;
    final label      = json['label']       as String? ?? 'HEALTHY';
    final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;
    final pHealthy   = (json['p_healthy']  as num?)?.toDouble() ?? 0.0;
    final pPatient   = (json['p_patient']  as num?)?.toDouble() ?? 0.0;
    final features   = Map<String, dynamic>.from(json['features'] ?? {});
    final chartData  = Map<String, dynamic>.from(json['chart_data'] ?? {});
    final frames     = (json['frames_used'] as num?)?.toInt() ?? 0;
    return AIAnalysisResult(
      score: score, label: label, confidence: confidence,
      pHealthy: pHealthy, pPatient: pPatient, features: features,
      chartData: chartData, framesUsed: frames,
      analysis: _arabicSummary(testType, score, label, features),
      error: json['error'] as String?,
    );
  }

  factory AIAnalysisResult.demo(TestType testType) {
    const scores = {
      TestType.tandemWalk: 72.0, TestType.fingerToNose: 68.0,
      TestType.romberg: 75.0,    TestType.gaitAnalysis: 65.0,
    };
    final s = scores[testType] ?? 70.0;
    return AIAnalysisResult(
      score: s, label: s >= 60 ? 'HEALTHY' : 'PATIENT',
      confidence: 65.0, pHealthy: s / 100, pPatient: 1 - s / 100,
      features: {}, chartData: {}, framesUsed: 0,
      analysis: '${_arabicSummary(testType, s, s >= 60 ? "HEALTHY" : "PATIENT", {})}\n[وضع التجربة]',
      isDemoMode: true,
    );
  }

  static String _arabicSummary(TestType t, double score, String label, Map feats) {
    final level = score >= 80 ? 'ممتاز' : score >= 60 ? 'طبيعي' : 'يحتاج متابعة';
    final pct   = score.toStringAsFixed(0);
    switch (t) {
      case TestType.fingerToNose:
        final j = feats['Jitter'] ?? 0.0;
        return 'اختبار الأنف بالإصبع: $level ($pct%)\n'
            '${j < 0.05 ? "رعشة منخفضة — تنسيق ممتاز" : j < 0.12 ? "رعشة خفيفة" : "رعشة مرتفعة — راجع طبيبك"}';
      case TestType.romberg:
        final sw = feats['hip_osc_range'] ?? feats['sh_tilt_range'] ?? 0.0;
        return 'اختبار رومبيرغ: $level ($pct%)\n'
            '${sw < 5 ? "تذبذب منخفض — توازن ممتاز" : sw < 15 ? "تذبذب خفيف — طبيعي" : "تذبذب مرتفع — ضعف في التوازن"}';
      case TestType.tandemWalk:
      case TestType.gaitAnalysis:
        final sw2 = feats['step_width_mean'] ?? 0.0;
        return 'تحليل المشي: $level ($pct%)\n'
            '${sw2 < 8 ? "خطوة ضيقة — مشي ممتاز" : sw2 < 20 ? "عرض خطوة طبيعي" : "عرض خطوة مرتفع — صعوبة في التوازن"}';
      default:
        return '${t.label}: $level ($pct%)';
    }
  }
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Local Android emulator: http://10.0.2.2:8000
  // After Render deploy, replace with: https://YOUR-RENDER-SERVICE.onrender.com
  static const String serverUrl = 'https://YOUR-RENDER-SERVICE.onrender.com';

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(minutes: 3),
  ));

  bool _available = false;

  Future<bool> checkServer() async {
    try {
      final r = await _dio.get('$serverUrl/health');
      _available = r.statusCode == 200;
      return _available;
    } catch (_) { _available = false; return false; }
  }

  Future<AIAnalysisResult> analyzeVideo({
    required File videoFile,
    required TestType testType,
  }) async {
    if (!testType.requiresAI) throw ArgumentError('$testType has no AI endpoint');
    if (!_available) await checkServer();
    if (!_available)  return AIAnalysisResult.demo(testType);

    try {
      final resp = await _dio.post(
        '$serverUrl${_endpoint(testType)}',
        data: FormData.fromMap({
          'video': await MultipartFile.fromFile(videoFile.path, filename: 'video.mp4'),
        }),
      );
      if (resp.statusCode == 200) {
        return AIAnalysisResult.fromJson(resp.data as Map<String, dynamic>, testType);
      }
      throw Exception('HTTP ${resp.statusCode}');
    } on DioException catch (e) {
      _available = false;
      final msg = e.response?.data?.toString() ?? e.message ?? 'Server connection failed';
      return AIAnalysisResult.demo(testType).copyWithError(msg);
    }
  }

  String _endpoint(TestType t) => {
    TestType.fingerToNose: '/analyze/finger',
    TestType.romberg:      '/analyze/romberg',
    TestType.tandemWalk:   '/analyze/tandem',
    TestType.gaitAnalysis: '/analyze/gait',
  }[t]!;

  void dispose() => _dio.close();
}
