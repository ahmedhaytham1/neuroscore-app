// lib/services/app_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'ai_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AIService _aiService = AIService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDoctor => _currentUser?.userType == UserType.doctor;
  bool get isPatient => _currentUser?.userType == UserType.patient;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? e) { _error = e; notifyListeners(); }

  Future<void> init() async {
    _aiService.initialize(); // preload AI models in background
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        _currentUser = await _authService.getUser(user.uid);
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true); _setError(null);
    try {
      _currentUser = await _authService.signIn(email: email, password: password);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_authErrorMessage(e.code));
      return false;
    } finally { _setLoading(false); }
  }

  Future<bool> signUp({
    required String email, required String password, required String name,
    required int age, required Gender gender, required UserType userType,
    String? specialization, String? hospital, int? experienceYears,
    String? phone, String? doctorId, String? doctorName,
  }) async {
    _setLoading(true); _setError(null);
    try {
      _currentUser = await _authService.signUp(
        email: email, password: password, name: name,
        age: age, gender: gender, userType: userType,
        specialization: specialization, hospital: hospital,
        experienceYears: experienceYears, phone: phone,
        doctorId: doctorId, doctorName: doctorName,
      );
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_authErrorMessage(e.code));
      return false;
    } finally { _setLoading(false); }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<List<AppUser>> getDoctors() => _authService.getAllDoctors();

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email': return 'البريد الإلكتروني غير صالح';
      case 'weak-password': return 'كلمة المرور ضعيفة جداً';
      case 'user-not-found': return 'المستخدم غير موجود';
      case 'wrong-password': return 'كلمة المرور غير صحيحة';
      case 'invalid-credential': return 'البريد أو كلمة المرور غير صحيحة';
      default: return 'حدث خطأ، يرجى المحاولة مرة أخرى';
    }
  }
}
