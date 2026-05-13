// lib/services/test_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';

class TestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── Save Test Result ─────────────────────────────────────
  Future<TestResult> saveResult({
    required String patientId,
    required String patientName,
    required String doctorId,
    required TestType testType,
    required double score,
    Map<String, dynamic>? metadata,
    File? videoFile,
    String? aiAnalysis,
  }) async {
    String? videoUrl;
    if (videoFile != null) {
      videoUrl = await _uploadVideo(patientId, testType, videoFile);
    }

    final docRef = _db.collection('test_results').doc();
    final result = TestResult(
      id: docRef.id,
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      testType: testType,
      score: score,
      completedAt: DateTime.now(),
      metadata: metadata,
      videoUrl: videoUrl,
      aiAnalysis: aiAnalysis,
    );

    await docRef.set(result.toFirestore());
    return result;
  }

  // ─── Upload Video to Firebase Storage ────────────────────
  Future<String> _uploadVideo(String patientId, TestType type, File file) async {
    final ref = _storage
        .ref()
        .child('videos/$patientId/${type.name}_${DateTime.now().millisecondsSinceEpoch}.mp4');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  // ─── Get Patient Tests (stream) ───────────────────────────
  Stream<List<TestResult>> getPatientTests(String patientId) {
    return _db
        .collection('test_results')
        .where('patientId', isEqualTo: patientId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => TestResult.fromFirestore(d)).toList());
  }

  // ─── Get Patient Tests by Type ────────────────────────────
  Future<List<TestResult>> getPatientTestsByType(
      String patientId, TestType type) async {
    final snapshot = await _db
        .collection('test_results')
        .where('patientId', isEqualTo: patientId)
        .where('testType', isEqualTo: type.name)
        .orderBy('completedAt')
        .get();
    return snapshot.docs.map((d) => TestResult.fromFirestore(d)).toList();
  }

  // ─── Get Doctor Stats ─────────────────────────────────────
  Future<Map<String, dynamic>> getDoctorStats(
      String doctorId, List<String> patientIds) async {
    if (patientIds.isEmpty) {
      return {
        'totalTests': 0,
        'activePatients': 0,
        'avgTests': 0.0,
      };
    }

    // Firestore 'in' queries max 10 items at a time
    int totalTests = 0;
    Set<String> activePatients = {};

    for (int i = 0; i < patientIds.length; i += 10) {
      final chunk = patientIds.sublist(
        i,
        i + 10 > patientIds.length ? patientIds.length : i + 10,
      );
      final snapshot = await _db
          .collection('test_results')
          .where('patientId', whereIn: chunk)
          .get();
      totalTests += snapshot.docs.length;
      for (final doc in snapshot.docs) {
        activePatients.add(doc['patientId'] as String);
      }
    }

    return {
      'totalTests': totalTests,
      'activePatients': activePatients.length,
      'avgTests': patientIds.isEmpty
          ? 0.0
          : totalTests / patientIds.length,
    };
  }

  // ─── Get Patient Summary Stats ────────────────────────────
  Future<Map<String, dynamic>> getPatientSummary(String patientId) async {
    final snapshot = await _db
        .collection('test_results')
        .where('patientId', isEqualTo: patientId)
        .get();

    final results = snapshot.docs.map((d) => TestResult.fromFirestore(d)).toList();

    if (results.isEmpty) {
      return {
        'totalTests': 0,
        'testTypes': 0,
        'lastTest': null,
        'avgScore': 0.0,
      };
    }

    results.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final types = results.map((r) => r.testType).toSet();
    final avgScore = results.fold(0.0, (s, r) => s + r.score) / results.length;

    return {
      'totalTests': results.length,
      'testTypes': types.length,
      'lastTest': results.first.completedAt,
      'avgScore': avgScore,
    };
  }
}
