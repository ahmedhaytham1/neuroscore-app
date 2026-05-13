// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { doctor, patient }
enum Gender { male, female }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserType userType;
  final int age;
  final Gender gender;
  final DateTime createdAt;

  // Doctor-specific
  final String? specialization;
  final String? hospital;
  final int? experienceYears;
  final String? phone;

  // Patient-specific
  final String? doctorId;
  final String? doctorName;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    required this.age,
    required this.gender,
    required this.createdAt,
    this.specialization,
    this.hospital,
    this.experienceYears,
    this.phone,
    this.doctorId,
    this.doctorName,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      userType: data['userType'] == 'doctor' ? UserType.doctor : UserType.patient,
      age: data['age'] ?? 0,
      gender: data['gender'] == 'male' ? Gender.male : Gender.female,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      specialization: data['specialization'],
      hospital: data['hospital'],
      experienceYears: data['experienceYears'],
      phone: data['phone'],
      doctorId: data['doctorId'],
      doctorName: data['doctorName'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'userType': userType == UserType.doctor ? 'doctor' : 'patient',
    'age': age,
    'gender': gender == Gender.male ? 'male' : 'female',
    'createdAt': Timestamp.fromDate(createdAt),
    if (specialization != null) 'specialization': specialization,
    if (hospital != null) 'hospital': hospital,
    if (experienceYears != null) 'experienceYears': experienceYears,
    if (phone != null) 'phone': phone,
    if (doctorId != null) 'doctorId': doctorId,
    if (doctorName != null) 'doctorName': doctorName,
  };

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : '?';
  }

  String get genderLabel => gender == Gender.male ? 'ذكر' : 'أنثى';
}

// lib/models/test_result_model.dart - included here for convenience
class TestResult {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final TestType testType;
  final double score;
  final DateTime completedAt;
  final Map<String, dynamic>? metadata; // extra data per test
  final String? videoUrl;              // Firebase Storage URL for video tests
  final String? aiAnalysis;            // AI model output text

  TestResult({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.testType,
    required this.score,
    required this.completedAt,
    this.metadata,
    this.videoUrl,
    this.aiAnalysis,
  });

  factory TestResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestResult(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorId: data['doctorId'] ?? '',
      testType: TestType.values.firstWhere(
        (e) => e.name == data['testType'],
        orElse: () => TestType.memory,
      ),
      score: (data['score'] ?? 0).toDouble(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'],
      videoUrl: data['videoUrl'],
      aiAnalysis: data['aiAnalysis'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'patientId': patientId,
    'patientName': patientName,
    'doctorId': doctorId,
    'testType': testType.name,
    'score': score,
    'completedAt': Timestamp.fromDate(completedAt),
    if (metadata != null) 'metadata': metadata,
    if (videoUrl != null) 'videoUrl': videoUrl,
    if (aiAnalysis != null) 'aiAnalysis': aiAnalysis,
  };

  String get testName => testType.label;
  String get scoreLabel => '${score.toStringAsFixed(0)}%';

  Color get scoreColor {
    if (score >= 80) return const Color(0xFF10B981); // green
    if (score >= 60) return const Color(0xFFF59E0B); // amber
    return const Color(0xFFEF4444); // red
  }
}

enum TestType {
  tandemWalk,
  fingerToNose,
  romberg,
  drawing,
  memory,
  fingerTapping,
  mood,
  fatigue,
  gaitAnalysis;

  String get label {
    switch (this) {
      case TestType.tandemWalk: return 'اختبار المشي المتتالي';
      case TestType.fingerToNose: return 'اختبار الأنف بالإصبع';
      case TestType.romberg: return 'اختبار رومبيرغ';
      case TestType.drawing: return 'اختبار الرسم';
      case TestType.memory: return 'اختبار الذاكرة';
      case TestType.fingerTapping: return 'اختبار النقر بالأصابع';
      case TestType.mood: return 'استبيان المزاج';
      case TestType.fatigue: return 'استبيان الإرهاق';
      case TestType.gaitAnalysis: return 'تحليل المشي المفصل';
    }
  }

  bool get requiresVideo => [
    TestType.tandemWalk,
    TestType.fingerToNose,
    TestType.romberg,
    TestType.gaitAnalysis,
  ].contains(this);

  bool get requiresAI => [
    TestType.tandemWalk,
    TestType.fingerToNose,
    TestType.romberg,
    TestType.gaitAnalysis,
  ].contains(this);
}
