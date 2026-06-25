import 'package:flutter/material.dart';

/// Placeholder journal list screen.
///
/// NOTE: This is a minimal stub created by Plan 11-03 so [AppShell] compiles
/// while Plan 11-04 (which owns this file) runs in parallel. Plan 04 replaces
/// this with the real notebook-list UI consuming `JournalProvider`. Do not add
/// journal business logic here.
class JournalListScreen extends StatelessWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6EFE0),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.menu_book, size: 64, color: Color(0xFF8B7355)),
              SizedBox(height: 12),
              Text(
                'Journal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A4A3A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
