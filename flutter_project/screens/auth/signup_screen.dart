// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  UserType _userType = UserType.patient;
  Gender _gender = Gender.male;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  List<AppUser> _doctors = [];
  AppUser? _selectedDoctor;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final docs = await context.read<AppProvider>().getDoctors();
    if (mounted) setState(() => _doctors = docs);
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _passCtrl, _confirmCtrl,
      _ageCtrl, _specCtrl, _hospitalCtrl, _expCtrl, _phoneCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userType == UserType.patient && _selectedDoctor == null) {
      _showError('يرجى اختيار طبيبك المتابع');
      return;
    }

    final provider = context.read<AppProvider>();
    final ok = await provider.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text) ?? 0,
      gender: _gender,
      userType: _userType,
      specialization: _userType == UserType.doctor ? _specCtrl.text.trim() : null,
      hospital: _userType == UserType.doctor ? _hospitalCtrl.text.trim() : null,
      experienceYears: _userType == UserType.doctor ? int.tryParse(_expCtrl.text) : null,
      phone: _userType == UserType.doctor ? _phoneCtrl.text.trim() : null,
      doctorId: _userType == UserType.patient ? _selectedDoctor?.id : null,
      doctorName: _userType == UserType.patient ? _selectedDoctor?.name : null,
    );

    if (!mounted) return;
    if (ok) {
      context.go(provider.isDoctor ? '/doctor' : '/patient');
    } else {
      _showError(provider.error ?? 'حدث خطأ');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const NeuroScoreLogo(fontSize: 16),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  AppStrings.signup,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 20),

                // User type toggle
                _buildLabel('نوع الحساب'),
                const SizedBox(height: 8),
                _buildTypeToggle(),
                const SizedBox(height: 16),

                // Common fields
                _buildLabel(AppStrings.fullName),
                const SizedBox(height: 8),
                _buildTextField(_nameCtrl, 'أحمد محمد', validator: (v) =>
                    v!.isEmpty ? 'أدخل الاسم الكامل' : null),
                const SizedBox(height: 12),

                _buildLabel(AppStrings.email),
                const SizedBox(height: 8),
                _buildTextField(_emailCtrl, 'example@email.com',
                    direction: TextDirection.ltr,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v!.isEmpty) return 'أدخل البريد الإلكتروني';
                      if (!v.contains('@')) return 'بريد غير صالح';
                      return null;
                    }),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildLabel(AppStrings.gender),
                        const SizedBox(height: 8),
                        _buildGenderDropdown(),
                      ],
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildLabel(AppStrings.age),
                        const SizedBox(height: 8),
                        _buildTextField(_ageCtrl, '30',
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isEmpty ? 'أدخل العمر' : null),
                      ],
                    )),
                  ],
                ),
                const SizedBox(height: 12),

                // Doctor-specific fields
                if (_userType == UserType.doctor) ...[
                  _buildLabel(AppStrings.specialization),
                  const SizedBox(height: 8),
                  _buildTextField(_specCtrl, 'Neurology',
                      validator: (v) => v!.isEmpty ? 'أدخل التخصص' : null),
                  const SizedBox(height: 12),
                  _buildLabel(AppStrings.hospital),
                  const SizedBox(height: 8),
                  _buildTextField(_hospitalCtrl, 'مستشفى القاهرة',
                      validator: (v) => v!.isEmpty ? 'أدخل اسم المستشفى' : null),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildLabel(AppStrings.phone),
                          const SizedBox(height: 8),
                          _buildTextField(_phoneCtrl, '01xxxxxxxxx',
                              keyboardType: TextInputType.phone),
                        ],
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildLabel(AppStrings.experience),
                          const SizedBox(height: 8),
                          _buildTextField(_expCtrl, '10',
                              keyboardType: TextInputType.number),
                        ],
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Patient: doctor selector
                if (_userType == UserType.patient) ...[
                  _buildLabel(AppStrings.selectDoctor),
                  const SizedBox(height: 8),
                  _buildDoctorDropdown(),
                  const SizedBox(height: 12),
                ],

                _buildLabel(AppStrings.password),
                const SizedBox(height: 8),
                _buildTextField(_passCtrl, '••••••••',
                    obscure: _obscurePass,
                    onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
                    validator: (v) {
                      if (v!.isEmpty) return 'أدخل كلمة المرور';
                      if (v.length < 6) return 'كلمة المرور قصيرة جداً';
                      return null;
                    }),
                const SizedBox(height: 12),

                _buildLabel(AppStrings.confirmPassword),
                const SizedBox(height: 8),
                _buildTextField(_confirmCtrl, '••••••••',
                    obscure: _obscureConfirm,
                    onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (v) {
                      if (v != _passCtrl.text) return 'كلمتا المرور غير متطابقتين';
                      return null;
                    }),
                const SizedBox(height: 28),

                Consumer<AppProvider>(
                  builder: (_, p, __) => GradientButton(
                    label: AppStrings.signup,
                    isLoading: p.isLoading,
                    onTap: _signup,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      AppStrings.haveAccount,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF374151),
      fontFamily: 'Cairo',
    ),
  );

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
    TextDirection direction = TextDirection.rtl,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      textAlign: TextAlign.right,
      obscureText: obscure,
      keyboardType: keyboardType,
      textDirection: direction,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF94A3B8),
                  size: 20,
                ),
                onPressed: onToggleObscure,
              )
            : null,
      ),
      validator: validator,
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _typeButton(UserType.patient, AppStrings.patient, Icons.person_outlined)),
          Expanded(child: _typeButton(UserType.doctor, AppStrings.doctor, Icons.medical_services_outlined)),
        ],
      ),
    );
  }

  Widget _typeButton(UserType type, String label, IconData icon) {
    final selected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<Gender>(
      value: _gender,
      alignment: AlignmentDirectional.centerEnd,
      decoration: const InputDecoration(),
      items: [
        DropdownMenuItem(value: Gender.male, child: Text(AppStrings.male, style: const TextStyle(fontFamily: 'Cairo'))),
        DropdownMenuItem(value: Gender.female, child: Text(AppStrings.female, style: const TextStyle(fontFamily: 'Cairo'))),
      ],
      onChanged: (v) => setState(() => _gender = v!),
    );
  }

  Widget _buildDoctorDropdown() {
    if (_doctors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'لا يوجد أطباء مسجلون بعد',
            style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Cairo', fontSize: 13),
          ),
        ),
      );
    }
    return DropdownButtonFormField<AppUser>(
      value: _selectedDoctor,
      hint: const Text('اختر طبيبك', style: TextStyle(fontFamily: 'Cairo')),
      decoration: const InputDecoration(),
      items: _doctors.map((d) => DropdownMenuItem(
        value: d,
        child: Text('د. ${d.name}', style: const TextStyle(fontFamily: 'Cairo')),
      )).toList(),
      onChanged: (v) => setState(() => _selectedDoctor = v),
    );
  }
}
