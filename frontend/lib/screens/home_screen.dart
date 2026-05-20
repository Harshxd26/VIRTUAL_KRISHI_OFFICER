// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/language_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/farmer.dart';
import 'dart:ui';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  Farmer? _farmer;
  bool _isLoading = true;
  String _selectedLanguage = 'Hindi';

  @override
  void initState() {
    super.initState();
    _loadFarmerProfile();
    _loadLanguage();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _storageService.clearFarmerProfile();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/profile',
          (route) => false,
    );
  }

  Future<void> _loadFarmerProfile() async {
    final farmer = await _storageService.getFarmerProfile();
    setState(() {
      _farmer = farmer;
      _isLoading = false;
    });
  }

  Future<void> _loadLanguage() async {
    final language = await _storageService.getLanguage();
    setState(() {
      _selectedLanguage = language;
    });
  }

  Future<void> _changeLanguage(String? language) async {
    if (language != null) {
      await LanguageController.instance.setLanguage(language);
      if (_farmer != null) {
        final updatedFarmer = _farmer!.copyWith(
          language: language,
          languageCode: LanguageController.instance.locale.value.languageCode,
        );
        await _storageService.saveFarmerProfile(updatedFarmer);
        setState(() {
          _farmer = updatedFarmer;
          _selectedLanguage = language;
        });
      } else {
        setState(() {
          _selectedLanguage = language;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final farmerName = _farmer?.name ?? loc.t('name');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("🌾 "),
            Expanded(child: Text(loc.t('app_title'))),
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;

                case 'history':
                  Navigator.pushNamed(context, '/history');
                  break;

                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;

                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('History'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF4FFF4),
              Color(0xFFE8F5E9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [

            // TOP RIGHT GLOW
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.12),
                ),
              ),
            ),

            // BOTTOM LEFT GLOW
            Positioned(
              bottom: -80,
              left: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.lightGreen.withOpacity(0.10),
                ),
              ),
            ),

            SafeArea(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                Text(
                  loc.t('home_greeting', params: {'name': farmerName}),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  loc.t('home_subtitle'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade600,
                        Colors.green.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "🌾 Smart Farming Assistant",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "AI powered crop guidance, disease detection & expert support.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ASK AI (Text + Voice Combined)
                _buildQueryCard(
                  icon: Icons.smart_toy,
                  iconColor: Colors.green,
                  title: loc.t('home_ai_title'),
                  subtitle: loc.t('home_ai_sub'),
                  onTap: () => Navigator.pushNamed(context, '/text_query'),
                ),

                SizedBox(height: 20),

                // Image Query Card
                _buildQueryCard(
                  icon: Icons.camera_alt,
                  iconColor: Colors.purple,
                  title: loc.t('home_image_title'),
                  subtitle: loc.t('home_image_sub'),
                  onTap: () => Navigator.pushNamed(context, '/image_query'),
                ),

                SizedBox(height: 20),

                _buildQueryCard(
                  icon: Icons.support_agent,
                  iconColor: Colors.blue,
                  title: loc.t('home_expert_title'),
                  subtitle: loc.t('home_expert_sub'),
                  onTap: () => Navigator.pushNamed(context, '/escalation'),
                ),
                  ],
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [

                      // ICON CONTAINER
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              iconColor.withOpacity(0.18),
                              iconColor.withOpacity(0.08),
                            ],
                          ),
                          borderRadius:
                          BorderRadius.circular(18),
                        ),
                        child: Icon(
                          icon,
                          size: 30,
                          color: iconColor,
                        ),
                      ),

                      const SizedBox(width: 20),

                      // TEXT
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ARROW
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                          Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}