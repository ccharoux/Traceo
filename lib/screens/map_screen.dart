import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../screens/stats_screen.dart';
import '../components/drawer.dart';
import '../components/map_controls.dart';
import '../components/map_type_dialog.dart';
import '../components/dialogs/choose_home_dialog.dart';
import '../components/routs.dart';
import '../models/handle_bounds.dart';
import '../models/location_service.dart';
import '../models/track_data.dart';
import '../models/permission_handler.dart';
import '../screens/tracks_screen.dart';
import '../models/home.dart';
import '../models/home_service.dart';
import '../models/premium_state.dart';
import '../models/settings_state.dart';
import '../components/heading_indicator.dart';

// OPENAIP key
const String _openAipApiKey = 'f8a70b741f6eee3412c75e23e4121ca1';

enum SimulationState { stopped, running, paused }

class MapScreen extends StatefulWidget {
  static const String id = '/';
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  String _version = "0.0.0";
  final Completer<GoogleMapController> _mapController = Completer();
  StreamSubscription<Position>? _positionStream;
  Timer? _simulationTimer;
  double _simulationSpeed = 1.0;
  double _currentZoom = 14.4746;
  DateTime? _lastProcessedTime;
  DateTime? _lastCameraUpdate;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  BitmapDescriptor? _currentPositionIcon;
  BitmapDescriptor? _airplaneIcon;
  BitmapDescriptor? _noteIcon;
  BitmapDescriptor? _pauseIcon;
  BitmapDescriptor? _photoIcon;
  bool _isLoading = true;


  bool _isSaving = false;
  SimulationState _simulationState = SimulationState.stopped;
  bool _isTopDownView = true;
  bool _didInit = false;

  int _simulationIndex = 0;
  String _actualTitle = ' ';

  Position? _currentPosition;

  // ÉTATS POUR LA PRÉPARATION DE VOL
  bool _isPreparingFlight = false;
  bool _isPlacingRouteNote = false;
  final List<LatLng> _routePoints = [];
  final List<String> _routePointNames = [];
  final List<Map<String, dynamic>> _routeSegmentNotes = [];
  
  // Historique pour l'annulation (Undo)
  final List<List<LatLng>> _pointsHistory = [];
  final List<List<String>> _namesHistory = [];
  final List<List<Map<String, dynamic>>> _notesHistory = [];

  // Fournisseur de tuiles avec cache robuste
  late final _OpenAIPTileProvider _oaciTileProvider;

  // État de la boussole temporaire
  bool _showCompassTemp = false;
  Timer? _compassTimer;

  final Position _defaultPosition = Position(
    latitude: 43.805072, longitude: 5.725026, timestamp: DateTime.now(),
    accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPosition = _defaultPosition;
    _loadVersion();
    _oaciTileProvider = _OpenAIPTileProvider(onQuotaExceeded: _handleQuotaExceeded);
  }

  void _handleQuotaExceeded() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ol('oaci_quota_exceeded')),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _loadVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = packageInfo.version);
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _initializeApp();
      _didInit = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStream?.cancel();
    _simulationTimer?.cancel();
    _compassTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _updateCurrentPosition();
    if (state == AppLifecycleState.detached && context.read<LocaData>().isTracking) _saveTrackSync();
  }

  Future<void> _updateCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 2));
        if (mounted) setState(() => _currentPosition = pos);
      }
    } catch (_) {}
  }

  Future<void> _initializeApp() async {
    final trackData = context.read<TrackData>();
    final locaData = context.read<LocaData>();
    await trackData.createAppFolder();
    await _loadCustomIcons();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      Position? pos;
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 2), onTimeout: () async => (await Geolocator.getLastKnownPosition()) ?? _defaultPosition);
      } else {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos != null) _currentPosition = pos;
    } catch (_) {}

    if (!mounted) return;
    locaData.resetTarget(); 

    setState(() { _isLoading = false; _actualTitle = ' '; });
    if (_currentPosition != null && _currentPosition != _defaultPosition) {
      _mapController.future.then((controller) {
        if (mounted) {
          controller.animateCamera(CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude)));
        }
      });
    }
  }

  Future<void> _loadCustomIcons() async {
    try {
      _currentPositionIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(32, 32)), 'assets/fleche.png');
      _airplaneIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(48, 48)), 'assets/avion.png');
      _noteIcon = await _createCustomMarker(Icons.note_alt, Colors.orange);
      _pauseIcon = await _createCustomMarker(Icons.pause, Colors.blue);
      _photoIcon = await _createCustomMarker(Icons.camera_alt, Colors.purple);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _resetAllActivities() {
    _positionStream?.cancel();
    _simulationTimer?.cancel();
    _positionStream = null;
    _simulationTimer = null;
    _lastProcessedTime = null;
    if (!mounted) return;
    context.read<LocaData>().reset();
    setState(() { 
      _simulationState = SimulationState.stopped; 
      _simulationIndex = 0; 
      _simulationSpeed = 1.0; 
      _actualTitle = ' '; 
      _polylines.clear(); 
      _markers.clear(); 
      _isPreparingFlight = false;
      _isPlacingRouteNote = false;
      _pointsHistory.clear();
      _namesHistory.clear();
      _notesHistory.clear();
    });
  }

  // --- LOGIQUE PRÉPARATION DE VOL ---

  void _saveToHistory() {
    _pointsHistory.add(List.from(_routePoints));
    _namesHistory.add(List.from(_routePointNames));
    _notesHistory.add(List.from(_routeSegmentNotes.map((n) => Map<String, dynamic>.from(n))));
    if (_pointsHistory.length > 20) {
      _pointsHistory.removeAt(0);
      _namesHistory.removeAt(0);
      _notesHistory.removeAt(0);
    }
  }

  void _undoRouteAction() {
    if (_pointsHistory.isNotEmpty) {
      setState(() {
        _routePoints.clear();
        _routePoints.addAll(_pointsHistory.removeLast());
        _routePointNames.clear();
        _routePointNames.addAll(_namesHistory.removeLast());
        _routeSegmentNotes.clear();
        _routeSegmentNotes.addAll(_notesHistory.removeLast());
        _updateRouteGraphics();
      });
    }
  }

  void _togglePrepareFlight() async {
    final locaData = context.read<LocaData>();
    final homeService = context.read<HomeService>();

    final Home? chosen = await showDialog<Home>(
      context: context,
      builder: (BuildContext dialogContext) {
        return ChooseHomeDialog(
          homes: homeService.homes,
          title: ol('flight_preparation'),
          subtitle: ol('choose_destination'),
          onlyAerodromes: true,
          onDelete: (Home home) async {
            final n = Navigator.of(dialogContext);
            await homeService.deleteHome(home.name);
            n.pop();
            _togglePrepareFlight();
          },
        );
      },
    );

    if (chosen == null || !mounted) return;

    locaData.updateActiveTarget(chosen, _currentPosition ?? _defaultPosition);
    _addOrUpdateHomeMarker(chosen);

    setState(() {
      _isPreparingFlight = true;
      _isPlacingRouteNote = false;
      _actualTitle = "${ol('flight_preparation_short')} ${chosen.name}";
      _routePoints.clear();
      _routePointNames.clear();
      _routeSegmentNotes.clear();
      _pointsHistory.clear();
      _namesHistory.clear();
      _notesHistory.clear();
      
      if (chosen.isRoute && chosen.routePoints != null) {
        for (var pt in chosen.routePoints!) {
          _routePoints.add(LatLng(pt['lat'], pt['lon']));
          _routePointNames.add(pt['name'] ?? '');
        }
        if (chosen.segmentNotes != null) {
          _routeSegmentNotes.addAll(chosen.segmentNotes!);
        }
      } else {
        if (_currentPosition != null) {
          _routePoints.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
          _routePointNames.add(ol('departure_point'));
        }
        _routePoints.add(LatLng(chosen.latitude, chosen.longitude));
        _routePointNames.add(chosen.name);
      }
      _updateRouteGraphics();
    });
  }

  double _getProjectionRatio(LatLng p, LatLng a, LatLng b) {
    final double x = p.longitude - a.longitude;
    final double y = p.latitude - a.latitude;
    final double dx = b.longitude - a.longitude;
    final double dy = b.latitude - a.latitude;
    final double dot = x * dx + y * dy;
    final double lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return 0;
    return (dot / lenSq).clamp(0.0, 1.0);
  }

  LatLng _interpolate(LatLng a, LatLng b, double ratio) {
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * ratio,
      a.longitude + (b.longitude - a.longitude) * ratio,
    );
  }

  void _onMapTap(LatLng point) async {
    if (!_isPreparingFlight) return;

    if (_isPlacingRouteNote) {
      int? segIdx;
      double? segRatio;
      double minSegDist = double.infinity;

      for (int i = 0; i < _routePoints.length - 1; i++) {
        final a = _routePoints[i];
        final b = _routePoints[i + 1];
        final ratio = _getProjectionRatio(point, a, b);
        final projected = _interpolate(a, b, ratio);
        final dist = Geolocator.distanceBetween(point.latitude, point.longitude, projected.latitude, projected.longitude);
        
        if (dist < minSegDist) {
          minSegDist = dist;
          segIdx = i;
          segRatio = ratio;
        }
      }

      if (segIdx != null && minSegDist < 1000) { 
         final String? note = await _asyncInputDialog(context, ol('route_note'), ol('enter_segment_note'));
         if (note != null && note.isNotEmpty) {
           _saveToHistory();
           setState(() {
             _routeSegmentNotes.add({
               'text': note,
               'segmentIndex': segIdx,
               'ratio': segRatio
             });
             _isPlacingRouteNote = false;
             _updateRouteGraphics();
           });
         }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ol('tap_segment_to_add_note'))));
      }
      return;
    }

    final String? name = await _asyncInputDialog(context, ol('nav_point'), ol('name_this_point'));
    if (name == null || name.isEmpty) return;
    _saveToHistory();
    setState(() {
      int index = _routePoints.length - 1;
      _routePoints.insert(index, point);
      _routePointNames.insert(index, name);
      _updateRouteGraphics();
    });
  }

  void _editWaypoint(int index) async {
    final nameController = TextEditingController(text: _routePointNames[index]);
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ol('edit_point')),
        content: TextField(controller: nameController, decoration: InputDecoration(labelText: ol('name'))),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _confirmDeleteWaypoint(index); }, child: Text(ol('delete'), style: const TextStyle(color: Colors.red))),
          const Spacer(),
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(ol('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(ol('ok'))),
        ],
      ),
    );
    if (result == true) {
      _saveToHistory();
      setState(() { _routePointNames[index] = nameController.text; _updateRouteGraphics(); });
    }
  }

  void _confirmDeleteWaypoint(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ol('delete_point_q')),
        content: Text(ol('remove_point_from_route').replaceAll('%s', _routePointNames[index])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(ol('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(ol('delete'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      _saveToHistory();
      setState(() {
        _routePoints.removeAt(index);
        _routePointNames.removeAt(index);
        _routeSegmentNotes.removeWhere((n) => n['segmentIndex'] >= _routePoints.length - 1);
        _updateRouteGraphics();
      });
    }
  }

  void _editSegmentNote(int noteIndex) async {
    final noteCtrl = TextEditingController(text: _routeSegmentNotes[noteIndex]['text']);
    final bool? res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ol('segment_note')),
        content: TextField(controller: noteCtrl, maxLines: 3),
        actions: [
          TextButton(onPressed: () { _saveToHistory(); setState(() { _routeSegmentNotes.removeAt(noteIndex); _updateRouteGraphics(); }); Navigator.pop(context); }, child: Text(ol('delete'), style: const TextStyle(color: Colors.red))),
          const Spacer(),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(ol('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(ol('ok'))),
        ],
      ),
    );
    if (res == true) { _saveToHistory(); setState(() { _routeSegmentNotes[noteIndex]['text'] = noteCtrl.text; _updateRouteGraphics(); }); }
  }

  void _updateRouteGraphics() {
    _polylines.removeWhere((p) => p.polylineId.value == 'flight_plan');
    _polylines.add(Polyline(
      polylineId: const PolylineId('flight_plan'),
      points: List.from(_routePoints),
      color: Colors.blueAccent,
      width: 4,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    ));
    _markers.removeWhere((m) => m.markerId.value.startsWith('route_pt_') || m.markerId.value.startsWith('seg_note_'));
    for (int i = 0; i < _routePoints.length; i++) {
      _markers.add(Marker(
        markerId: MarkerId('route_pt_$i'), position: _routePoints[i], draggable: true,
        onDragStart: (_) => _saveToHistory(),
        onDragEnd: (newPosition) { setState(() { _routePoints[i] = newPosition; _updateRouteGraphics(); }); },
        onTap: () => _editWaypoint(i),
        infoWindow: InfoWindow(title: _routePointNames[i]),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }
    for (int i = 0; i < _routeSegmentNotes.length; i++) {
      final note = _routeSegmentNotes[i];
      final int sIdx = note['segmentIndex'];
      if (sIdx >= _routePoints.length - 1) continue;
      final pos = _interpolate(_routePoints[sIdx], _routePoints[sIdx + 1], note['ratio']);
      _markers.add(Marker(
        markerId: MarkerId('seg_note_$i'), position: pos,
        icon: _noteIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        onTap: () => _editSegmentNote(i),
        infoWindow: InfoWindow(title: note['text']),
      ));
    }
  }

  Future<void> _saveFlightPlan() async {
    final locaData = context.read<LocaData>();
    final homeService = context.read<HomeService>();
    if (locaData.activeTarget == null) return;
    final targetHome = locaData.activeTarget!;
    List<Map<String, dynamic>> pts = [];
    for (int i = 0; i < _routePoints.length; i++) { pts.add({ 'lat': _routePoints[i].latitude, 'lon': _routePoints[i].longitude, 'name': _routePointNames[i] }); }
    await homeService.updateHome(targetHome.copyWith(
      isRoute: true, routePoints: pts, segmentNotes: List<Map<String, dynamic>>.from(_routeSegmentNotes)
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ol('route_saved_msg').replaceAll('%s', targetHome.name))));
      _resetAllActivities();
      _togglePrepareFlight();
    }
  }

  Future<void> _startTracking() async {
    final locaData = context.read<LocaData>();
    final messenger = ScaffoldMessenger.of(context);
    if (!await PermissionHelper.handleTrackingPermissions(context)) return; 
    if (!mounted) return;
    final activeTarget = locaData.activeTarget;
    _resetAllActivities();
    locaData.startTracking();
    if (activeTarget != null) { locaData.updateActiveTarget(activeTarget, _currentPosition ?? _defaultPosition); _addOrUpdateHomeMarker(activeTarget); }
    final locationSettings = Platform.isAndroid ? AndroidSettings( accuracy: LocationAccuracy.high, distanceFilter: 0, intervalDuration: const Duration(seconds:3), foregroundNotificationConfig: ForegroundNotificationConfig( notificationTitle: ol('foreground_notification_title'), notificationText: ol('foreground_notification_text'), enableWakeLock: true, setOngoing: true )) : AppleSettings( accuracy: LocationAccuracy.high, distanceFilter: 0, showBackgroundLocationIndicator: true, activityType: ActivityType.fitness );
    if (mounted) setState(() => _actualTitle = ol('tracking'));
    messenger.showSnackBar(SnackBar(content: Text(ol('acquiring_gps'))));
    try {
      final startPosition = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 5), onTimeout: () async => (await Geolocator.getLastKnownPosition()) ?? _defaultPosition);
      if (!mounted) return;
      await _resetMapState(null, startPosition);
      setState(() { _currentPosition = startPosition; _lastProcessedTime = startPosition.timestamp; });
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position p) => _processNewPosition(p), onError: (e) { if(mounted) messenger.showSnackBar(SnackBar(content: Text("${ol('tracking_error')}: $e"))); _resetAllActivities(); });
    } catch (e) { if (mounted) messenger.showSnackBar(SnackBar(content: Text(ol('gps_error_start')))); _resetAllActivities(); }
  }

  Future<void> _stopTracking() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try { await _saveTrack(); } catch (e) { debugPrint("Error saving track: $e"); }
    finally { if (mounted) { _resetAllActivities(); setState(() => _isSaving = false); } }
  }

  Future<void> _startSimulation(String trackName, {bool archived = false}) async {
    _positionStream?.cancel();
    _simulationTimer?.cancel();
    _positionStream = null;
    _simulationTimer = null;
    _lastProcessedTime = null;

    final locaData = context.read<LocaData>();
    locaData.reset();

    final trackData = context.read<TrackData>();
    final messenger = ScaffoldMessenger.of(context);
    final String basePath = archived ? trackData.archivePath : trackData.trackPath;
    final file = File(p.join(basePath, '$trackName.txt'));
    debugPrint("START SIMULATION: path = ${file.path}, exists = ${await file.exists()}");
    if (!await file.exists()) {
      debugPrint("TRACK FILE DOES NOT EXIST: ${file.path}");
      if (mounted) messenger.showSnackBar(SnackBar(content: Text("File not found: $trackName")));
      return;
    }
    final lines = await file.readAsLines();
    debugPrint("TRACK FILE READ: lines count = ${lines.length}");
    if (!mounted) return;
    
    bool isFlight = lines.any((l) => l.toLowerCase().contains("isflight:true"));
    
    final List<Position> simulatedPositions = [];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split(' ');
      if (parts.length >= 4) {
        final lat = double.tryParse(parts[0]);
        final lon = double.tryParse(parts[1]);
        final alt = double.tryParse(parts[2]);
        final time = DateTime.tryParse(parts[3]);
        if (lat != null && lon != null && alt != null && time != null) {
          double speed = 0;
          if (simulatedPositions.isNotEmpty) {
            final last = simulatedPositions.last;
            final dist = Geolocator.distanceBetween(last.latitude, last.longitude, lat, lon);
            final diff = time.difference(last.timestamp).inSeconds;
            if (diff > 0) speed = dist / diff;
          }
          final String key = time.toLocal().toIso8601String().split('.')[0];
          simulatedPositions.add(Position(latitude: lat, longitude: lon, altitude: alt, timestamp: time, accuracy: 1, altitudeAccuracy: 1, heading: 0, headingAccuracy: 1, speed: speed, speedAccuracy: 1));
          String? noteContent, photoVignette; int? pauseDuration;
          for (var part in parts.sublist(4)) { if (part.startsWith("pause:")) { pauseDuration = int.tryParse(part.substring(6)); } else if (part.startsWith("vignette:")) { photoVignette = part.substring(9); } else { noteContent = (noteContent == null) ? Uri.decodeComponent(part) : "$noteContent ${Uri.decodeComponent(part)}"; } }
          if (pauseDuration != null) locaData.pauses[key] = pauseDuration;
          if (photoVignette != null) locaData.photos[key] = photoVignette;
          if (noteContent != null && noteContent.isNotEmpty) locaData.notes[key] = noteContent;
        }
      }
    }
    debugPrint("PARSED simulatedPositions count = ${simulatedPositions.length}");
    if (simulatedPositions.isEmpty) {
      debugPrint("SIMULATION POSITIONS EMPTY!");
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(ol('no_simulation_data'))));
      return;
    }
    
    locaData.setSimulationData(simulatedPositions, isFlight: isFlight);
    if (locaData.activeTarget == null) {
      locaData.updateActiveTarget(Home(name: ol('start_point'), latitude: simulatedPositions.first.latitude, longitude: simulatedPositions.first.longitude), simulatedPositions.first);
    }

    setState(() {
      _polylines.clear();
      _markers.clear();
      _simulationIndex = 0;
      _simulationSpeed = 1.0;
      _simulationState = SimulationState.running;
      _currentPosition = simulatedPositions.first;
      _actualTitle = ol('start_simulation');
    });

    if (locaData.activeTarget != null) {
      _addOrUpdateHomeMarker(locaData.activeTarget!);
    }

    _startSimulationTimer();
  }

  void _resumeSimulation() {
    final locaData = context.read<LocaData>();
    if (locaData.isTracking || _simulationState == SimulationState.running) return;
    if (locaData.simulationData.isEmpty) { _resetAllActivities(); return; }
    setState(() { _simulationState = SimulationState.running; _actualTitle = ol('start_simulation'); });
    _startSimulationTimer();
  }

  void _startSimulationTimer() {
    _simulationTimer?.cancel();
    final locaData = context.read<LocaData>();
    debugPrint("START SIMULATION TIMER: simulationData length = ${locaData.simulationData.length}, speed = $_simulationSpeed");
    _simulationTimer = Timer.periodic(Duration(milliseconds: (1000 / _simulationSpeed).round()), (timer) {
      if (_simulationIndex >= locaData.simulationData.length) {
        debugPrint("SIMULATION ENDED naturally at index $_simulationIndex");
        _stopSimulation(naturalEnd: true);
        return;
      }
      final currentSimulatedPosition = locaData.simulationData[_simulationIndex];
      debugPrint("SIMULATION TICK: index=$_simulationIndex, pos=${currentSimulatedPosition.latitude},${currentSimulatedPosition.longitude}");
      _processNewPosition(currentSimulatedPosition);
      final String key = currentSimulatedPosition.timestamp.toLocal().toIso8601String().split('.')[0];
      final bool hasNote = locaData.notes.containsKey(key), hasPhoto = locaData.photos.containsKey(key);
      final int? pDuration = locaData.pauses[key];
      if (pDuration != null && pDuration >= 600 && !hasNote && !hasPhoto) _addPauseMarker(currentSimulatedPosition, pDuration);
      if (hasNote || hasPhoto) _addNoteMarker(currentSimulatedPosition, locaData.notes[key] ?? '', pauseDuration: pDuration, photoVignette: locaData.photos[key]);
      _simulationIndex++;
    });
  }

  void _pauseSimulation() { if (_simulationState != SimulationState.running) return; _simulationTimer?.cancel(); setState(() { _simulationState = SimulationState.paused; _actualTitle = ol('pause'); }); }
  void _stopSimulation({bool naturalEnd = false}) { if (!naturalEnd && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ol('simulation_stopped')))); _resetAllActivities(); }

  void _processNewPosition(Position position) {
    if (Platform.isIOS && _simulationState == SimulationState.stopped) { if (_lastProcessedTime != null && position.timestamp.difference(_lastProcessedTime!).inSeconds < 3) return; _lastProcessedTime = position.timestamp; }
    final locaData = context.read<LocaData>();
    if (_simulationState != SimulationState.stopped) {
      locaData.updateSimulationPosition(position);
    } else {
      if (!locaData.updatePosition(position)) return;
    }
    double newHeading = (locaData.trace.length > 1) ? Geolocator.bearingBetween(locaData.trace[locaData.trace.length-2].latitude, locaData.trace[locaData.trace.length-2].longitude, position.latitude, position.longitude) : position.heading;
    final posWithHeading = Position.fromMap({...position.toJson(), 'heading': newHeading});
    if (mounted) {
      setState(() {
        _currentPosition = posWithHeading;
        _updateLivePolyline(locaData.trace.map((p) => LatLng(p.latitude, p.longitude)).toList());
        _updateCurrentPositionMarker();
        _updateDestinationLine();
      });
      final now = DateTime.now();
      if (_lastCameraUpdate == null || now.difference(_lastCameraUpdate!).inMilliseconds > (_simulationSpeed > 1 ? 500 : 200)) {
        _lastCameraUpdate = now;
        _animateCameraToPosition(posWithHeading);
      }
    }
  }

  void _updateLivePolyline(List<LatLng> points) { _polylines.removeWhere((p) => p.polylineId.value == 'live'); _polylines.add(Polyline(polylineId: const PolylineId('live'), points: points, color: Colors.blue, width: 5)); }
  void _updateDestinationLine() {
    final locaData = context.read<LocaData>();
    final settings = context.read<SettingsState>();
    _polylines.removeWhere((p) => p.polylineId.value == 'to_destination');
    if (settings.showDestinationLine && locaData.activeTarget != null && _currentPosition != null && (locaData.isTracking || _simulationState != SimulationState.stopped)) {
      double targetLat = locaData.activeTarget!.latitude, targetLon = locaData.activeTarget!.longitude;
      if (locaData.activeTarget!.isRoute && locaData.activeTarget!.routePoints != null && locaData.currentWaypointIndex < locaData.activeTarget!.routePoints!.length) { targetLat = locaData.activeTarget!.routePoints![locaData.currentWaypointIndex]['lat']; targetLon = locaData.activeTarget!.routePoints![locaData.currentWaypointIndex]['lon']; }
      _polylines.add(Polyline(
        polylineId: const PolylineId('to_destination'), 
        points: [LatLng(_currentPosition!.latitude, _currentPosition!.longitude), LatLng(targetLat, targetLon)], 
        color: Colors.red.withValues(alpha: 0.9), 
        width: 2, 
        patterns: [PatternItem.dash(20), PatternItem.gap(10)]
      ));
    }
  }

  void _updateCurrentPositionMarker() { if (_currentPosition == null) return; final locaData = context.read<LocaData>(); final icon = (locaData.activeTarget?.isAerodrome == true || locaData.isSimulatedFlight) ? _airplaneIcon : _currentPositionIcon; _markers.removeWhere((m) => m.markerId.value == 'currentPos'); _markers.add(Marker(markerId: const MarkerId('currentPos'), position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), icon: icon ?? BitmapDescriptor.defaultMarker, rotation: _currentPosition!.heading, anchor: const Offset(0.5, 0.5), flat: true, zIndexInt: 2)); }
  Future<void> _animateCameraToPosition(Position position) async { (await _mapController.future).animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: _currentZoom, bearing: _isTopDownView ? 0 : position.heading))); }

  void _showCacheInfo() async { 
    final info = await _OpenAIPTileProvider.getCacheInfo(); 
    if (!mounted) return; 
    showDialog( context: context, builder: (context) => AlertDialog( title: Text(ol('oaci_cache')), content: Column( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ Text("${ol('tiles_count')} ${info['count']}"), Text("${ol('cache_size')} ${info['size'].toStringAsFixed(2)} Mo"), ], ), actions: [ 
      TextButton( onPressed: () async { 
        final settings = context.read<SettingsState>();
        final success = await settings.exportOaciCache();
        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ol('export_success'))));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ol('error_exporting_cache'))));
          }
        }
      }, child: Text(ol('export_cache'))),
      TextButton( onPressed: () async { 
        final settings = context.read<SettingsState>();
        final success = await settings.importOaciCache();
        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ol('import_success'))));
            Navigator.of(context).pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ol('error_importing_cache'))));
          }
        }
      }, child: Text(ol('import_cache'))),
      TextButton( onPressed: () async { await _OpenAIPTileProvider.clearCache(); if (context.mounted) { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ol('cache_cleared')))); } }, child: Text(ol('clear_cache'), style: const TextStyle(color: Colors.red)), ), 
      TextButton( onPressed: () => Navigator.of(context).pop(), child: Text(ol('ok')), ), 
    ], ), ); 
  }
  void _showFullImageDialog(Uint8List bytes) { showDialog( context: context, builder: (context) => Dialog( backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(10), child: Stack( alignment: Alignment.center, children: [ GestureDetector( onTap: () => Navigator.of(context).pop(), child: InteractiveViewer( minScale: 0.5, maxScale: 4.0, child: Image.memory(bytes, fit: BoxFit.contain), ), ), Positioned( top: 10, right: 10, child: IconButton( icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.of(context).pop(), ), ), ], ), ), ); }
  void _showNoteEditDialog(Position pos, String curN, int? pD, String? pV) { 
    final isSim = _simulationState != SimulationState.stopped; final ld = context.read<LocaData>(); final messenger = ScaffoldMessenger.of(context); final String key = pos.timestamp.toLocal().toIso8601String().split('.')[0]; final pDurationEff = pD ?? ld.pauses[key] ?? ld.getPauseDuration(pos.timestamp); final noteCtrl = TextEditingController(text: ld.notes[key] ?? curN); 
    showDialog(context: context, barrierDismissible: false, builder: (BuildContext dc) { 
      Uint8List? vB; if (pV != null) vB = base64Decode(pV); 
      return AlertDialog( scrollable: true, title: Text(vB != null ? ol('photo') : ol('note')), content: Column(mainAxisSize: MainAxisSize.min, children: [ if (vB != null) Padding( padding: const EdgeInsets.only(bottom: 10.0), child: SizedBox( width: 250, height: 250, child: GestureDetector( onTap: () => _showFullImageDialog(vB!), child: Stack( alignment: Alignment.center, children: [ ClipRRect( borderRadius: BorderRadius.circular(8), child: Image.memory(vB, height: 250, width: 250, fit: BoxFit.contain), ), Positioned( bottom: 8, right: 8, child: Container( padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.zoom_in, color: Colors.white, size: 24), ), ), ], ), ), ), ), TextField(controller: noteCtrl, autofocus: !isSim && vB == null, readOnly: isSim, maxLines: null, keyboardType: TextInputType.multiline, decoration: InputDecoration(hintText: ol('note_hint'), border: isSim ? InputBorder.none : const UnderlineInputBorder())), const SizedBox(height: 20) ]), actions: <Widget>[Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [if (!isSim) TextButton(onPressed: () async { final n = Navigator.of(dc); ld.removeNoteAndPhotoAtPosition(pos.timestamp); if (ld.isTracking) { try { _saveTrack(); } catch(_) {} } if (mounted) { setState(() { _markers.removeWhere((m) => m.markerId.value == 'note_$key' || m.markerId.value == 'photo_$key'); }); n.pop(); } }, child: Text(ol('delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))), TextButton(child: Text(ol('ok'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), onPressed: () async { final n = Navigator.of(dc); if (!isSim) { ld.notes[key] = noteCtrl.text; if (ld.isTracking) { _saveTrack().catchError((_){}); } if (mounted) { _addNoteMarker(pos, noteCtrl.text, pauseDuration: pDurationEff, photoVignette: pV); messenger.showSnackBar(SnackBar(content: Text(ol('note_added')))); } } n.pop(); })])]); 
    }); 
  }

  void _addNoteMarker(Position pos, String note, {int? pauseDuration, String? photoVignette}) {
    final icon = photoVignette != null ? _photoIcon : _noteIcon;
    if (icon == null) return;
    final String key = pos.timestamp.toLocal().toIso8601String().split('.')[0];
    setState(() {
      _markers.removeWhere((m) {
        if (m.markerId.value.startsWith('pause_')) {
          double d = Geolocator.distanceBetween(pos.latitude, pos.longitude, m.position.latitude, m.position.longitude);
          return d < 25.0 || m.markerId.value == 'pause_$key';
        }
        return false;
      });
      _markers.add(Marker(
        markerId: MarkerId('${photoVignette != null ? "photo" : "note"}_$key'),
        position: LatLng(pos.latitude, pos.longitude),
        icon: icon,
        onTap: () => _showNoteEditDialog(pos, note, pauseDuration, photoVignette)
      ));
    });
  }
  void _addPauseMarker(Position pos, int dur) { if (_pauseIcon == null) return; final String key = pos.timestamp.toLocal().toIso8601String().split('.')[0]; if (_markers.any((m) { if (m.markerId.value.startsWith('note_') || m.markerId.value.startsWith('photo_')) { double d = Geolocator.distanceBetween(pos.latitude, pos.longitude, m.position.latitude, m.position.longitude); return d < 25.0; } return false; })) return; final int m = dur ~/ 60, s = dur % 60; setState(() { _markers.add(Marker(markerId: MarkerId('pause_$key'), position: LatLng(pos.latitude, pos.longitude), icon: _pauseIcon!, infoWindow: InfoWindow(title: ol('stop'), snippet: '${m.toString().padLeft(2, '0')}m${s.toString().padLeft(2, '0')}s'))); }); }
  Future<BitmapDescriptor> _createCustomMarker(IconData iconData, Color color) async { final ui.PictureRecorder pictureRecorder = ui.PictureRecorder(); final Canvas canvas = Canvas(pictureRecorder); const double size = 45.0, radius = size / 2; canvas.drawCircle(const Offset(radius, radius + 1), radius - 2, Paint()..color = Colors.black.withValues(alpha: 50/255)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)); canvas.drawCircle(const Offset(radius, radius), radius - 2, Paint()..color = Colors.white); canvas.drawCircle(const Offset(radius, radius), radius - 4, Paint()..color = color); final TextPainter textPainter = TextPainter(textDirection: ui.TextDirection.ltr)..text = TextSpan(text: String.fromCharCode(iconData.codePoint), style: TextStyle(fontSize: size * 0.5, fontFamily: iconData.fontFamily, package: iconData.fontPackage, color: Colors.white)); textPainter.layout(); textPainter.paint(canvas, Offset(radius - textPainter.width / 2, radius - textPainter.height / 2)); final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt()); final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png); if (byteData == null) return BitmapDescriptor.defaultMarker; return BitmapDescriptor.bytes(byteData.buffer.asUint8List()); }
  void _handleNamePosition() async { final n = Navigator.of(context); final hs = context.read<HomeService>(); n.pop(); final homeName = await _asyncInputDialog(context, ol('name_current_position'), ol('enter_destination_name_hint')); if (homeName == null || homeName.isEmpty || _currentPosition == null) return; await hs.addHome(Home(name: homeName, latitude: _currentPosition!.latitude, longitude: _currentPosition!.longitude)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$homeName' ${ol('home_saved')}"))); }
  Future<String?> _asyncInputDialog(BuildContext context, String title, String hint) async { final n = Navigator.of(context); String textValue = ''; return showDialog<String>(context: context, builder: (BuildContext context) => AlertDialog(title: Text(title), content: TextField(autofocus: true, onChanged: (value) => textValue = value, decoration: InputDecoration(hintText: hint)), actions: <Widget>[TextButton(child: Text(ol('cancel')), onPressed: () => n.pop()), TextButton(child: Text(ol('ok')), onPressed: () => n.pop(textValue))])); }
  void _handleChangeDestination() async { final n = Navigator.of(context); final ld = context.read<LocaData>(); final hs = context.read<HomeService>(); n.pop(); final Home? newTarget = await showDialog<Home>(context: context, builder: (BuildContext context) => ChooseHomeDialog(homes: hs.homes, subtitle: ol('choose_destination'), onDelete: (Home home) async { final n2 = Navigator.of(context); await hs.deleteHome(home.name); n2.pop(); _handleChangeDestination(); })); if (newTarget != null) { if (!ld.isTracking) await hs.saveChosenHome(newTarget); if (!mounted) return; ld.updateActiveTarget(newTarget, _currentPosition ?? _defaultPosition); _addOrUpdateHomeMarker(newTarget); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${ol('destination_set')}${newTarget.name}"))); } }
  void _addOrUpdateHomeMarker(Home home) { setState(() { _markers.removeWhere((m) => m.markerId.value == 'home'); _markers.add(Marker(markerId: const MarkerId('home'), position: LatLng(home.latitude, home.longitude), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), infoWindow: InfoWindow(title: home.name))); }); }
  Future<void> _saveTrack() async {
    final ld = context.read<LocaData>();
    final td = context.read<TrackData>();
    if (ld.trace.length < 2) return;
    final tn = await formatTrackName(ld.trace.first.timestamp.toLocal());
    await td.writeTrack(tn, await makeTrack(ld, tn)); }
  void _saveTrackSync() { final ld = context.read<LocaData>(); if (ld.trace.length < 2) return; final tn = DateFormat("d MMMM yyyy HH'h'mm", 'fr_FR').format(ld.trace.first.timestamp.toLocal()); context.read<TrackData>().writeTrackSync(tn, makeTrackSync(ld: ld, tn: tn)); }
  String makeTrackSync({required LocaData ld, required String tn}) { final d = ld.travelledLengthDble / 1000.0, b = HandleBounds.fromPoints(ld.trace.map((p) => LatLng(p.latitude, p.longitude)).toList()); final df = DateFormat("d MMMM yyyy HH'h'mm", 'fr_FR'); final isFlight = ld.activeTarget?.isAerodrome == true; final StringBuffer buffer = StringBuffer(); buffer.writeln(tn); buffer.writeln('${b.southwest.latitude} ${b.southwest.longitude} ${b.northeast.latitude} ${b.northeast.longitude}'); buffer.writeln(df.format(ld.trace.first.timestamp.toLocal())); buffer.writeln(df.format(ld.trace.last.timestamp.toLocal())); buffer.writeln('${ld.dureeInt ?? 0}'); buffer.writeln('${ld.walkingTime}'); buffer.writeln('$d'); buffer.writeln('isFlight:$isFlight'); for (var p in ld.trace) { final String k = p.timestamp.toLocal().toIso8601String().split('.')[0]; buffer.write('${p.latitude.toStringAsFixed(6)} ${p.longitude.toStringAsFixed(6)} ${p.altitude.toInt()} $k'); if (ld.notes.containsKey(k)) buffer.write(' ${Uri.encodeComponent(ld.notes[k]!)}'); if (ld.photos.containsKey(k)) buffer.write(' vignette:${ld.photos[k]}'); if (ld.pauses.containsKey(k)) buffer.write(' pause:${ld.pauses[k]}'); buffer.writeln(); } return buffer.toString(); }
  Future<String> makeTrack(LocaData ld, String tn) async {
    final d = ld.travelledLengthDble / 1000.0,
        b = HandleBounds.fromPoints(ld.trace.map((p) => LatLng(p.latitude, p.longitude)).toList()); final df = DateFormat("d MMMM yyyy HH'h'mm", 'fr_FR'); final isFlight = ld.activeTarget?.isAerodrome == true; final StringBuffer buffer = StringBuffer(); buffer.writeln(tn); buffer.writeln('${b.southwest.latitude} ${b.southwest.longitude} ${b.northeast.latitude} ${b.northeast.longitude}'); buffer.writeln(df.format(ld.trace.first.timestamp.toLocal())); buffer.writeln(df.format(ld.trace.last.timestamp.toLocal())); buffer.writeln('${ld.dureeInt ?? 0}'); buffer.writeln('${ld.walkingTime}'); buffer.writeln('$d'); buffer.writeln('isFlight:$isFlight'); for (var p in ld.trace) { final String k = p.timestamp.toLocal().toIso8601String().split('.')[0]; buffer.write('${p.latitude.toStringAsFixed(6)} ${p.longitude.toStringAsFixed(6)} ${p.altitude.toInt()} $k'); if (ld.notes.containsKey(k)) buffer.write(' ${Uri.encodeComponent(ld.notes[k]!)}'); if (ld.photos.containsKey(k)) buffer.write(' vignette:${ld.photos[k]}'); if (ld.pauses.containsKey(k)) buffer.write(' pause:${ld.pauses[k]}'); buffer.writeln(); } return buffer.toString(); }
  Future<void> _resetMapState(String? trackName, Position startPosition) async {
    final ld = context.read<LocaData>();
    setState(() { _polylines.clear(); _markers.clear();
      if (ld.activeTarget == null) {
        ld.updateActiveTarget(Home(name: ol('start_point'),
            latitude: startPosition.latitude,
            longitude: startPosition.longitude), startPosition);
        _addOrUpdateHomeMarker(ld.activeTarget!); } }); }

  void _shareCurrentLocation() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ol('no_position_available'))),
      );
      return;
    }
    final String url = 'https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}';
    Share.share("${ol('here_is_my_location')}\n$url");
  }

  @override
  Widget build(BuildContext context) {
    final locaData = context.watch<LocaData>(); final trackData = context.watch<TrackData>(); final premiumState = context.watch<PremiumState>(); final settings = context.watch<SettingsState>();
    final bool canShowOACI = premiumState.isPremium && (
      (locaData.activeTarget != null && locaData.activeTarget!.isAerodrome && locaData.activeTarget!.name != ol('start_point')) || 
      locaData.isSimulatedFlight || 
      _isPreparingFlight
    );
    final Set<TileOverlay> tileOverlays = {}; if (canShowOACI) tileOverlays.add(TileOverlay(tileOverlayId: const TileOverlayId('aviation_layer_stable'), tileProvider: _oaciTileProvider, zIndex: 1));
    _updateDestinationLine();
    final Set<Marker> markersToShow = settings.showPauseMarkers ? _markers : _markers.where((m) => !m.markerId.value.startsWith('pause_')).toSet();

    double targetBearing = 0.0;
    if (locaData.activeTarget != null && _currentPosition != null) {
      double tLat = locaData.activeTarget!.latitude;
      double tLon = locaData.activeTarget!.longitude;
      if (locaData.activeTarget!.isRoute && locaData.activeTarget!.routePoints != null && locaData.currentWaypointIndex < locaData.activeTarget!.routePoints!.length) {
        tLat = locaData.activeTarget!.routePoints![locaData.currentWaypointIndex]['lat'];
        tLon = locaData.activeTarget!.routePoints![locaData.currentWaypointIndex]['lon'];
      }
      targetBearing = Geolocator.bearingBetween(_currentPosition!.latitude, _currentPosition!.longitude, tLat, tLon);
      if (targetBearing < 0) targetBearing += 360;
    }

    return Scaffold(
      appBar: _buildAppBar(locaData.isTracking, _simulationState != SimulationState.stopped, premiumState.isPremium),
      drawer: AppDrawer(version: _version, isTracking: locaData.isTracking, isSimulating: _simulationState == SimulationState.running, isMovingFast: locaData.speedValue > 80, activeTarget: locaData.activeTarget, onSimulate: _handleSimulate, onNamePosition: _handleNamePosition, onChangeDestination: _handleChangeDestination, onPrepareFlight: _togglePrepareFlight),
      body: Stack(children: [ 
        GoogleMap( mapType: trackData.mapType, initialCameraPosition: CameraPosition(target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), zoom: _currentZoom), onMapCreated: (GoogleMapController c) { if (!_mapController.isCompleted) _mapController.complete(c); }, onCameraMove: (CameraPosition p) => _currentZoom = p.zoom, myLocationEnabled: false, myLocationButtonEnabled: false, zoomControlsEnabled: false, polylines: _polylines, markers: markersToShow, tileOverlays: tileOverlays, onTap: _onMapTap, ), 
        if (_isLoading) Container(color: Colors.white, child: Center(child: Image.asset('assets/Promenade.png', width: 150))), 
        MapControls(onZoomIn: () async => (await _mapController.future).animateCamera(CameraUpdate.zoomIn()), onZoomOut: () async => (await _mapController.future).animateCamera(CameraUpdate.zoomOut()), onMyLocation: () => _currentPosition != null ? _animateCameraToPosition(_currentPosition!) : null, onToggleMapView: () { setState(() { _isTopDownView = !_isTopDownView; if (_isTopDownView) _currentZoom = 16.0; }); if (_currentPosition != null) _animateCameraToPosition(_currentPosition!); }, isTopDownView: _isTopDownView, isTracking: locaData.isTracking || _simulationState != SimulationState.stopped),
        if (_showCompassTemp && locaData.activeTarget != null && (locaData.isTracking || _simulationState != SimulationState.stopped)) 
          HeadingIndicator(bearingToTarget: targetBearing, currentHeading: _currentPosition?.heading ?? 0),
        if (locaData.nextHeadingMessage != null) _buildNextHeadingBubble(locaData), 
      ]),
      floatingActionButton: _isLoading ? null : FloatingActionButton(onPressed: _isSaving ? null : () async { if (_isPreparingFlight) { await _saveFlightPlan(); } else if (locaData.isTracking) { await _stopTracking(); } else if (_simulationState != SimulationState.stopped) { _stopSimulation(); } else { await _startTracking(); } }, backgroundColor: _isPreparingFlight ? Colors.blue : (locaData.isTracking ? Colors.red : (_simulationState != SimulationState.stopped) ? Colors.orange : Colors.green), child: _isSaving ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)) : Icon(_isPreparingFlight ? Icons.save : (locaData.isTracking || _simulationState != SimulationState.stopped ? Icons.stop : Icons.play_arrow), color: Colors.white)),
      bottomNavigationBar: BottomAppBar(child: Container(height: 50.0, padding: const EdgeInsets.symmetric(horizontal: 16.0), alignment: Alignment.center, child: Consumer<LocaData>(builder: (context, ld, child) { if (ld.isTracking) return _buildTrackingBanner(ld, settings); if (_simulationState != SimulationState.stopped) return _buildSimulationBanner(ld, settings); return _isPreparingFlight ? _buildPreparationBanner() : Text(ol('start_tracking_prompt'), style: const TextStyle(fontWeight: FontWeight.bold)); }))),
    );
  }

  Widget _buildPreparationBanner() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(_isPlacingRouteNote ? Icons.cancel : Icons.note_add, color: _isPlacingRouteNote ? Colors.red : Colors.blue),
          onPressed: () => setState(() => _isPlacingRouteNote = !_isPlacingRouteNote),
          tooltip: ol('add_route_note'),
        ),
        Expanded(
          child: Text(
            _isPlacingRouteNote ? ol('tap_segment_to_add_note') : ol('drag_points_instruction'),
            style: TextStyle(fontWeight: FontWeight.bold, color: _isPlacingRouteNote ? Colors.blue : Colors.black),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.blue, size: 28),
          onPressed: () => _showPreparationHelp(),
          tooltip: ol('help'),
        ),
      ],
    );
  }

  void _showPreparationHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Colors.blue),
            const SizedBox(width: 10),
            Text(ol('prep_help_title')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHelpItem(Icons.touch_app, ol('help_prep_1')),
            _buildHelpItem(Icons.back_hand, ol('help_prep_2')),
            _buildHelpItem(Icons.edit_location, ol('help_prep_3')),
            _buildHelpItem(Icons.note_add, ol('help_prep_4')),
            _buildHelpItem(Icons.save, ol('help_prep_5')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ol('ok'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildNextHeadingBubble(LocaData ld) { return Positioned( top: 100, left: 20, right: 20, child: GestureDetector( onTap: () => ld.clearNextHeadingMessage(), child: Container( padding: const EdgeInsets.all(16), decoration: BoxDecoration( color: Colors.blue.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)], ), child: Column( children: [ Text(ld.nextHeadingMessage!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center), const SizedBox(height: 8), Text(ol('press_to_close'), style: const TextStyle(color: Colors.white70, fontSize: 12)), ], ), ), ), ); }

  AppBar _buildAppBar(bool isTracking, bool isSimulatingOrPaused, bool isPremium) {
    return AppBar(
      leading: _isPreparingFlight ? IconButton( icon: const Icon(Icons.arrow_back), onPressed: () { _resetAllActivities(); _togglePrepareFlight(); }, ) : null,
      title: Text(_actualTitle), backgroundColor: Colors.brown, foregroundColor: Colors.white, 
      actions: [
        if (_isPreparingFlight) ...[
          IconButton( icon: const Icon(Icons.undo), tooltip: ol('undo_last_change'), onPressed: _pointsHistory.isEmpty ? null : _undoRouteAction, ),
        ],
        if (isSimulatingOrPaused) IconButton(icon: Icon(_simulationState == SimulationState.running ? Icons.pause : Icons.play_arrow), tooltip: ol(_simulationState == SimulationState.running ? 'pause' : 'start_simulation'), onPressed: () { if(_simulationState == SimulationState.running) { _pauseSimulation(); } else { _resumeSimulation(); } }),
        if (isTracking) ...[
          IconButton(icon: const Icon(Icons.share_location), onPressed: _shareCurrentLocation, tooltip: ol('share_location')),
          IconButton(icon: const Icon(Icons.camera_alt), onPressed: _handleTakePhoto, tooltip: ol('take_photo')), 
          IconButton(icon: const Icon(Icons.note_add), onPressed: _handleAddNote, tooltip: ol('add_note'))
        ],
        if (isPremium) IconButton(icon: const Icon(Icons.storage), tooltip: ol('oaci_cache'), onPressed: _showCacheInfo),
        IconButton(icon: const Icon(Icons.map), onPressed: () => showDialog(context: context, builder: (c) => MapTypeDialog(trackData: context.read<TrackData>())), tooltip: ol('map_type_tooltip')),
        IconButton(icon: const Icon(Icons.list_alt), tooltip: ol('tracks_title'), onPressed: () => Navigator.pushNamed(context, TracksScreen.id)),
      ]
    );
  }

  Widget _buildTrackingBanner(LocaData ld, SettingsState settings) { 
    final distStr = settings.formatDistance(ld.travelledLengthDble); 
    final speedStr = settings.formatSpeed(ld.speedValue / 3.6); 
    
    // Logique du bouton boussole / pointillés
    Widget compassButton;
    if (settings.showDestinationLine) {
      compassButton = IconButton(
        icon: const Text('..', style: TextStyle(color: Colors.brown, fontSize: 30, fontWeight: FontWeight.bold)), 
        onPressed: null, // Inactif quand la ligne rouge est forcée par les paramètres
        tooltip: ol('destination_line')
      );
    } else {
      compassButton = IconButton(
        icon: const Icon(Icons.explore_outlined, color: Colors.brown),
        onPressed: () {
          setState(() => _showCompassTemp = true);
          _compassTimer?.cancel();
          _compassTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) setState(() => _showCompassTemp = false);
          });
        },
        tooltip: ol('show_compass_tooltip')
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ 
      compassButton,
      Expanded(child: Text("${ol('to')} ${ld.activeTarget?.name} | $distStr | $speedStr", style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)), 
      IconButton(icon: const Icon(Icons.bar_chart, color: Colors.brown), onPressed: () => Navigator.pushNamed(context, StatsScreen.id), tooltip: ol('trip_stats')) 
    ]); 
  }

  Widget _buildSimulationBanner(LocaData ld, SettingsState settings) {
    Widget compassButton;
    if (settings.showDestinationLine) {
      compassButton = IconButton(
        icon: const Text('..', style: TextStyle(color: Colors.brown, fontSize: 30, fontWeight: FontWeight.bold)), 
        onPressed: null, 
        tooltip: ol('destination_line')
      );
    } else {
      compassButton = IconButton(
        icon: const Icon(Icons.explore_outlined, color: Colors.brown),
        onPressed: () {
          setState(() => _showCompassTemp = true);
          _compassTimer?.cancel();
          _compassTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) setState(() => _showCompassTemp = false);
          });
        },
        tooltip: ol('show_compass_tooltip')
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      compassButton,
      IconButton(icon: const Icon(Icons.fast_rewind), onPressed: () => setState(() { _simulationSpeed = (_simulationSpeed - 1.0).clamp(1.0, 10.0); if(_simulationState == SimulationState.running) _startSimulationTimer(); }), tooltip: ol('simulation_speed_decrease')), 
      Text('x${_simulationSpeed.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)), 
      IconButton(icon: const Icon(Icons.fast_forward), onPressed: () => setState(() { _simulationSpeed = (_simulationSpeed + 1.0).clamp(1.0, 10.0); if(_simulationState == SimulationState.running) _startSimulationTimer(); }), tooltip: ol('simulation_speed_increase')), 
      IconButton(icon: const Icon(Icons.streetview, color: Colors.blue), onPressed: _launchStreetView, tooltip: ol('street_view')),
      IconButton(icon: const Icon(Icons.bar_chart, color: Colors.brown), onPressed: () => Navigator.pushNamed(context, StatsScreen.id), tooltip: ol('trip_stats'))
    ]);
  }

  Future<void> _launchStreetView() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ol('no_position_available'))),
      );
      return;
    }
    final url = Uri.parse(
        'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${_currentPosition!.latitude},${_currentPosition!.longitude}');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        final fallbackUrl = Uri.parse(
            'https://www.google.com/maps?layer=c&cbll=${_currentPosition!.latitude},${_currentPosition!.longitude}');
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ol('error_prefix')} $e')),
        );
      }
    }
  }

  void _handleSimulate() async { final n = Navigator.of(context); if (context.read<LocaData>().isTracking) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ol('simulation_disabled_during_tracking')))); return; } n.pop(); final result = await n.pushNamed(TracksScreen.id, arguments: true); if (result is Map && result['name'] is String) _startSimulation(result['name'], archived: result['archived'] ?? false); }
  Future<void> _handleTakePhoto() async { final ImagePicker pkr = ImagePicker(); final ld = context.read<LocaData>(); final XFile? photo = await pkr.pickImage(source: ImageSource.camera, maxWidth: 400, imageQuality: 60); if (photo != null && mounted) { final bytes = await photo.readAsBytes(); if (!mounted) return; final base64V = base64Encode(bytes); if (_currentPosition == null) return; final actualPos = ld.addPhotoAtPosition(_currentPosition!, base64V); _addNoteMarker(actualPos, '', photoVignette: base64V); _showNoteEditDialog(actualPos, '', null, base64V); } }
  void _handleAddNote() async { final ld = context.read<LocaData>(); if (_currentPosition == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ol('no_position_available')))); return; } _positionStream?.pause(); final actualPos = ld.addNoteAtPosition(_currentPosition!, ''); _addNoteMarker(actualPos, ''); _showNoteEditDialog(actualPos, '', null, null); _positionStream?.resume(); }
}

class _OpenAIPTileProvider implements TileProvider {
  static String? _cacheDirPath; static Completer<void>? _initCompleter; final VoidCallback? onQuotaExceeded; bool _hasNotifiedQuota = false;
  _OpenAIPTileProvider({this.onQuotaExceeded});
  static Future<Map<String, dynamic>> getCacheInfo() async { 
    if (_cacheDirPath == null) { 
      try { 
        final cacheDir = await getTemporaryDirectory(); 
        _cacheDirPath = p.join(cacheDir.path, 'oaci_cache'); 
      } catch (_) { 
        return {'count': 0, 'size': 0.0}; 
      } 
    } 
    final dir = Directory(_cacheDirPath!); 
    int count = 0; 
    int totalSize = 0; 
    if (await dir.exists()) {
      try { 
        final List<FileSystemEntity> files = dir.listSync(); 
        for (var file in files) { 
          if (file is File && file.path.endsWith('.png')) { 
            count++; 
            totalSize += await file.length(); 
          } 
        } 
      } catch (e) { 
        debugPrint("OACI_CACHE: Erreur calcul info: $e"); 
      } 
    }
    return {'count': count, 'size': totalSize / (1024 * 1024)}; 
  }
  static Future<void> clearCache() async { if (_cacheDirPath == null) return; final dir = Directory(_cacheDirPath!); if (await dir.exists()) { try { final List<FileSystemEntity> files = dir.listSync(); for (var file in files) { if (file is File) await file.delete(); } } catch (e) { debugPrint("OACI_CACHE: Erreur suppression cache: $e"); } } }
  Future<void> _ensureCacheDir() async { if (_cacheDirPath != null) return; if (_initCompleter != null) return _initCompleter!.future; _initCompleter = Completer<void>(); try { final cacheDir = await getTemporaryDirectory(); _cacheDirPath = p.join(cacheDir.path, 'oaci_cache'); final dir = Directory(_cacheDirPath!); if (!await dir.exists()) await dir.create(recursive: true); _initCompleter!.complete(); } catch (e) { _initCompleter!.completeError(e); _initCompleter = null; } }
  @override Future<Tile> getTile(int x, int y, int? zoom) async { if (zoom == null) return TileProvider.noTile; try { await _ensureCacheDir(); } catch (_) { return _getRemoteTile(x, y, zoom); } final String fileName = 'tile_${zoom}_${x}_$y.png'; File? localFile; if (_cacheDirPath != null) { localFile = File(p.join(_cacheDirPath!, fileName)); try { if (await localFile.exists()) { final Uint8List bytes = await localFile.readAsBytes(); if (bytes.isNotEmpty) return Tile(256, 256, bytes); } } catch (e) { debugPrint("OACI_CACHE: Erreur lecture $fileName: $e"); } } return _getRemoteTile(x, y, zoom, localFile: localFile); }
  Future<Tile> _getRemoteTile(int x, int y, int zoom, {File? localFile}) async { final String fileName = 'tile_${zoom}_${x}_$y.png'; final url = 'https://api.tiles.openaip.net/api/data/openaip/$zoom/$x/$y.png?apiKey=$_openAipApiKey'; try { final response = await http.get(Uri.parse(url), headers: { 'User-Agent': 'Traceo-App-Flutter', 'Accept': 'image/png' }).timeout(const Duration(seconds: 15)); if (response.statusCode == 200) { if (localFile != null) await localFile.writeAsBytes(response.bodyBytes); return Tile(256, 256, response.bodyBytes); } else if (response.statusCode == 429 || response.statusCode == 402) { if (!_hasNotifiedQuota) { _hasNotifiedQuota = true; onQuotaExceeded?.call(); } } } catch (e) { debugPrint("OACI_CACHE: Erreur réseau $fileName: $e"); } return TileProvider.noTile; }
}
