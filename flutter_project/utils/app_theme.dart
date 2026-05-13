// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF2563EB);      // Blue
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF10B981);    // Green
  static const Color accent = Color(0xFF8B5CF6);       // Purple
  static const Color warning = Color(0xFFF59E0B);      // Orange
  static const Color error = Color(0xFFEF4444);        // Red

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Test card colors
  static const List<Color> testColors = [
    Color(0xFF3B82F6), // blue - tandem walk
    Color(0xFF06B6D4), // cyan - finger to nose
    Color(0xFF8B5CF6), // purple - romberg
    Color(0xFF10B981), // green - drawing
    Color(0xFFF59E0B), // amber - memory
    Color(0xFFEF4444), // red - finger tapping
    Color(0xFF6366F1), // indigo - mood
    Color(0xFFEC4899), // pink - fatigue
    Color(0xFF14B8A6), // teal - gait analysis
  ];

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E293B),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontFamily: 'Cairo',
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      displayMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontFamily: 'Cairo'),
      bodyMedium: TextStyle(fontFamily: 'Cairo'),
      labelLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
    ),
  );
}

class AppStrings {
  // App
  static const String appName = 'NeuroScore';
  static const String appSubtitle = 'متابعة الأداء العصبي لمرضى التصلب المتعدد';

  // Auth
  static const String login = 'تسجيل الدخول';
  static const String signup = 'إنشاء حساب جديد';
  static const String email = 'البريد الإلكتروني';
  static const String password = 'كلمة المرور';
  static const String confirmPassword = 'تأكيد كلمة المرور';
  static const String fullName = 'الاسم الكامل';
  static const String age = 'العمر';
  static const String gender = 'الجنس';
  static const String male = 'ذكر';
  static const String female = 'أنثى';
  static const String doctor = 'طبيب';
  static const String patient = 'مريض';
  static const String userType = 'نوع الحساب';
  static const String specialization = 'التخصص';
  static const String hospital = 'المستشفى / العيادة';
  static const String experience = 'سنوات الخبرة';
  static const String phone = 'رقم التواصل';
  static const String selectDoctor = 'اختر طبيبك المتابع';
  static const String logout = 'تسجيل الخروج';
  static const String haveAccount = 'لديك حساب بالفعل؟ تسجيل الدخول';
  static const String noAccount = 'ليس لديك حساب؟ إنشاء حساب جديد';

  // Doctor Dashboard
  static const String welcomeDoctor = 'مرحباً، د.';
  static const String doctorDashboard = 'لوحة التحكم الخاصة بك';
  static const String totalPatients = 'إجمالي المرضى';
  static const String completedTests = 'الاختبارات المكتملة';
  static const String activeCases = 'حالات نشطة';
  static const String avgTests = 'متوسط الاختبارات';
  static const String patientsList = 'قائمة المرضى';
  static const String searchPatient = 'ابحث عن مريض بالاسم...';

  // Patient Dashboard
  static const String welcomePatient = 'مرحباً،';
  static const String chooseTest = 'اختر الاختبار المناسب';
  static const String progressPage = 'تطور الحالة';
  static const String startTest = 'بدأ الاختبار';

  // Tests
  static const String tandemWalk = 'اختبار المشي المتتالي';
  static const String tandemWalkDesc = 'ابحث عن خط مستقيم وامشِ 10 خطوات';
  static const String fingerToNose = 'اختبار الأنف بالإصبع';
  static const String fingerToNoseDesc = 'المس أنفك بإصبعك عدة مرات';
  static const String romberg = 'اختبار رومبيرغ';
  static const String rombergDesc = 'قف مستقيماً وأغلق عينيك 10 ثوان';
  static const String drawing = 'اختبار الرسم';
  static const String drawingDesc = 'ارسم شكل حلزوني على الشاشة';
  static const String memory = 'اختبار الذاكرة';
  static const String memoryDesc = 'لعبة تطابق الأزواج - 8 أزواج من الرموز';
  static const String fingerTapping = 'اختبار النقر بالأصابع';
  static const String fingerTappingDesc = 'انقر بإصبعك بأسرع ما يمكن لمدة 10 ثوان';
  static const String mood = 'استبيان المزاج الأسبوعي';
  static const String moodDesc = 'أسئلة عن حالتك النفسية';
  static const String fatigue = 'استبيان الإرهاق';
  static const String fatigueDesc = 'أسئلة عن مستوى إرهاقك';
  static const String gaitAnalysis = 'تحليل المشي المفصل';
  static const String gaitAnalysisDesc = 'تصوير مفصل لطريقة المشي وتحليلها بالذكاء الاصطناعي';

  // Progress
  static const String totalTests = 'إجمالي الاختبارات';
  static const String lastTest = 'آخر اختبار';
  static const String testTypes = 'أنواع الاختبارات';
  static const String testHistory = 'سجل الاختبارات';
  static const String noTestsYet = 'لم تجرِ أي اختبارات بعد';
}
