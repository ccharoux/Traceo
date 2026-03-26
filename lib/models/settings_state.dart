import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

enum DistanceUnit { kilometers, nauticalMiles, miles }

class SettingsState extends ChangeNotifier {
  static const String _unitKey = 'settings_distance_unit';
  static const String _showDestinationLineKey = 'settings_show_destination_line';
  static const String _minPauseDurationKey = 'settings_min_pause_duration';

  DistanceUnit _unit = DistanceUnit.kilometers;
  bool _showDestinationLine = true;
  int _minPauseDuration = 0; // 0 = désactivé, sinon minutes (5, 10, 15...)
  
  int _oaciTileCount = 0;
  String _oaciCacheSize = "0 Ko";

  DistanceUnit get unit => _unit;
  bool get showDestinationLine => _showDestinationLine;
  int get minPauseDuration => _minPauseDuration;
  bool get showPauseMarkers => _minPauseDuration > 0;
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
    _minPauseDuration = prefs.getInt(_minPauseDurationKey) ?? 0;
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

  Future<bool> exportOaciCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final oaciPath = p.join(cacheDir.path, 'oaci_cache');
      final dir = Directory(oaciPath);
      if (!await dir.exists()) return false;

      final files = dir.listSync().whereType<File>().toList();
      if (files.isEmpty) return false;

      final archive = Archive();
      for (var file in files) {
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(p.basename(file.path), bytes.length, bytes));
      }

      final zipEncoder = ZipEncoder();
      final encodedZip = zipEncoder.encode(archive);
      if (encodedZip == null) return false;

      final tempDir = await getTemporaryDirectory();
      final zipFile = File(p.join(tempDir.path, 'oaci_cache_export.zip'));
      await zipFile.writeAsBytes(encodedZip);

      await Share.shareXFiles([XFile(zipFile.path)], text: 'Export Cache OACI Traceo');
      return true;
    } catch (e) {
      debugPrint("Erreur export cache: $e");
      return false;
    }
  }

  Future<bool> importOaciCache() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) return false;

      final zipFile = File(result.files.single.path!);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final cacheDir = await getTemporaryDirectory();
      final oaciPath = p.join(cacheDir.path, 'oaci_cache');
      final dir = Directory(oaciPath);
      if (!await dir.exists()) await dir.create(recursive: true);

      for (final file in archive) {
        if (file.isFile) {
          final data = file.content as List<int>;
          File(p.join(oaciPath, file.name))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }

      await updateCacheInfo();
      return true;
    } catch (e) {
      debugPrint("Erreur import cache: $e");
      return false;
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

  Future<void> setMinPauseDuration(int minutes) async {
    _minPauseDuration = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_minPauseDurationKey, minutes);
    notifyListeners();
  }

  String formatDistance(double meters) {
    switch (_unit) {
      case DistanceUnit.kilometers:
        if (meters < 999.5) {
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
