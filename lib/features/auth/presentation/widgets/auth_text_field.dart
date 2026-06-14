import 'package:flutter/material.dart';

/// Styled text input matching the auth-frame aesthetic.
///
/// Renders a rounded cream container wrapping a borderless [TextField].
/// When [obscure] is true, a trailing eye [IconButton] toggles visibility.
/// Inputs are NOT PNG-framed — they use Flutter styling per CONTEXT conventions.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  /// When the field is configured as a password field, text starts hidden.
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = widget.obscure;
  }

  void _toggleVisibility() {
    setState(() {
      _hidden = !_hidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B7C6A),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: _hidden,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        style: const TextStyle(
          color: Color(0xFF2F3E2E),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: widget.label,
          hintStyle: const TextStyle(
            color: Color(0xFF8A9E8A),
            fontSize: 15,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
          suffixIcon: widget.obscure
              ? IconButton(
                  icon: Icon(
                    _hidden ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF6B7C6A),
                    size: 20,
                  ),
                  onPressed: _toggleVisibility,
                )
              : null,
        ),
      ),
    );
  }
}
