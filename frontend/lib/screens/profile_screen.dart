import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/farmer.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _districtStateController =
  TextEditingController();
  final TextEditingController _cropsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isGettingLocation = false;

  double? _latitude;
  double? _longitude;

  Future<void> _loadFarmerData() async {
    final farmer = await _storageService.getFarmerProfile();


    if (farmer == null) return;

    setState(() {
      _nameController.text = farmer.name ?? '';
      _districtStateController.text = farmer.districtState ?? '';
      _cropsController.text = farmer.mainCrops ?? '';
      _phoneController.text = farmer.phoneNumber ?? '';

      _latitude = farmer.latitude;
      _longitude = farmer.longitude;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadFarmerData(); // ✅ auto load farmer profile
  }

  @override
  void dispose() {
    _nameController.dispose();
    _districtStateController.dispose();
    _cropsController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ---------------- LOCATION ----------------

  Future<void> _getLocation() async {
    final loc = AppLocalizations.of(context);

    setState(() => _isGettingLocation = true);

    try {
      final position = await _locationService.getCurrentPosition();

      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('location_success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(loc.t('location_error', params: {'error': '$e'})),
          backgroundColor: Colors.red,
        ),
      );
    }


    setState(() => _isGettingLocation = false);
  }


  // ---------------- SAVE PROFILE ----------------

  Future<void> _saveProfile() async {
    final loc = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('location_required')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final preferredLanguage = await _storageService.getLanguage();
    final existingFarmer = await _storageService.getFarmerProfile();


    final farmer = Farmer(
      id: existingFarmer?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      districtState: _districtStateController.text.trim(),
      mainCrops: _cropsController.text.trim(),
      language: preferredLanguage,
      languageCode: preferredLanguage == 'English' ? 'en' : 'hi',
      latitude: _latitude,
      longitude: _longitude,
    );

    await _storageService.saveFarmerProfile(farmer);

    setState(() => _isLoading = false);

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/home');
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('profile_title')),
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

            SafeArea(child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade600,
                            Colors.green.shade400,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [

                          CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            loc.t('profile_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            "Manage your farming profile, crops, language and location details.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.72),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.green.shade400,
                            width: 1.5,
                          ),
                        ),
                        labelText: loc.t('name'),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (v) =>
                      v == null || v.isEmpty ? loc.t('name_required') : null,
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.72),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.green.shade400,
                            width: 1.5,
                          ),
                        ),
                        labelText: loc.t('phone_number'),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return loc.t('phone_required');
                        }
                        if (value.length < 10) {
                          return loc.t('phone_invalid');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _districtStateController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.72),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.green.shade400,
                            width: 1.5,
                          ),
                        ),
                        labelText: loc.t('district_state'),
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _isGettingLocation ? null : _getLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(loc.t('get_gps')),
                    ),

                    if (_latitude != null && _longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Location saved ✓",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _cropsController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.72),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.green.shade400,
                            width: 1.5,
                          ),
                        ),
                        labelText: loc.t('crops'),
                        prefixIcon: const Icon(Icons.eco),
                      ),
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade600,
                              Colors.green.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : Text(
                            loc.t('save'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
      ],
    ),
        ),
    );
  }
}