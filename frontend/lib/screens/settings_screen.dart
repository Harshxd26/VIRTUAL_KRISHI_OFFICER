import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../services/language_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();

  String _selectedLanguage = 'Hindi';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  // ✅ load saved language
  Future<void> _loadLanguage() async {
    final lang = await _storageService.getLanguage();
    setState(() {
      _selectedLanguage = lang;
    });
  }

  // ✅ change language globally
  Future<void> _changeLanguage(String language) async {
    await LanguageController.instance.setLanguage(language);
    await _storageService.saveLanguage(language);

    setState(() {
      _selectedLanguage = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('settings')),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          /// PROFILE
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(loc.t('profile_title')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.confirmation_number),
            title: const Text("Support Tickets"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/ticket_history');
            },
          ),

          /// HISTORY
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(loc.t('history')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/history');
            },
          ),

          const Divider(),

          /// ✅ LANGUAGE SELECTOR
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(loc.t('language')),
            subtitle: const Text('Change app language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Marathi', child: Text('Marathi')),
                DropdownMenuItem(value: 'Gujarati', child: Text('Gujarati')),
                DropdownMenuItem(value: 'Telugu', child: Text('Telugu')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _changeLanguage(value);
                }
              },
            ),
          ),

          const Divider(),

          /// ABOUT
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About App'),
            subtitle: Text('AI-Based Farmer Advisory System'),
          ),
        ],
      ),
    );
  }
}