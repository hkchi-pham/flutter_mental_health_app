import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/auth_repository.dart';
import '../../../features/shared/network/api_client.dart';
import 'widgets/auth_frame.dart';
import 'widgets/auth_text_field.dart';

/// Login screen — collects username + password and calls [AuthRepository.login].
///
/// Constructor params:
///   [onRegisterTap]   — called when the user taps "Register" link; Plan 03's
///                       AuthGate swaps screens by toggling a bool.
///   [initialMessage]  — optional externally-supplied notice rendered in the
///                       same inline error line as auth errors.  Plan 03 seeds
///                       "Session expired — please log in again" here after a
///                       401 mid-session.  First keystroke / new submit clears it.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onRegisterTap,
    this.initialMessage,
  });

  final VoidCallback onRegisterTap;
  final String? initialMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Seed the inline notice from the external param so a session-expired
    // message renders inside the framed panel (per CONTEXT decision).
    if (widget.initialMessage != null) {
      _error = widget.initialMessage;
    }
  }

  @override
  void dispose() {
    _userNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Clear any previous error and mark submitting
    setState(() {
      _submitting = true;
      _error = null;
    });

    final userName = _userNameCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Non-empty validation
    if (userName.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Please fill in all fields';
        _submitting = false;
      });
      return;
    }

    try {
      await context.read<AuthRepository>().login(
            userName: userName,
            password: password,
          );
      // On success the AuthSession flips isAuthenticated; Plan 03's gate
      // routes to the garden automatically — no manual navigation here.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.statusCode == 0) {
          _error = 'Network error — check your connection';
        } else if (e.message.toUpperCase().contains('INVALID') ||
            e.message.toUpperCase().contains('CREDENTIALS') ||
            e.message.toUpperCase().contains('INCORRECT') ||
            e.message.toUpperCase().contains('PASSWORD') ||
            e.message.toUpperCase().contains('NOT FOUND') ||
            e.statusCode == 400 ||
            e.statusCode == 404) {
          _error = 'Incorrect username or password';
        } else {
          _error = e.message.isNotEmpty ? e.message : 'Something went wrong';
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
      title: 'Welcome back',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Username field
          AuthTextField(
            controller: _userNameCtrl,
            label: 'Username',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),

          // Password field with eye toggle
          AuthTextField(
            controller: _passwordCtrl,
            label: 'Password',
            obscure: true,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 18),

          // Inline error line — renders both auth errors and the seeded
          // session-expired notice in the same location (per CONTEXT).
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
          _SubmitButton(
            submitting: _submitting,
            onTap: _submitting ? null : _login,
          ),
          const SizedBox(height: 20),

          // Navigation link to register
          _RegisterLink(onTap: widget.onRegisterTap),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.submitting, required this.onTap});

  final bool submitting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // PNG button — errorBuilder provides a styled green button
          Image.asset(
            'assets/screens/login_btn_@2x.png',
            height: 52,
            fit: BoxFit.fitHeight,
            errorBuilder: (_, _, _) => _FallbackButton(label: 'Log In'),
          ),
          if (submitting)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _FallbackButton extends StatelessWidget {
  const _FallbackButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF6B8E5A),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  const _RegisterLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(
            color: Color(0xFF4A5E4A),
            fontSize: 13.5,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Register',
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
