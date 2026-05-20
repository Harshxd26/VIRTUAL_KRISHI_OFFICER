// screens/history_screen.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/query.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storageService = StorageService();
  List<Query> _queries = [];
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadQueries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when coming back to this screen
    _loadQueries();
  }

  Future<void> _loadQueries() async {
    setState(() {
      _isLoading = true;
    });

    final queries = await _storageService.getQueries();
    queries.sort((a, b) => b.timestamp.compareTo(a.timestamp));


    setState(() {
      _queries = queries;
      _isLoading = false;
    });
  }

  String _getTimeAgo(
      DateTime timestamp,
      AppLocalizations loc,
      ) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${loc.t('days_ago')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${loc.t('hours_ago')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${loc.t('minutes_ago')}';
    } else {
      return loc.t('just_now');
    }
  }

  String _getStatusEmoji(QueryStatus status) {
    switch (status) {
      case QueryStatus.answered:
        return '✅';
      case QueryStatus.escalated:
        return '🔁';
      case QueryStatus.resolved:
        return '✔️';
      case QueryStatus.pending:
        return '⏳';
    }
  }

  String _getStatusText(
      QueryStatus status,
      AppLocalizations loc,
      ) {
    switch (status) {
      case QueryStatus.answered:
        return loc.t('answered');

      case QueryStatus.escalated:
        return loc.t('escalated');

      case QueryStatus.resolved:
        return loc.t('resolved');

      case QueryStatus.pending:
        return loc.t('processing');
    }
  }

  Future<void> _showQueryDetails(Query query) async {
    final loc = AppLocalizations.of(context);
    final response = query.response;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history,
                            size: 60,
                            color: Colors.green.shade600,
                          ),
                        ),

                        const SizedBox(height: 22),

                        Text(
                          loc.t('no_history'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "Your AI farming queries and responses will appear here.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                Text(
                  loc.t('question_label'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    query.content,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      '🗓️',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(query.timestamp),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _getStatusEmoji(query.status),
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _getStatusText(query.status, loc),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (response != null) ...[
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 20),
                  Text(
                    loc.t('ai_advice_title'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 12),
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'loc.t(ai_generated): ${response.intent}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            response.answer,
                            style: TextStyle(fontSize: 14, height: 1.4),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '${loc.t('confidence')}: ${(response.confidence * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("📜 "),
            Expanded(
              child: Text(loc.t('history_title')),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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

              Positioned(
              top: -80,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.08),
                ),
              ),
            ),

            Positioned(
              bottom: -120,
              left: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.lightGreen.withOpacity(0.08),
                ),
              ),
            ),

            SafeArea(child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _queries.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 90,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: 20),
                  Text(
                    loc.t('no_history'),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadQueries,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _queries.length,
                itemBuilder: (context, index) {
                  final query = _queries[index];
                  final response = query.response;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.96, end: 1),
                    duration: Duration(
                      milliseconds: 350 + (index * 80),
                    ),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _showQueryDetails(query),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // ICON
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: query.type == QueryType.image
                                        ? Colors.purple.withOpacity(0.12)
                                        : query.type == QueryType.voice
                                        ? Colors.orange.withOpacity(0.12)
                                        : Colors.green.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    query.type == QueryType.image
                                        ? Icons.camera_alt
                                        : query.type == QueryType.voice
                                        ? Icons.mic
                                        : Icons.smart_toy,
                                    color: query.type == QueryType.image
                                        ? Colors.purple
                                        : query.type == QueryType.voice
                                        ? Colors.orange
                                        : Colors.green,
                                    size: 28,
                                  ),
                                ),

                                const SizedBox(width: 18),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [

                                      Text(
                                        query.content.length > 70
                                            ? '${query.content.substring(0, 70)}...'
                                            : query.content,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          height: 1.4,
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      Row(
                                        children: [

                                          Container(
                                            padding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                              Colors.green.withOpacity(0.1),
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getStatusText(query.status , loc),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 8),

                                          Text(
                                            _getTimeAgo(query.timestamp , loc),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (response != null) ...[
                                        const SizedBox(height: 10),

                                        Row(
                                          children: [

                                            Expanded(
                                              child: Text(
                                                response.intent,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                  Colors.grey.shade600,
                                                ),
                                              ),
                                            ),

                                            Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                BorderRadius.circular(
                                                    12),
                                              ),
                                              child: Text(
                                                '${(response.confidence * 100).toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                  FontWeight.bold,
                                                  color:
                                                  Colors.blue.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 18,
                                  color: Colors.grey.shade500,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}