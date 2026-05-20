import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final Function(String?) onChanged;
  final Map<String, String> languages;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onChanged,
    this.languages = const {
      'Hindi': 'हिन्दी',
      'English': 'English',
      'Marathi': 'मराठी',
      'Gujarati': 'ગુજરાતી',
      'Telugu': 'తెలుగు',
    },
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLanguage,
          isExpanded: true,
          icon: Icon(Icons.language, color: Colors.green),
          items: languages.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(
                entry.value,
                style: TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
