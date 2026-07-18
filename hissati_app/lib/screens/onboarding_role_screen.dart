import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'main_navigation_screen.dart';

/// Onboarding screen shown the first time a user signs in (no Firestore
/// profile yet). Collects full name and role (tutor / parent), creates
/// the profile via [AuthService], then navigates to [MainNavigationScreen].
class OnboardingRoleScreen extends StatefulWidget {
  final String uid;
  final String phoneNumber;

  const OnboardingRoleScreen({
    super.key,
    required this.uid,
    required this.phoneNumber,
  });

  @override
  State<OnboardingRoleScreen> createState() => _OnboardingRoleScreenState();
}

class _OnboardingRoleScreenState extends State<OnboardingRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  UserRole? _selectedRole;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الدور')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = AppUser(
        uid: widget.uid,
        fullName: _nameController.text.trim(),
        phoneNumber: widget.phoneNumber,
        role: _selectedRole!,
        createdAt: DateTime.now(),
      );

      await AuthService.instance.createProfile(user);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(currentUser: user),
          ),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_add_rounded,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'أكمل بياناتك',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Full name ────────────────────────────────────
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'الاسم الكامل',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'مطلوب';
                      if (v.trim().length < 3) return 'الاسم قصير جداً';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── Role selection ───────────────────────────────
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'اختر دورك',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          label: 'مدرس',
                          icon: Icons.school,
                          isSelected: _selectedRole == UserRole.tutor,
                          onTap: () =>
                              setState(() => _selectedRole = UserRole.tutor),
                          colorScheme: colorScheme,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _RoleCard(
                          label: 'ولي أمر',
                          icon: Icons.family_restroom,
                          isSelected: _selectedRole == UserRole.parent,
                          onTap: () =>
                              setState(() => _selectedRole = UserRole.parent),
                          colorScheme: colorScheme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // ── Submit button ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'متابعة',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A selectable card representing a user role (tutor / parent).
class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 44,
              color: isSelected ? colorScheme.primary : Colors.grey.shade500,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? colorScheme.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
