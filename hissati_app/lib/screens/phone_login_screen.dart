import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Phone-number login screen with Firebase Phone Auth.
///
/// Flow:
///   1. User enters an Egyptian phone number (auto-prefixed with +20).
///   2. Firebase sends an OTP via [verifyPhoneNumber].
///   3. User enters the 6-digit code in a [PinCodeTextField].
///   4. The app verifies and signs in with a [PhoneAuthCredential].
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ─── Send OTP ──────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phone = '+20${_phoneController.text.trim()}';

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-resolve on Android (instant verification).
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError(e.message ?? 'فشل إرسال الكود');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // ─── Verify OTP ────────────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      _showError('يرجى إدخال كود مكون من 6 أرقام');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      // AuthGate in main.dart handles navigation after sign-in.
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message ?? 'كود خاطئ');
    } catch (e) {
      if (mounted) _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ─── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo & Title ─────────────────────────────────
                  Icon(
                    Icons.school_rounded,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'حصتي',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سجّل دخولك برقم الموبايل',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Phone number field ───────────────────────────
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    enabled: !_codeSent,
                    decoration: InputDecoration(
                      labelText: 'رقم الموبايل',
                      prefixText: '+20 ',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال رقم الموبايل';
                      }
                      if (value.trim().length < 10) {
                        return 'رقم غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Send OTP button ──────────────────────────────
                  if (!_codeSent)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'إرسال كود التحقق',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),

                  // ── OTP input & verify button ────────────────────
                  if (_codeSent) ...[
                    Text(
                      'أدخل كود التحقق المرسل إلى هاتفك',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: PinCodeTextField(
                        appContext: context,
                        length: 6,
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(10),
                          fieldHeight: 50,
                          fieldWidth: 44,
                          activeFillColor: Colors.white,
                          inactiveFillColor: Colors.grey.shade50,
                          selectedFillColor: Colors.white,
                          activeColor: colorScheme.primary,
                          inactiveColor: Colors.grey.shade300,
                          selectedColor: colorScheme.primary,
                        ),
                        enableActiveFill: true,
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'تسجيل الدخول',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
