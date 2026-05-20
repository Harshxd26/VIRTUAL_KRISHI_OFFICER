class SupportTicket {
  final String ticketId;
  final String query;
  final DateTime createdAt;
  final String status;

  final String? officerResponse;


  SupportTicket({
    required this.ticketId,
    required this.query,
    required this.createdAt,
    required this.status,
    this.officerResponse,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      ticketId: json['ticketId'],
      query: json['query'],
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'query': query,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}