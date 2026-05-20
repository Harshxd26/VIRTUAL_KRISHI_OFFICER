class Farmer {
  Farmer({
    required this.id,
    required this.name,
    this.phoneNumber,
    required this.districtState,
    required this.mainCrops,
    this.language = 'Hindi',
    this.languageCode = 'hi',
    this.state,
    this.district,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String? phoneNumber;
  final String districtState;
  final String mainCrops;
  final String language;
  final String languageCode;
  final String? state;
  final String? district;
  final double? latitude;
  final double? longitude;

  Farmer copyWith({
    String? name,
    String? phoneNumber,
    String? districtState,
    String? mainCrops,
    String? language,
    String? languageCode,
    String? state,
    String? district,
    double? latitude,
    double? longitude,
  }) {
    return Farmer(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      districtState: districtState ?? this.districtState,
      mainCrops: mainCrops ?? this.mainCrops,
      language: language ?? this.language,
      languageCode: languageCode ?? this.languageCode,
      state: state ?? this.state,
      district: district ?? this.district,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'districtState': districtState,
        'mainCrops': mainCrops,
        'language': language,
        'languageCode': languageCode,
        'state': state,
        'district': district,
        'latitude': latitude,
        'longitude': longitude,
      }..removeWhere((key, value) => value == null);

  factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
        id: json['id'],
        name: json['name'],
        phoneNumber: json['phoneNumber'],
        districtState: json['districtState'] ?? json['district'] ?? '',
        mainCrops: json['mainCrops'],
        language: json['language'] ?? 'Hindi',
        languageCode: json['languageCode'] ?? 'hi',
        state: json['state'],
        district: json['district'],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
