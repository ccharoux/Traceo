class Home {
  final String name;
  final double latitude;
  final double longitude;
  final String? vacUrl; 
  final bool isAerodrome;
  final bool isRoute;
  final List<Map<String, dynamic>>? routePoints; // List of {lat, lon, name}

  Home({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.vacUrl,
    this.isAerodrome = false,
    this.isRoute = false,
    this.routePoints,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'vacUrl': vacUrl,
    'isAerodrome': isAerodrome,
    'isRoute': isRoute,
    'routePoints': routePoints,
  };

  factory Home.fromJson(Map<String, dynamic> json) => Home(
    name: json['name'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    vacUrl: json['vacUrl'],
    isAerodrome: json['isAerodrome'] ?? false,
    isRoute: json['isRoute'] ?? false,
    routePoints: json['routePoints'] != null 
        ? List<Map<String, dynamic>>.from(json['routePoints']) 
        : null,
  );
  
  Home copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? vacUrl,
    bool? isAerodrome,
    bool? isRoute,
    List<Map<String, dynamic>>? routePoints,
  }) {
    return Home(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      vacUrl: vacUrl ?? this.vacUrl,
      isAerodrome: isAerodrome ?? this.isAerodrome,
      isRoute: isRoute ?? this.isRoute,
      routePoints: routePoints ?? this.routePoints,
    );
  }
}
