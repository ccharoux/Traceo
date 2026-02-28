import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum DistanceUnit { kilometers, nauticalMiles, miles }

class SettingsState extends ChangeNotifier {
  static const String _unitKey = 'settings_distance_unit';
  static const String _showDestinationLineKey = 'settings_show_destination_line';
  static const String _showPauseMarkersKey = 'settings_show_pause_markers';

  DistanceUnit _unit = DistanceUnit.kilometers;
  bool _showDestinationLine = true;
  bool _showPauseMarkers = true;
  
  int _oaciTileCount = 0;
  String _oaciCacheSize = "0 Ko";

  DistanceUnit get unit => _unit;
  bool get showDestinationLine => _showDestinationLine;
  bool get showPauseMarkers => _showPauseMarkers;
  int get oaciTileCount => _oaciTileCount;
  String get oaciCacheSize => _oaciCacheSize;

  SettingsState() {
    _loadSettings();
    updateCacheInfo();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final unitIndex = prefs.getInt(_unitKey) ?? 0;
    if (unitIndex >= 0 && unitIndex < DistanceUnit.values.length) {
      _unit = DistanceUnit.values[unitIndex];
    } else {
      _unit = DistanceUnit.kilometers;
    }
    _showDestinationLine = prefs.getBool(_showDestinationLineKey) ?? true;
    _showPauseMarkers = prefs.getBool(_showPauseMarkersKey) ?? true;
    notifyListeners();
  }

  Future<void> updateCacheInfo() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final oaciPath = p.join(cacheDir.path, 'oaci_cache');
      final dir = Directory(oaciPath);
      if (await dir.exists()) {
        final files = dir.listSync();
        _oaciTileCount = files.length;
        int totalBytes = 0;
        for (var file in files) {
          if (file is File) {
            totalBytes += await file.length();
          }
        }
        if (totalBytes < 1024 * 1024) {
          _oaciCacheSize = "${(totalBytes / 1024).toStringAsFixed(1)} Ko";
        } else {
          _oaciCacheSize = "${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} Mo";
        }
      } else {
        _oaciTileCount = 0;
        _oaciCacheSize = "0 Ko";
      }
    } catch (e) {
      debugPrint("Erreur info cache: $e");
    }
    notifyListeners();
  }

  Future<void> clearOaciCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final oaciPath = p.join(cacheDir.path, 'oaci_cache');
      final dir = Directory(oaciPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
      await updateCacheInfo();
    } catch (e) {
      debugPrint("Erreur clear cache: $e");
    }
  }

  Future<void> setUnit(DistanceUnit unit) async {
    _unit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_unitKey, unit.index);
    notifyListeners();
  }

  Future<void> setShowDestinationLine(bool value) async {
    _showDestinationLine = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showDestinationLineKey, value);
    notifyListeners();
  }

  Future<void> setShowPauseMarkers(bool value) async {
    _showPauseMarkers = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showPauseMarkersKey, value);
    notifyListeners();
  }

  String formatDistance(double meters) {
    switch (_unit) {
      case DistanceUnit.kilometers:
        if (meters < 1000) {
          return '${meters.toStringAsFixed(0)} m';
        } else {
          return '${(meters / 1000).toStringAsFixed(2)} km';
        }
      case DistanceUnit.nauticalMiles:
        final nm = meters / 1852.0;
        return '${nm.toStringAsFixed(2)} NM';
      case DistanceUnit.miles:
        final miles = meters / 1609.34;
        return '${miles.toStringAsFixed(2)} mi';
    }
  }

  String formatSpeed(double metersPerSecond) {
    switch (_unit) {
      case DistanceUnit.kilometers:
        final kmh = metersPerSecond * 3.6;
        return '${kmh.toStringAsFixed(1)} kmh';
      case DistanceUnit.nauticalMiles:
        final knots = metersPerSecond / 0.514444;
        return '${knots.toStringAsFixed(1)} kt';
      case DistanceUnit.miles:
        final mph = metersPerSecond / 0.44704;
        return '${mph.toStringAsFixed(1)} mph';
    }
  }

  String formatAltitude(double meters) {
    switch (_unit) {
      case DistanceUnit.kilometers:
        return '${meters.toStringAsFixed(0)} m';
      case DistanceUnit.nauticalMiles:
      case DistanceUnit.miles:
        final feet = meters * 3.28084;
        return '${feet.toStringAsFixed(0)} ft';
    }
  }
}
