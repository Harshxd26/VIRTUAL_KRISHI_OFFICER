import 'package:flutter/material.dart';
import '../models/query.dart';
import 'package:intl/intl.dart';

class QueryCard extends StatelessWidget {
  final Query query;
  final VoidCallback? onTap;

  const QueryCard({super.key, required this.query, this.onTap});

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(query.timestamp);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          query.type == QueryType.text
              ? Icons.text_snippet
              : query.type == QueryType.voice
              ? Icons.mic
              : Icons.image,
          color: Colors.green,
        ),
        title: Text(query.content, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(formattedTime),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
