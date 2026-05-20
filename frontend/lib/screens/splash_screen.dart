// screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/language_selector.dart';
import '../l10n/app_localizations.dart';
import '../services/language_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();
  String _selectedLanguage = 'Hindi';
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _checkProfile();
    _loadLanguage();
  }

  Future<void> _checkProfile() async {
    final hasProfile = await _storageService.hasFarmerProfile();
    setState(() {
      _hasProfile = hasProfile;
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
      setState(() {
        _selectedLanguage = language;
      });
    }
  }

  void _navigateToNext() {
    if (_hasProfile) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushNamed(context, '/consent');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
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

            // TOP GLOW
            Positioned(
              top: -100,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.10),
                ),
              ),
            ),

            // BOTTOM GLOW
            Positioned(
              bottom: -120,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.lightGreen.withOpacity(0.10),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [

                      // APP ICON
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1),
                        duration:
                        const Duration(milliseconds: 900),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade500,
                                Colors.green.shade300,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                Colors.green.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.agriculture,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // TITLE
                      Text(
                        loc.t('app_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // SUBTITLE
                      Text(
                        'AI-powered multilingual farming assistant for smart agriculture support.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 50),

                      // START BUTTON
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade600,
                              Colors.green.shade400,
                            ],
                          ),
                          borderRadius:
                          BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.green.withOpacity(0.2),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _navigateToNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.transparent,
                            shadowColor:
                            Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            _hasProfile
                                ? loc.t('go_home')
                                : loc.t('start'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // LANGUAGE CARD
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.72),
                          borderRadius:
                          BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.black.withOpacity(0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [

                            Text(
                              loc.t('language_label'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),

                            const SizedBox(height: 14),

                            LanguageSelector(
                              selectedLanguage:
                              _selectedLanguage,
                              onChanged: _changeLanguage,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        '🌱 Smart Farming • AI Advisory • Expert Support',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
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
}