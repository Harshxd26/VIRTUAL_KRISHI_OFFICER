// screens/processing_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/farmer.dart';
import '../models/query.dart';
import '../models/query_request.dart';
import '../models/query_response.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../l10n/app_localizations.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _isImageMode = false;
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();


  ProcessingStatus _status = ProcessingStatus.running;
  String? _errorMessage;
  Map<String, dynamic>? _errorDetails;
  int _currentPhase = 0;
  Timer? _phaseTimer;

  static final List<_PhaseData> _phases = [
    _PhaseData(
      (loc) => loc.t('phase_intent'),
      (loc) => loc.t('phase_intent_sub'),
      Icons.analytics_outlined,
    ),
    _PhaseData(
      (loc) => loc.t('phase_data'),
      (loc) => loc.t('phase_data_sub'),
      Icons.storage_outlined,
    ),
    _PhaseData(
      (loc) => loc.t('phase_answer'),
      (loc) => loc.t('phase_answer_sub'),
      Icons.smart_toy_outlined,
    ),
    _PhaseData(
      (loc) => loc.t('phase_verify'),
      (loc) => loc.t('phase_verify_sub'),
      Icons.verified_outlined,
    ),
  ];

  static final List<_PhaseData> _imagePhases = [
    _PhaseData(
          (loc) => "Scanning Crop Image",
          (loc) => "Analyzing uploaded image",
      Icons.camera_alt,
    ),
    _PhaseData(
          (loc) => "Detecting Symptoms",
          (loc) => "Checking spots and damage",
      Icons.search,
    ),
    _PhaseData(
          (loc) => "Identifying Disease",
          (loc) => "AI analyzing crop condition",
      Icons.bug_report,
    ),
    _PhaseData(
          (loc) => "Preparing Treatment",
          (loc) => "Generating solution for farmer",
      Icons.medical_services,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _processQuery());
    _phaseTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        if (_currentPhase < _phases.length - 1) {
          _currentPhase += 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _processQuery() async {
    final startTime = DateTime.now();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      Navigator.pop(context);
      return;
    }

    final String queryText = (args['query'] as String?)?.trim() ?? '';
    if (queryText.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final String type = (args['type'] ?? 'text').toString();

    late QueryType queryType;

    if (type == 'image') {
      queryType = QueryType.image;
    } else if (type == 'voice') {
      queryType = QueryType.voice;
    } else {
      queryType = QueryType.text;
    }

    _isImageMode = queryType == QueryType.image;

    print("Received type = $type");
    print("Resolved queryType = $queryType");
    print("Image mode = $_isImageMode");

    _isImageMode = queryType == QueryType.image;

    print("Query Type = $queryType");
    print("Image Mode = $_isImageMode");

    try {
      final farmer = await _storageService.getFarmerProfile();
      final contextPayload = await _buildContext(args, farmer, queryType);

      // Get location from profile (should be mandatory now)
      double? latitude = farmer?.latitude;
      double? longitude = farmer?.longitude;
      
      // If location is still missing, try to get it but show warning
      if (latitude == null || longitude == null) {
        try {
          final position = await _locationService.getCurrentPosition();
          if (position != null) {
            latitude = position.latitude;
            longitude = position.longitude;
            // Update farmer profile with location
            if (farmer != null) {
              final updatedFarmer = farmer.copyWith(
                latitude: latitude,
                longitude: longitude,
              );
              await _storageService.saveFarmerProfile(updatedFarmer);
            }
          }
        } catch (e) {
          // Location not available, continue without it - backend can handle it
          // User should have provided location during profile setup
        }
      }

      final request = QueryRequest(
        query: queryText,
        latitude: latitude,
        longitude: longitude,
        state: farmer?.state ?? _parseLocationPart(farmer?.districtState, 1),
        district: farmer?.district ?? _parseLocationPart(farmer?.districtState, 0),
        language: (farmer?.languageCode?.isNotEmpty ?? false) ? farmer!.languageCode : 'hi',
        userId: farmer?.id,
        context: contextPayload.isEmpty ? null : contextPayload,
      );

      QueryResponseModel response;

      if (queryType == QueryType.image) {
        final imagePath = args['imagePath'] as String?;
        if (imagePath == null) {
          throw Exception("Image not found");
        }

        response = await _apiService.sendImage(File(imagePath));

      } else {
        // text + voice use same pipeline
        response = await _apiService.sendQuery(request);
        // Ensure minimum processing time (2.5 seconds)
        const minProcessingTime = Duration(milliseconds: 7500);

        final elapsed = DateTime.now().difference(startTime);

        if (elapsed < minProcessingTime) {
          await Future.delayed(minProcessingTime - elapsed);
        }
      }

      final queryRecord = Query(
        id: response.queryId,
        content: queryText,
        type: queryType,
        timestamp: response.timestamp,
        status: QueryStatus.answered,
        imagePath: args['imagePath'] as String?,
        context: request.context,
        response: response,
      );

      await _storageService.saveQuery(queryRecord);

      // ---- FORCE MINIMUM PROCESSING TIME ----
      final elapsed =
          DateTime.now().difference(startTime).inMilliseconds;

      const minDuration = 7500; // 7.5 seconds

      if (elapsed < minDuration) {
        await Future.delayed(
            Duration(milliseconds: minDuration - elapsed));
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/ai_answer',
        arguments: {
          'query': queryRecord,
          'response': response,
        },
      );
    } on ApiException catch (error) {
      _handleError(error.message, error.details);
    } catch (error) {
      _handleError('सर्वर से संपर्क नहीं हो सका। कृपया पुनः प्रयास करें।', {'error': error.toString()});
    }
  }

  void _handleError(String message, Map<String, dynamic>? details) {
    if (!mounted) return;
    setState(() {
      _status = ProcessingStatus.error;
      _errorMessage = message;
      _errorDetails = details;
      _phaseTimer?.cancel();
    });
  }

  Future<Map<String, dynamic>> _buildContext(
    Map<String, dynamic> args,
    Farmer? farmer,
    QueryType queryType,
  ) async {
    final context = <String, dynamic>{
      'input_mode': queryType.name,
      if (farmer?.mainCrops.isNotEmpty ?? false) 'farmer_main_crops': farmer!.mainCrops,
    };

    final imagePath = args['imagePath'] as String?;
    if (imagePath != null) {
      final imageBase64 = await _encodeImageToBase64(imagePath);
      if (imageBase64 != null) {
        context['image_base64'] = imageBase64;
      }
    }

    return context;
  }

  Future<String?> _encodeImageToBase64(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }

  String? _parseLocationPart(String? districtState, int index) {
    if (districtState == null || districtState.isEmpty) return null;
    final parts = districtState.split(',').map((part) => part.trim()).toList();
    if (index >= parts.length) return null;
    return parts[index];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _status == ProcessingStatus.error ? _buildErrorState(loc) : _buildProcessingState(loc),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingState(AppLocalizations loc) {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final isImageMode = args?['type'] == 'image';

    final phases = isImageMode ? _imagePhases : _phases;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: child,
            ),
            child: const Text('🌿', style: TextStyle(fontSize: 96)),
          ),
          const SizedBox(height: 16),
          Text(
            loc.t('processing_title'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            loc.t('processing_sub'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...List.generate(phases.length, (index) {
            final phase = phases[index];
            final isActive = index == _currentPhase;
            final isCompleted = index < _currentPhase;
            final color = isCompleted
                ? Colors.green
                : isActive
                    ? Colors.orange
                    : Colors.grey.shade400;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.shade50
                    : isActive
                        ? Colors.orange.shade50
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    phase.icon,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.title(loc),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phase.subtitle(loc),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isCompleted
                        ? Icons.check_circle
                        : isActive
                            ? Icons.sync
                            : Icons.radio_button_unchecked,
                    color: color,
                  )
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 72, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? loc.t('fallback_answer'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          if (_errorDetails?['query_id'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Query ID: ${_errorDetails?['query_id']}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _status = ProcessingStatus.running;
                  _errorMessage = null;
                  _errorDetails = null;
                  _currentPhase = 0;
                  _phaseTimer?.cancel();
                  _phaseTimer = Timer.periodic(const Duration(seconds: 2), (_) {
                    if (!mounted) return;
                    setState(() {
                      if (_currentPhase < _phases.length - 1) {
                        _currentPhase += 1;
                      }
                    });
                  });
                });
                _processQuery();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(
                loc.t('retry'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.t('later')),
            ),
          ),
        ],
      ),
    );
  }
}

enum ProcessingStatus { running, error }

class _PhaseData {
  const _PhaseData(this.title, this.subtitle, this.icon);

  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) subtitle;
  final IconData icon;
}