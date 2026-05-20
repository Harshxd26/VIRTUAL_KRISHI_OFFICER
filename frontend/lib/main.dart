import 'package:digital_krishi_officer/screens/support_ticket_history_screen.dart';
import 'package:digital_krishi_officer/screens/ticket_detail_screen.dart';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'services/language_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/voice_query_screen.dart';
import 'screens/text_query_screen.dart';
import 'screens/image_query_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/ai_answer_screen.dart';
import 'screens/escalation_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/history_screen.dart';
import 'services/storage_service.dart';
import 'screens/settings_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageController.instance.loadInitial();
  runApp(const DigitalKrishiOfficerApp());
}

class DigitalKrishiOfficerApp extends StatelessWidget {
  const DigitalKrishiOfficerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.instance.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Virtual Krishi Officer',
          theme: ThemeData(
            primarySwatch: Colors.green,
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          initialRoute: '/',
          routes: {
            '/': (context) => SplashScreen(),
            '/consent': (context) => ConsentScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/home': (context) => HomeScreen(),
            '/voice_query': (context) => VoiceQueryScreen(),
            '/text_query': (context) => TextQueryScreen(),
            '/image_query': (context) => ImageQueryScreen(),
            '/processing': (context) => ProcessingScreen(),
            '/ai_answer': (context) => AIAnswerScreen(),
            '/escalation': (context) => EscalationScreen(),
            '/feedback': (context) => FeedbackScreen(),
            '/history': (context) => HistoryScreen(),
            '/ticket_history': (context) => const SupportTicketHistoryScreen(),
            '/ticket_detail': (context) => const TicketDetailScreen(),

          },
        );
      },
    );
  }
}