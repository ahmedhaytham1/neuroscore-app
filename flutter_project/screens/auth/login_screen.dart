// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final ok = await provider.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      if (provider.isDoctor) {
        context.go('/doctor');
      } else {
        context.go('/patient');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'حدث خطأ'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const NeuroScoreLogo(fontSize: 22),
              const SizedBox(height: 12),
              Text(
                AppStrings.appSubtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
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
                        AppStrings.login,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLabel(AppStrings.email),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          hintText: 'example@email.com',
                          hintTextDirection: TextDirection.ltr,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل البريد الإلكتروني';
                          if (!v.contains('@')) return 'بريد إلكتروني غير صالح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel(AppStrings.password),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passCtrl,
                        textAlign: TextAlign.right,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                          if (v.length < 6) return 'كلمة المرور قصيرة جداً';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      Consumer<AppProvider>(
                        builder: (_, p, __) => GradientButton(
                          label: AppStrings.login,
                          isLoading: p.isLoading,
                          onTap: _login,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.push('/signup'),
                          child: Text(
                            AppStrings.noAccount,
                            style: const TextStyle(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFF374151),
      fontFamily: 'Cairo',
    ),
  );
}
