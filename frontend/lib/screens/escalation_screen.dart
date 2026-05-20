// screens/escalation_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/query_response.dart';
import '../services/storage_service.dart';
import '../models/support_ticket.dart';


class EscalationScreen extends StatefulWidget {
  const EscalationScreen({super.key});

  @override
  _EscalationScreenState createState() => _EscalationScreenState();
}

class _EscalationScreenState extends State<EscalationScreen> {
  final StorageService _storageService = StorageService();

  void _createTicket() async {
    final ticketId =
        "KR-${const Uuid().v4().substring(0, 8).toUpperCase()}";

    final ticket = SupportTicket(
      ticketId: ticketId,
      query: "Farmer requested expert help",
      createdAt: DateTime.now(),
      status: "Pending",
      officerResponse: null,
    );

    await _storageService.saveSupportTicket(ticket);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Support Ticket Created"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Your request has been sent to Agriculture Officer."),
            const SizedBox(height: 12),
            Text(
              ticketId,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text("Expected response within 24 hours."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  final Uuid _uuid = Uuid();
  bool _isLoading = false;

  Future<void> _escalateToOfficer(bool shouldEscalate) async {
    if (!shouldEscalate) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final response = args?['response'] as QueryResponseModel?;

    // Generate ticket ID
    final ticketId = 'DGO-${_uuid.v4().substring(0, 4).toUpperCase()}';

    // Simulate API call to escalate
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('सफलतापूर्वक भेजा गया'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'आपका सवाल कृषि अधिकारी को भेज दिया गया है।\n\nवे 24 घंटे में संपर्क करेंगे।',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ticket ID: #$ticketId',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              },
              child: Text(
                'ठीक है',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final response = args?['response'] as QueryResponseModel?;
    final needsEscalation = response?.shouldEscalate ?? false;
    final lowConfidence = (response?.confidence ?? 1.0) < 0.6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk to Expert'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'tickets') {
                Navigator.pushNamed(context, '/tickets');
              } else if (value == 'create') {
                _createTicket();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'tickets',
                child: ListTile(
                  leading: Icon(Icons.confirmation_number),
                  title: Text('My Tickets'),
                ),
              ),
              const PopupMenuItem(
                value: 'create',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Create Ticket'),
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

              Positioned(
              top: -80,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.08),
                ),
              ),
            ),

            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.08),
                ),
              ),
            ),

            Padding(padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade600,
                          Colors.blue.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [

                        Row(
                          children: [
                            Icon(
                              Icons.support_agent,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Agriculture Expert Support",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 14),

                        Text(
                          "Connect with agriculture officers for expert farming guidance, urgent crop issues, and personalized support.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  const SizedBox(height: 30),

                  _buildOptionCard(
                    context,
                    icon: Icons.confirmation_number,
                    color: Colors.green,
                    title: "Create Support Ticket",
                    subtitle: "Officer will review and respond within 24 hours",
                    route: "ticket",
                  ),

                  const SizedBox(height: 16),

                  _buildOptionCard(
                    context,
                    icon: Icons.priority_high,
                    color: Colors.orange,
                    title: "Priority Support",
                    subtitle: "Urgent farming issue — faster response",
                    route: "priority",
                  ),

                  const SizedBox(height: 16),

                  _buildOptionCard(
                    context,
                    icon: Icons.video_call,
                    color: Colors.blue,
                    title: "Schedule Call",
                    subtitle: "Book audio/video consultation",
                    route: "schedule",
                  )
                    ],
                  ),
            ),
              ],
            ),
        ),
    );
  }
  Widget _buildOptionCard(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required String subtitle,
        required String route,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (route == "ticket") {
              _createTicket();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$title coming soon")),
              );
            }
          },
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 18),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
  }
}