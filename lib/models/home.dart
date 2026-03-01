class Home {
  final String name;
  final double latitude;
  final double longitude;
  final String? vacUrl; 
  final bool isAerodrome;
  final bool isRoute;
  final List<Map<String, dynamic>>? routePoints; // List of {lat, lon, name}
  final List<Map<String, dynamic>>? segmentNotes; // List of {text, segmentIndex, ratio}
  final Map<String, String>? notes; // General markers notes
  final Map<String, String>? photos; // General markers photos

  Home({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.vacUrl,
    this.isAerodrome = false,
    this.isRoute = false,
    this.routePoints,
    this.segmentNotes,
    this.notes,
    this.photos,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'vacUrl': vacUrl,
    'isAerodrome': isAerodrome,
    'isRoute': isRoute,
    'routePoints': routePoints,
    'segmentNotes': segmentNotes,
    'notes': notes,
    'photos': photos,
  };

  factory Home.fromJson(Map<String, dynamic> json) => Home(
    name: json['name'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    vacUrl: json['vacUrl'],
    isAerodrome: json['isAerodrome'] ?? false,
    isRoute: json['isRoute'] ?? false,
    routePoints: json['routePoints'] != null 
        ? (json['routePoints'] as List).map((e) => Map<String, dynamic>.from(e)).toList()
        : null,
    segmentNotes: json['segmentNotes'] != null
        ? (json['segmentNotes'] as List).map((e) => Map<String, dynamic>.from(e)).toList()
        : null,
    notes: json['notes'] != null ? Map<String, String>.from(json['notes']) : null,
    photos: json['photos'] != null ? Map<String, String>.from(json['photos']) : null,
  );
  
  Home copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? vacUrl,
    bool? isAerodrome,
    bool? isRoute,
    List<Map<String, dynamic>>? routePoints,
    List<Map<String, dynamic>>? segmentNotes,
    Map<String, String>? notes,
    Map<String, String>? photos,
  }) {
    return Home(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      vacUrl: vacUrl ?? this.vacUrl,
      isAerodrome: isAerodrome ?? this.isAerodrome,
      isRoute: isRoute ?? this.isRoute,
      routePoints: routePoints ?? this.routePoints,
      segmentNotes: segmentNotes ?? this.segmentNotes,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
    );
  }
}
