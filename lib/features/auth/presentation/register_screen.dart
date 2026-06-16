import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/auth_repository.dart';
import '../../../features/shared/network/api_client.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_frame.dart';
import 'widgets/auth_text_field.dart';

/// Register screen — collects fullname, user_name, phone, password,
/// confirm-password and optional email, then calls
/// [AuthRepository.register] followed immediately by [AuthRepository.login]
/// (register returns no token — auto-login is mandatory).
///
/// [onLoginTap] is called when the "Already have an account?" link is tapped;
/// Plan 03's AuthGate toggles between this screen and [LoginScreen].
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onLoginTap,
  });

  final VoidCallback onLoginTap;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullnameCtrl = TextEditingController();
  final _userNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _fullnameCtrl.dispose();
    _userNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final fullname = _fullnameCtrl.text.trim();
    final userName = _userNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    // --- Validation ---
    if (fullname.isEmpty || userName.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Please fill in all required fields';
        _submitting = false;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _error = 'Passwords do not match';
        _submitting = false;
      });
      return;
    }

    // Simple phone check: at least 7 digits
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7) {
      setState(() {
        _error = 'Please enter a valid phone number';
        _submitting = false;
      });
      return;
    }

    // Simple email check if provided
    if (email.isNotEmpty && !email.contains('@')) {
      setState(() {
        _error = 'Please enter a valid email address';
        _submitting = false;
      });
      return;
    }

    try {
      final repo = context.read<AuthRepository>();

      // register() returns no token — must call login() right after.
      await repo.register(
        fullname: fullname,
        userName: userName,
        phone: phone,
        password: password,
        email: email.isEmpty ? null : email,
      );

      // Auto-login so the user lands in the garden without a detour.
      await repo.login(userName: userName, password: password);

      // On success AuthSession flips isAuthenticated; Plan 03's gate routes
      // to the garden automatically — no manual navigation here.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.statusCode == 0) {
          _error = 'Network error — check your connection';
        } else if (e.message.toUpperCase().contains('ALREADY') ||
            e.message.toUpperCase().contains('EXISTS') ||
            e.message.toUpperCase().contains('DUPLICATE') ||
            e.message.toUpperCase().contains('TAKEN')) {
          _error = 'That username is already taken';
        } else {
          _error = e.message.isNotEmpty ? e.message : 'Registration failed';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong — please try again';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Create your garden',
      onBack: widget.onLoginTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Fields (order matches plan spec) ---
          AuthTextField(
            controller: _fullnameCtrl,
            label: 'Full name',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          AuthTextField(
            controller: _userNameCtrl,
            label: 'Username',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          AuthTextField(
            controller: _phoneCtrl,
            label: 'Phone',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          AuthTextField(
            controller: _emailCtrl,
            label: 'Email (optional)',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          AuthTextField(
            controller: _passwordCtrl,
            label: 'Password',
            obscure: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          AuthTextField(
            controller: _confirmPasswordCtrl,
            label: 'Confirm password',
            obscure: true,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 18),

          // Inline error line
          if (_error != null) ...[
            Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFB00020),
                fontSize: 13.5,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],

          // Submit button
          AuthButton(
            label: 'Register',
            submitting: _submitting,
            onTap: _submitting ? null : _register,
          ),
          const SizedBox(height: 20),

          // Navigation link to login
          _LoginLink(onTap: widget.onLoginTap),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _LoginLink extends StatelessWidget {
  const _LoginLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(
            color: Color(0xFF4A5E4A),
            fontSize: 13.5,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Log in',
            style: TextStyle(
              color: Color(0xFF2F5E2E),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF2F5E2E),
            ),
          ),
        ),
      ],
    );
  }
}
