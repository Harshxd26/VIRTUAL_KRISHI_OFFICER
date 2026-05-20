import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

class LanguageController {
  LanguageController._();
  static final LanguageController instance = LanguageController._();

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('hi'));

  Locale _mapLanguage(String language) {
    final map = {
      'Hindi': const Locale('hi'),
      'English': const Locale('en'),
      'Marathi': const Locale('mr'),
      'Gujarati': const Locale('gu'),
      'Telugu': const Locale('te'),
    };
    return map[language] ?? const Locale('hi');
  }

  Future<void> loadInitial() async {
    final storage = StorageService();
    final language = await storage.getLanguage();
    locale.value = _mapLanguage(language);
  }

  Future<void> setLanguage(String language) async {
    final storage = StorageService();
    await storage.saveLanguage(language);
    locale.value = _mapLanguage(language);
  }
}

