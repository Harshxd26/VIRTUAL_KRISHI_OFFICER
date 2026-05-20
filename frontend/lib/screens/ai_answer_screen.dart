// screens/ai_answer_screen.dart
import 'package:flutter/material.dart';

import '../models/query.dart';
import '../models/query_response.dart';
import '../l10n/app_localizations.dart';

class AIAnswerScreen extends StatelessWidget {
  const AIAnswerScreen({super.key});

  String _friendlyIntent(String intent) {
    switch (intent) {
      case 'image_diagnosis':
        return 'Crop Diagnosis';

      case 'general_farming_advice':
        return 'Farming Advice';

      case 'pest_management':
        return 'Pest Control';

      case 'fertilizer_advice':
        return 'Fertilizer Guidance';

      default:
        return 'AI Advisory';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final Query? query = args?['query'] as Query?;
    final QueryResponseModel? explicitResponse = args?['response'] as QueryResponseModel?;
    final QueryResponseModel response = explicitResponse ?? query?.response ?? _fallbackResponse;

    final confidencePercent =
    (response.confidence * 100).clamp(0, 100).toInt();

    Color confidenceColor;
    IconData confidenceIcon;
    String confidenceLabel;

    if (confidencePercent >= 90) {
      confidenceColor = Colors.green;
      confidenceIcon = Icons.verified;
      confidenceLabel = loc.t('confidence_high');
    } else if (confidencePercent >= 70) {
      confidenceColor = Colors.orange;
      confidenceIcon = Icons.warning_amber_rounded;
      confidenceLabel = loc.t('confidence_medium');
    } else {
      confidenceColor = Colors.red;
      confidenceIcon = Icons.error_outline;
      confidenceLabel = loc.t('confidence_low');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            response.intent == 'image_diagnosis'
                ? loc.t('image_result_title')
                : loc.t('ai_answer_title')
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (response.cached)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Chip(
                label: Text(loc.t('cached'), style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.green.shade700,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntentHeader(response, confidencePercent, confidenceColor, confidenceIcon, confidenceLabel, loc,),
              SizedBox(height: 16),
              _buildAnswerCard(response, loc),
              const SizedBox(height: 20),
              _buildMetadata(response, loc),
              const SizedBox(height: 20),
              if (response.sources.isNotEmpty) _SourcesList(sources: response.sources, loc: loc),
              const SizedBox(height: 24),
              _buildActions(context, response, query, loc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntentHeader(
      QueryResponseModel response,
      int confidencePercent,
      Color confidenceColor,
      IconData confidenceIcon,
      String confidenceLabel,
      AppLocalizations loc,
      ) {
    return Container(
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
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _friendlyIntent(response.intent),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                confidenceIcon,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                '${loc.t('confidence_label')}: $confidencePercent% ($confidenceLabel)',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: confidencePercent / 100,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(QueryResponseModel response, AppLocalizations loc) {
    if (response.intent == "image_diagnosis") {
      final lines = response.answer
          .split('\n')
          .where((e) => e.trim().isNotEmpty)
          .toList();

      return Column(
        children: lines.map((line) {
          IconData icon = Icons.info;

          if (line.toLowerCase().contains("disease") ||
              line.toLowerCase().contains("problem")) {
            icon = Icons.warning_amber_rounded;
          } else if (line.toLowerCase().contains("treatment")) {
            icon = Icons.medical_services;
          } else if (line.toLowerCase().contains("prevention")) {
            icon = Icons.shield;
          } else if (line.toLowerCase().contains("confidence")) {
            icon = Icons.analytics;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: Icon(icon, color: Colors.green),
              title: Text(
                line,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          );
        }).toList(),
      );
    }

    final answerParagraphs = response.answer
        .trim()
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.t('ai_advice'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ...answerParagraphs.map(
                  (paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  paragraph,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata(QueryResponseModel response, AppLocalizations loc) {
    return Row(
      children: [
        _MetadataChip(
          icon: Icons.timer,
          label: loc.t('time'),
          value: '${response.metadata.processingTimeSeconds.toStringAsFixed(2)}s',
        ),
        const SizedBox(width: 12),
        _MetadataChip(
          icon: Icons.source,
          label: loc.t('sources'),
          value: response.metadata.sourcesUsed.toString(),
        ),
        const SizedBox(width: 12),
        _MetadataChip(
          icon: Icons.language,
          label: loc.t('language'),
          value: response.metadata.language.toUpperCase(),
        ),
      ],
    );
  }

  Widget _buildActions(
      BuildContext context,
      QueryResponseModel response,
      Query? query,
      AppLocalizations loc,
      ) {
    return Column(
      children: [

        /// ✅ ROW 1 — FEEDBACK
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleFeedback(context, true, response),
                icon: const Icon(Icons.thumb_up),
                label: Text(loc.t('helpful')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleFeedback(context, false, response),
                icon: const Icon(Icons.thumb_down),
                label: Text(loc.t('not_helpful')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        /// ✅ ROW 2 — ESCALATION OPTIONS
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/image_query',
                    arguments: {'response': response},
                  );
                },
                icon: const Icon(Icons.image_outlined),
                label: Text(loc.t('upload_image_btn')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/escalation',
                    arguments: {'response': response},
                  );
                },
                icon: const Icon(Icons.support_agent),
                label: Text(loc.t('talk_to_expert')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        /// ✅ ROW 3 — CONTINUE CHAT
        ElevatedButton.icon(
          onPressed: () => _continueChat(context, query),
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(loc.t('ask_more')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
  void _continueChat(BuildContext context, Query? query) {
    // Navigate to text query screen with previous context
    Navigator.pushNamed(context, '/text_query', arguments: {
      'previousQuery': query?.content,
      'previousResponse': query?.response,
    });
  }

  Future<void> _handleFeedback(BuildContext context, bool helpful, QueryResponseModel response) async {
    final loc = AppLocalizations.of(context);
    // Show thank you message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          helpful 
            ? loc.t('feedback_thanks_pos')
            : loc.t('feedback_thanks_neg'),
        ),
        backgroundColor: helpful ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // TODO: Send feedback to backend API
    // You can implement this later:
    // await apiService.submitFeedback(
    //   queryId: response.queryId,
    //   helpful: helpful,
    // );

    // Wait a moment for the snackbar to be visible
    await Future.delayed(const Duration(milliseconds: 500));

    // Navigate back to home screen
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false, // Remove all previous routes
      );
    }
  }

  QueryResponseModel get _fallbackResponse => QueryResponseModel(
        queryId: 'local_fallback',
        query: 'fallback',
        answer: 'सिस्टम फिलहाल उत्तर प्रदान करने में असमर्थ है। कृपया पुनः प्रयास करें।',
        intent: 'general',
        confidence: 0.5,
        metadata: QueryMetadata(),
        timestamp: DateTime.now(),
      );
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcesList extends StatelessWidget {
  const _SourcesList({required this.sources, required this.loc});

  final List<QuerySource> sources;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.t('sources_used'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        ...sources.map(
          (source) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.bookmark, color: Colors.green.shade600),
              title: Text(source.title),
              subtitle: Text(
                source.content ?? source.type,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: source.score != null
                  ? Chip(
                      label: Text('${(source.score! * 100).toInt()}%'),
                      backgroundColor: Colors.green.shade50,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}