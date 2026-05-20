// screens/ticket_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/support_ticket.dart';

class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)?.settings.arguments as SupportTicket?;

    if (args == null) {
      return const Scaffold(
        body: Center(child: Text("Ticket not found")),
      );
    }

    final ticket = args;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Support Ticket"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Ticket Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ticket ID: ${ticket.ticketId}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("Status: ${ticket.status}"),
                  Text(
                    "Created: ${ticket.createdAt.toLocal()}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Farmer Query
            const Text(
              "👨‍🌾 Farmer Question",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(ticket.query),
            ),

            const SizedBox(height: 24),

            /// Officer Response
            const Text(
              "👩‍🌾 Agriculture Officer Reply",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ticket.officerResponse == null
                    ? Colors.orange.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ticket.officerResponse == null
                      ? Colors.orange.shade200
                      : Colors.blue.shade200,
                ),
              ),
              child: Text(
                ticket.officerResponse ??
                    "Officer has not responded yet.\nExpected within 24 hours.",
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}