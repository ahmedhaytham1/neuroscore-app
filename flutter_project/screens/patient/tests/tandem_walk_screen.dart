// lib/screens/patient/tests/tandem_walk_screen.dart
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import 'video_test_base.dart';

class TandemWalkScreen extends StatelessWidget {
  const TandemWalkScreen({super.key});
  @override
  Widget build(BuildContext context) => const VideoTestScreen(
    title:       'اختبار المشي المتتالي',
    instruction: 'امشِ على خط مستقيم 10 خطوات',
    detail:      'ضع كعب قدمك أمام أصابع القدم الأخرى في خط مستقيم وامشِ 10 خطوات.',
    testType:    TestType.tandemWalk,
    color:       Color(0xFF3B82F6),
    icon:        Icons.directions_walk,
    tips: [
      'ارسم أو ضع شريطاً لاصقاً على الأرض كخط مستقيم',
      'صوِّر من الجانب بحيث يظهر جسمك كاملاً من الرأس للقدم',
      'امشِ بسرعة طبيعية، لا تسرع ولا تبطئ',
      'مدة التسجيل: 15 ثانية على الأقل',
    ],
  );
}

class FingerNoseScreen extends StatelessWidget {
  const FingerNoseScreen({super.key});
  @override
  Widget build(BuildContext context) => const VideoTestScreen(
    title:       'اختبار الأنف بالإصبع',
    instruction: 'المس أنفك بإصبعك السبابة عدة مرات',
    detail:      'مد ذراعك بالكامل ثم ألمس طرف أنفك. كرر 5 مرات لكل يد.',
    testType:    TestType.fingerToNose,
    color:       Color(0xFF06B6D4),
    icon:        Icons.back_hand_outlined,
    tips: [
      'صوِّر من الأمام بحيث تظهر يدك ووجهك بوضوح',
      'أبعد ذراعك بالكامل قبل كل لمسة',
      'اعمل الحركة بشكل طبيعي، لا تتعمد الإبطاء',
      'مدة التسجيل: 20 ثانية على الأقل لكل يد',
    ],
  );
}

class RombergScreen extends StatelessWidget {
  const RombergScreen({super.key});
  @override
  Widget build(BuildContext context) => const VideoTestScreen(
    title:       'اختبار رومبيرغ',
    instruction: 'قف مستقيماً وأغلق عينيك 10 ثوانٍ',
    detail:      'قف بقدمين متلاصقتين وذراعين على الجانبين، ثم أغلق عينيك.',
    testType:    TestType.romberg,
    color:       Color(0xFF8B5CF6),
    icon:        Icons.remove_red_eye_outlined,
    tips: [
      'اطلب من شخص آخر يقف بجانبك لضمان سلامتك',
      'صوِّر من الأمام بحيث يظهر جسمك كاملاً',
      'قدماك متلاصقتان، ذراعاك على الجانبين',
      'ابقَ ثابتاً قدر الإمكان بعد إغلاق عينيك',
    ],
  );
}

class GaitAnalysisScreen extends StatelessWidget {
  const GaitAnalysisScreen({super.key});
  @override
  Widget build(BuildContext context) => const VideoTestScreen(
    title:       'تحليل المشي المفصل',
    instruction: 'امشِ بشكل طبيعي لمسافة 6 أمتار ذهاباً وإياباً',
    detail:      'المشي الطبيعي يساعد الذكاء الاصطناعي على تحليل نمط مشيتك بدقة.',
    testType:    TestType.gaitAnalysis,
    color:       Color(0xFF14B8A6),
    icon:        Icons.accessibility_new_outlined,
    tips: [
      'صوِّر من الجانب لالتقاط حركة الجسم كاملة',
      'تأكد أن قدميك تظهران في الفيديو',
      'امشِ بشكل طبيعي تماماً كما تمشي عادةً',
      'مدة التسجيل: 30 ثانية على الأقل',
    ],
  );
}
