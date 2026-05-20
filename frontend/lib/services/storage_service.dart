import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/query.dart';
import '../models/farmer.dart';
import 'dart:convert';
import '../models/support_ticket.dart';

class StorageService {
  static const String _farmerKey = 'farmer_profile';
  static const String _queriesKey = 'queries';
  static const String _languageKey = 'selected_language';
  final Future<SharedPreferences> _prefs =
  SharedPreferences.getInstance();

  // Farmer Profile Methods
  Future<void> saveFarmerProfile(Farmer farmer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_farmerKey, jsonEncode(farmer.toJson()));
  }

  Future<void> clearFarmerProfile() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('farmer_profile');
    await prefs.remove('language');
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  Future<Farmer?> getFarmerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final farmerJson = prefs.getString(_farmerKey);
    if (farmerJson != null) {
      return Farmer.fromJson(jsonDecode(farmerJson));
    }
    return null;
  }

  Future<bool> hasFarmerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_farmerKey);
  }

  // Query Methods
  Future<void> saveQuery(Query query) async {
    final prefs = await SharedPreferences.getInstance();
    final savedQueries = prefs.getStringList(_queriesKey) ?? [];
    final decoded = savedQueries
        .map((entry) => Query.fromJson(jsonDecode(entry)))
        .where((existing) => existing.id != query.id)
        .toList();
    decoded.insert(0, query);
    final encoded = decoded.map((q) => jsonEncode(q.toJson())).toList();
    await prefs.setStringList(_queriesKey, encoded);
  }

  Future<List<Query>> getQueries() async {
    final prefs = await SharedPreferences.getInstance();
    final savedQueries = prefs.getStringList(_queriesKey) ?? [];
    final queries = savedQueries.map((q) => Query.fromJson(jsonDecode(q))).toList();
    queries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return queries;
  }

  // Language Methods
  Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'Hindi';
  }

  // ---------------- SUPPORT TICKETS ----------------

  Future<void> saveSupportTicket(SupportTicket ticket) async {
    final prefs = await _prefs;

    final tickets = await getSupportTickets();
    tickets.add(ticket);

    final encoded =
    jsonEncode(tickets.map((t) => t.toJson()).toList());

    await prefs.setString('support_tickets', encoded);
  }

  Future<List<SupportTicket>> getSupportTickets() async {
    final prefs = await _prefs;

    final data = prefs.getString('support_tickets');

    if (data == null) return [];

    final decoded = jsonDecode(data) as List;

    return decoded
        .map((e) => SupportTicket.fromJson(e))
        .toList();
  }
}
