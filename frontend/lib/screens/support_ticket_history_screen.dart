import 'package:flutter/material.dart';
import '../models/support_ticket.dart';
import '../services/storage_service.dart';

class SupportTicketHistoryScreen extends StatefulWidget {
  const SupportTicketHistoryScreen({super.key});

  @override
  State<SupportTicketHistoryScreen> createState() =>
      _SupportTicketHistoryScreenState();
}

class _SupportTicketHistoryScreenState
    extends State<SupportTicketHistoryScreen> {
  final StorageService _storageService = StorageService();

  List<SupportTicket> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final tickets = await _storageService.getSupportTickets();

    setState(() {
      _tickets = tickets;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Support Tickets"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
          ? const Center(
        child: Text(
          "No tickets created yet",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];

          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.confirmation_number,
                  color: Colors.green),
              title: Text(ticket.ticketId),
              subtitle: Text(
                "Status: ${ticket.status}\nCreated: ${ticket.createdAt.toLocal()}",
              ),
            ),
          );
        },
      ),
    );
  }
}