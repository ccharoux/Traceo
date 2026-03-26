import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'home.dart';
import '../components/routs.dart';

class LocaData with ChangeNotifier {
  // --- APP STATE ---
  bool isTracking = false;
  bool isAddingNote = false;
  bool isSimulatedFlight = false;

  // --- TRACE DATA ---
  List<Position> trace = [];
  
  Map<String, String> notes = {};
  Map<String, int> pauses = {};
  Map<String, String> photos = {}; 
  
  DateTime? _pauseStartTime;
  String? _noteInCurrentPauseKey;

  String travelledLength = "0 m";
  double travelledLengthDble = 0.0;
  int? dureeInt = 0;
  int walkingTime = 0;
  String speed = "0.0 kmh";
  double speedValue = 0.0; 
  String altitude = "0 m";
  String startTime = '';

  List<Position> _simulationData = [];
  List<Position> get simulationData => _simulationData;

  void setSimulationData(List<Position> data, {bool isFlight = false}) {
    _simulationData = data;
    isSimulatedFlight = isFlight;
    notifyListeners();
  }

  // --- TARGET DATA ---
  Home? _activeTarget;
  int _currentWaypointIndex = 0;
  String? nextHeadingMessage;
  final List<int> _triggeredSegmentNotes = [];

  bool destType=false;
  String distanceTarget = "0 m";
  String bearingToTarget = "0°";
  double bearingToTargetDble = 0.0;
  int angle = 0;

  // --- DEVICE DATA ---
  String heading = "0°";
  double headingDble = 0.0;

  Home? get activeTarget => _activeTarget;
  int get currentWaypointIndex => _currentWaypointIndex;

  String get duree {
    final int seconds = dureeInt ?? 0;
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void startTracking() {
    isTracking = true;
    isSimulatedFlight = false;
    _currentWaypointIndex = (_activeTarget != null && _activeTarget!.isRoute && (_activeTarget!.routePoints?.length ?? 0) > 1) ? 1 : 0;
    nextHeadingMessage = null;
    _triggeredSegmentNotes.clear();
    notifyListeners();
  }

  void stopTracking() {
    isTracking = false;
    notifyListeners();
  }

  void updateActiveTarget(Home newTarget, Position currentPosition) {
    _activeTarget = newTarget;
    _currentWaypointIndex = (newTarget.isRoute && (newTarget.routePoints?.length ?? 0) > 1) ? 1 : 0;
    nextHeadingMessage = null;
    _triggeredSegmentNotes.clear();
    
    // Charger les notes et photos si elles existent dans le Home
    notes.clear();
    if (newTarget.notes != null) notes.addAll(newTarget.notes!);
    photos.clear();
    if (newTarget.photos != null) photos.addAll(newTarget.photos!);

    recalculateTargetMetrics(currentPosition);
    notifyListeners();
  }

  void resetTarget() {
    _activeTarget = null;
    _currentWaypointIndex = 0;
    nextHeadingMessage = null;
    _triggeredSegmentNotes.clear();
    distanceTarget = "0 m";
    bearingToTarget = "0°";
    bearingToTargetDble = 0.0;
    angle = 0;
    notifyListeners();
  }

  String _getPosKey(DateTime dt) => dt.toLocal().toIso8601String().split('.')[0];

  bool updatePosition(Position newPosition) {
    if (newPosition.accuracy > 50) return false;

    if (trace.isEmpty) {
      startTime = _formatStartTime(newPosition.timestamp);
      trace.add(newPosition);
      recalculateTargetMetrics(newPosition);
      return true;
    }

    final lastPosition = trace.last;
    final timeDiff = newPosition.timestamp.difference(lastPosition.timestamp).inSeconds;
    if (timeDiff <= 0) return false;

    final distance = Geolocator.distanceBetween(
      lastPosition.latitude, lastPosition.longitude,
      newPosition.latitude, newPosition.longitude,
    );
    
    dureeInt = (dureeInt ?? 0) + timeDiff;
    bool isMoving = distance > 2.0 && newPosition.speed * 3.6 > 0.5;

    if (isMoving) { 
      if (_pauseStartTime != null) {
        _pauseStartTime = null;
        _noteInCurrentPauseKey = null;
      }
      travelledLengthDble += distance;
      walkingTime += timeDiff;
      trace.add(newPosition);
    } else { 
      _pauseStartTime ??= lastPosition.timestamp;
      
      final String lastKey = _getPosKey(lastPosition.timestamp);
      if (!notes.containsKey(lastKey) && !photos.containsKey(lastKey)) {
        trace[trace.length - 1] = newPosition;
      }
    }
    
    travelledLength = affKms(travelledLengthDble);
    speedValue = newPosition.speed * 3.6;
    speed = '${speedValue.toStringAsFixed(1)} kmh';
    altitude = '${newPosition.altitude.toStringAsFixed(0)} m';
    headingDble = newPosition.heading;
    heading = '${headingDble.toStringAsFixed(0)}°';

    recalculateTargetMetrics(newPosition);
    _checkWaypointProximity(newPosition);
    _checkSegmentNotesProximity(newPosition);
    
    return true;
  }

  void _checkWaypointProximity(Position currentPosition) {
    if (_activeTarget == null || !_activeTarget!.isRoute || _activeTarget!.routePoints == null) return;
    if (_currentWaypointIndex >= _activeTarget!.routePoints!.length - 1) return;

    final targetWP = _activeTarget!.routePoints![_currentWaypointIndex];
    double distToWP = Geolocator.distanceBetween(
      currentPosition.latitude, currentPosition.longitude,
      targetWP['lat'], targetWP['lon'],
    );

    // Si on est à moins de 300 mètres du point (ajustable pour le vol)
    if (distToWP < 300) {
      _currentWaypointIndex++;
      final nextWP = _activeTarget!.routePoints![_currentWaypointIndex];
      
      // On calcule le cap entre le point qu'on vient d'atteindre et le suivant
      double nextBearing = Geolocator.bearingBetween(
        targetWP['lat'], targetWP['lon'],
        nextWP['lat'], nextWP['lon'],
      );
      if (nextBearing < 0) nextBearing += 360;
      
      nextHeadingMessage = "${ol('wp_reached')} ${targetWP['name']}\n${ol('heading_to')} ${nextWP['name']}: ${nextBearing.toStringAsFixed(0)}°";
      notifyListeners();
    }
  }

  void _checkSegmentNotesProximity(Position currentPosition) {
    if (_activeTarget == null || !_activeTarget!.isRoute || _activeTarget!.segmentNotes == null) return;
    
    final notes = _activeTarget!.segmentNotes!;
    final routePoints = _activeTarget!.routePoints!;

    for (int i = 0; i < notes.length; i++) {
      if (_triggeredSegmentNotes.contains(i)) continue;

      final note = notes[i];
      final int segIdx = note['segmentIndex'];
      if (segIdx >= routePoints.length - 1) continue;
      
      final p1 = routePoints[segIdx];
      final p2 = routePoints[segIdx+1];

      final notePos = Geolocator.distanceBetween(
        p1['lat'], p1['lon'],
        p2['lat'], p2['lon'],
      ) * note['ratio'];

      final bearingToNote = Geolocator.bearingBetween(p1['lat'], p1['lon'], p2['lat'], p2['lon']);
      
      final noteLat = p1['lat'] + (notePos / 111111) * Geolocator.bearingBetween(0,0,1,0);
      final noteLon = p1['lon'] + (notePos / (111111 * Geolocator.bearingBetween(0,0,0,1))) * Geolocator.bearingBetween(0,0,0,1);

      double distToNote = Geolocator.distanceBetween(
        currentPosition.latitude, currentPosition.longitude,
        noteLat, noteLon,
      );
      
      // Si on est à moins de 500m de la note
      if (distToNote < 500) {
        nextHeadingMessage = "${ol('note_prefix')} ${note['text']}";
        _triggeredSegmentNotes.add(i);
        notifyListeners();
        break; // On n'affiche qu'une note à la fois
      }
    }
  }

  int getPauseDuration(DateTime timestamp) {
    final String key = _getPosKey(timestamp);
    if (pauses.containsKey(key)) return pauses[key]!;
    
    if (_pauseStartTime != null) {
      if (key == _noteInCurrentPauseKey || (trace.isNotEmpty && key == _getPosKey(trace.last.timestamp))) {
        return DateTime.now().difference(_pauseStartTime!).inSeconds;
      }
    }
    return 0;
  }

  Position addNoteAtPosition(Position position, String note) {
    Position targetPos = position;
    if (_pauseStartTime != null && trace.isNotEmpty) {
      targetPos = trace.last;
    } else {
      if (isTracking && !trace.any((p) => _getPosKey(p.timestamp) == _getPosKey(position.timestamp))) {
        trace.add(position);
      }
    }
    
    final String key = _getPosKey(targetPos.timestamp);
    notes[key] = note;
    if (_pauseStartTime != null) {
      _noteInCurrentPauseKey = key;
    }
    notifyListeners();
    return targetPos;
  }

  Position addPhotoAtPosition(Position position, String base64Vignette) {
    Position targetPos = position;
    if (_pauseStartTime != null && trace.isNotEmpty) {
      targetPos = trace.last;
    } else {
      if (isTracking && !trace.any((p) => _getPosKey(p.timestamp) == _getPosKey(position.timestamp))) {
        trace.add(position);
      }
    }
    
    final String key = _getPosKey(targetPos.timestamp);
    photos[key] = base64Vignette;
    notifyListeners();
    return targetPos;
  }

  void removePhotoAtPosition(DateTime timestamp) {
    final String key = _getPosKey(timestamp);
    photos.remove(key);
    notifyListeners();
  }

  void removeNoteAtPosition(DateTime timestamp) {
    final String key = _getPosKey(timestamp);
    notes.remove(key);
    notifyListeners();
  }

  void removeNoteAndPhotoAtPosition(DateTime timestamp) {
    final String key = _getPosKey(timestamp);
    notes.remove(key);
    photos.remove(key);
    notifyListeners();
  }

  void recalculateTargetMetrics(Position currentPosition) {
    if (_activeTarget != null) {
      double targetLat = _activeTarget!.latitude;
      double targetLon = _activeTarget!.longitude;

      if (_activeTarget!.isRoute && _activeTarget!.routePoints != null && _currentWaypointIndex < _activeTarget!.routePoints!.length) {
        targetLat = _activeTarget!.routePoints![_currentWaypointIndex]['lat'];
        targetLon = _activeTarget!.routePoints![_currentWaypointIndex]['lon'];
      }

      double distance = Geolocator.distanceBetween(
        currentPosition.latitude, currentPosition.longitude,
        targetLat, targetLon,
      );
      distanceTarget = affKms(distance);
      bearingToTargetDble = Geolocator.bearingBetween(
        currentPosition.latitude, currentPosition.longitude,
        targetLat, targetLon,
      );
      bearingToTarget = '${bearingToTargetDble.toStringAsFixed(0)}°';
      angle = (bearingToTargetDble - headingDble).round();
      if (angle < -180) angle += 360;
      if (angle > 180) angle -= 360;
    }
    notifyListeners();
  }

  void reset() {
    isTracking = false;
    isAddingNote = false;
    isSimulatedFlight = false;
    trace.clear();
    notes.clear();
    pauses.clear();
    photos.clear();
    _pauseStartTime = null;
    _noteInCurrentPauseKey = null;
    travelledLength = "0 m";
    travelledLengthDble = 0.0;
    dureeInt = 0;
    walkingTime = 0;
    speed = "0.0 kmh";
    speedValue = 0.0;
    altitude = "0 m";
    startTime = '';
    distanceTarget = "0 m";
    bearingToTarget = "0°";
    bearingToTargetDble = 0.0;
    angle = 0;
    heading = "0°";
    headingDble = 0.0;
    _simulationData.clear();
    _activeTarget = null;
    _currentWaypointIndex = 0;
    nextHeadingMessage = null;
    _triggeredSegmentNotes.clear();
    notifyListeners();
  }

  String _formatStartTime(DateTime time) {
    final localTime = time.toLocal();
    return "${localTime.day.toString().padLeft(2, '0')}/${localTime.month.toString().padLeft(2, '0')}/${localTime.year} ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}";
  }

  void clearNextHeadingMessage() {
    nextHeadingMessage = null;
    notifyListeners();
  }
}
