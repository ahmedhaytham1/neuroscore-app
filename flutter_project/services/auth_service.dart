// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ─── Sign Up ───────────────────────────────────────────────
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required Gender gender,
    required UserType userType,
    // Doctor fields
    String? specialization,
    String? hospital,
    int? experienceYears,
    String? phone,
    // Patient fields
    String? doctorId,
    String? doctorName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final appUser = AppUser(
      id: uid,
      name: name,
      email: email,
      userType: userType,
      age: age,
      gender: gender,
      createdAt: DateTime.now(),
      specialization: specialization,
      hospital: hospital,
      experienceYears: experienceYears,
      phone: phone,
      doctorId: doctorId,
      doctorName: doctorName,
    );

    await _db.collection('users').doc(uid).set(appUser.toFirestore());
    await credential.user!.updateDisplayName(name);

    return appUser;
  }

  // ─── Sign In ───────────────────────────────────────────────
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return await getUser(credential.user!.uid);
  }

  // ─── Sign Out ──────────────────────────────────────────────
  Future<void> signOut() async => await _auth.signOut();

  // ─── Get User ─────────────────────────────────────────────
  Future<AppUser> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('المستخدم غير موجود');
    return AppUser.fromFirestore(doc);
  }

  // ─── Get All Doctors (for patient signup) ─────────────────
  Future<List<AppUser>> getAllDoctors() async {
    final snapshot = await _db
        .collection('users')
        .where('userType', isEqualTo: 'doctor')
        .get();
    return snapshot.docs.map((d) => AppUser.fromFirestore(d)).toList();
  }

  // ─── Get Doctor's Patients ────────────────────────────────
  Stream<List<AppUser>> getDoctorPatients(String doctorId) {
    return _db
        .collection('users')
        .where('doctorId', isEqualTo: doctorId)
        .where('userType', isEqualTo: 'patient')
        .snapshots()
        .map((s) => s.docs.map((d) => AppUser.fromFirestore(d)).toList());
  }
}
