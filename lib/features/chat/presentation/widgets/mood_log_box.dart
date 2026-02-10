import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MoodLogBox extends StatefulWidget {
  final Function(String) onMoodSelected;

  const MoodLogBox({super.key, required this.onMoodSelected});

  @override
  State<MoodLogBox> createState() => _MoodLogBoxState();
}

class _MoodLogBoxState extends State<MoodLogBox> {
  int? _selectedIndex;

  final List<Map<String, String>> _moods = [
    {'emoji': '😢', 'label': 'Buồn'},
    {'emoji': '😕', 'label': 'Lo lắng'},
    {'emoji': '😐', 'label': 'Bình thường'},
    {'emoji': '🙂', 'label': 'Vui'},
    {'emoji': '😄', 'label': 'Rất vui'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F3E5), // Soft cream background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE8D5B7).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hôm nay bạn cảm thấy thế nào?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5D4E4E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_moods.length, (index) {
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  widget.onMoodSelected(_moods[index]['label']!);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _moods[index]['emoji']!,
                        style: TextStyle(fontSize: isSelected ? 28 : 24),
                      ),
                      const SizedBox(height: 4),
                      if (isSelected)
                        Text(
                          _moods[index]['label']!,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF5D4E4E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
