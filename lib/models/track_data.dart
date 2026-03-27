import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';

import '../components/routs.dart';
import '../models/track.dart';
import '../models/handle_bounds.dart';
import 'sort_state.dart';

class TrackData with ChangeNotifier {
  String _trackPath = '';
  final List<Track> _tracks = [];
  final List<Track> _archivedTracks = [];

  bool isLoading = true;
  List<String> _tracksToDisplay = [];
  List<LatLng> _trackCoordinates = [];
  bool isMergingPreview = false;
  String trackNameForDisplay = "";
  MapType mapType = MapType.terrain;
  bool isAviationLayerEnabled = false; // Réactivation de l'option manuelle
  final SortState _sortState = SortState();

  TrackData() {
    _init();
  }

  Future<void> _init() async {
    await initializeDateFormatting('fr_FR', null);
    await createAppFolder();
    await listTracks();
  }

  List<Track> get tracks => _tracks;
  List<Track> get archivedTracks => _archivedTracks;
  int get trackCount => _tracks.length;
  String get trackPath => _trackPath;
  String get archivePath => _trackPath.isNotEmpty ? p.join(_trackPath, 'archives') : '';
  String get homePath => '$_trackPath/homes';
  List<String> get tracksToDisplay => _tracksToDisplay;
  List<LatLng> get trackCoordinates => _trackCoordinates;
  MapType get currentMapType => mapType;
  SortState get sortState => _sortState;

  void setMapType(MapType newMapType) {
    mapType = newMapType;
    notifyListeners();
  }

  void toggleAviationLayer() {
    isAviationLayerEnabled = !isAviationLayerEnabled;
    notifyListeners();
  }

  void setSort(SortCriterion criterion) {
    _sortState.set(criterion);
    sortTracks();
    notifyListeners();
  }

  List<String> get getSelectedTracksNames {
    return _tracks.where((t) => t.isDone).toList().map((t) => t.name).toList();
  }
  
  List<String> get getSelectedArchivedTracksNames {
    return _archivedTracks.where((t) => t.isDone).toList().map((t) => t.name).toList();
  }

  void toggleDone(int index) {
    if (index >= 0 && index < _tracks.length) {
      _tracks[index].isDone = !_tracks[index].isDone;
      notifyListeners();
    }
  }

  void toggleArchiveDone(int index) {
    if (index >= 0 && index < _archivedTracks.length) {
      _archivedTracks[index].isDone = !_archivedTracks[index].isDone;
      notifyListeners();
    }
  }

  void setTracksToDisplay(List<String> trackNames) {
    _tracksToDisplay = trackNames;
    if (trackNames.length == 1) {
      trackNameForDisplay = trackNames.first;
      isMergingPreview = false;
    } else {
      trackNameForDisplay = "";
      isMergingPreview = trackNames.length > 1;
    }
  }

  Future<void> createAppFolder() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _trackPath = directory.path;
      final archiveDir = Directory(p.join(_trackPath, 'archives'));
      if (!await archiveDir.exists()) {
        await archiveDir.create();
      }
    } catch (_) {
      // Ignore error when creating app folder
    }
  }

  Future<void> listTracks() async {
    isLoading = true;
    notifyListeners();
    _tracks.clear();
    if (_trackPath.isEmpty) await createAppFolder();

    final directory = Directory(_trackPath);
    try {
      if (await directory.exists()) {
        await for (var entity in directory.list()) {
          if (entity is File &&
              entity.path.endsWith('.txt') &&
              !entity.path.endsWith('log.txt')) {
            try {
              final lines = await entity.readAsLines();
              if (lines.length >= 7) {
                _tracks.add(Track.fromLines(lines));
              }
            } catch (_) {
              // Ignore corrupted or invalid track files
            }
          }
        }
        sortTracks();
      }
    } catch (_) {
      // Ignore directory listing errors
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> listArchivedTracks() async {
    _archivedTracks.clear();
    if (_trackPath.isEmpty) await createAppFolder();
    
    final directory = Directory(archivePath);
    try {
      if (await directory.exists()) {
        await for (var entity in directory.list()) {
             if (entity is File && entity.path.endsWith('.txt')) {
            try {
              final lines = await entity.readAsLines();
              if (lines.length >= 7) {
                _archivedTracks.add(Track.fromLines(lines));
              } 
            } catch (_) {
              // Ignore corrupted or invalid archived track files
            }
          }
        }
        sortTracks();
      }
    } catch (_) {
      // Ignore directory listing errors for archives
    }
    notifyListeners();
  }

  Future<void> writeTrack(String trackName, String content) async {
    final file = File(p.join(trackPath, '$trackName.txt'));
    await file.writeAsString(content);
    
    // Optimisation : au lieu de relire TOUTES les traces, on met à jour uniquement celle-ci
    final lines = content.split('\n');
    if (lines.length >= 7) {
      final newTrack = Track.fromLines(lines);
      final index = _tracks.indexWhere((t) => t.name == trackName);
      if (index != -1) {
        _tracks[index] = newTrack;
      } else {
        _tracks.add(newTrack);
      }
      sortTracks();
      notifyListeners();
    }
  }

  void writeTrackSync(String trackName, String content) {
    final file = File(p.join(trackPath, '$trackName.txt'));
    file.writeAsStringSync(content);
  }

  Future<void> deleteTracks(List<String> trackNames) async {
    for (var trackName in trackNames) {
      try {
        final file = File(p.join(_trackPath, '$trackName.txt'));
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore errors during file deletion
      }
    }
    await listTracks();
  }

  Future<void> deleteArchivedTracks(List<String> trackNames) async {
    for (var trackName in trackNames) {
      try {
        final file = File(p.join(archivePath, '$trackName.txt'));
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore errors during archived file deletion
      }
    }
    await listArchivedTracks();
  }

  Future<void> changeName(String newName, int index) async {
    if (index < 0 || index >= _tracks.length) return;
    final oldName = _tracks[index].name;
    final oldFile = File('$_trackPath/$oldName.txt');
    final newFile = File('$_trackPath/$newName.txt');
    if (await newFile.exists()) return;
    try {
      List<String> lines = await oldFile.readAsLines();
      lines[0] = newName;
      String newContent = lines.join('\n');
      await newFile.writeAsString(newContent);
      await oldFile.delete();
    } catch (_) {
      // Ignore renaming errors
    }
    await listTracks();
  }
  
  Future<void> archiveTracks(List<Track> tracksToArchive) async {
    for (var track in tracksToArchive) {
      try {
        final sourceFile = File(p.join(trackPath, '${track.name}.txt'));
        final destFile = File(p.join(archivePath, '${track.name}.txt'));
        if (await sourceFile.exists()) {
           final archiveDir = Directory(archivePath);
           if (!await archiveDir.exists()) await archiveDir.create();
           await sourceFile.rename(destFile.path);
        }
      } catch(_) {
        // Ignore archival errors for individual tracks
      }
    }
    await listTracks();
    await listArchivedTracks();
  }
  
  Future<void> unarchiveTracks(List<Track> tracksToUnarchive) async {
    for (var track in tracksToUnarchive) {
      try {
        final sourceFile = File(p.join(archivePath, '${track.name}.txt'));
        final destFile = File(p.join(trackPath, '${track.name}.txt'));
        if (await sourceFile.exists()) {
           await sourceFile.rename(destFile.path);
        }
      } catch(_) {
        // Ignore unarchival errors for individual tracks
      }
    }
    await listArchivedTracks();
    await listTracks();
  }

  Future<void> mergeTracks(List<Track> tracksToMerge, String newTrackName, {required bool deleteSource}) async {
    if (tracksToMerge.length < 2) return;
    tracksToMerge.sort((a, b) => a.start.compareTo(b.start));
    double totalDistance = tracksToMerge.fold(0, (sum, t) => sum + t.distance);
    int totalDuration = tracksToMerge.fold(0, (sum, t) => sum + t.duree);
    int totalMovingTime = tracksToMerge.fold(0, (sum, t) => sum + t.moving);
    String startTime = tracksToMerge.first.start;
    String endTime = tracksToMerge.last.end;
    List<String> allPointsLines = [];
    List<LatLng> allLatLngs = [];

    for (var track in tracksToMerge) {
      final file = File('$_trackPath/${track.name}.txt');
      final lines = await file.readAsLines();
      final points = lines.sublist(7);
      allPointsLines.addAll(points);
      for (var line in points) {
        final parts = line.split(' ');
        if (parts.length >= 2) {
          allLatLngs.add(LatLng(double.parse(parts[0]), double.parse(parts[1])));
        }
      }
    }

    if (allPointsLines.isEmpty) return;
    final bounds = HandleBounds.fromPoints(allLatLngs);
    final String boundsData = '${bounds.southwest.latitude} ${bounds.southwest.longitude} ${bounds.northeast.latitude} ${bounds.northeast.longitude}';
    final header = '$newTrackName\n$boundsData\n$startTime\n$endTime\n$totalDuration\n$totalMovingTime\n$totalDistance';
    await writeTrack(newTrackName, '$header\n${allPointsLines.join('\n')}');

    if (deleteSource) {
      await deleteTracks(tracksToMerge.map((t) => t.name).toList());
    }
    await listTracks();
  }

  Future<String> cutTrack(String trackName, LatLng cutPoint) async {
    try {
      final originalFile = File(p.join(trackPath, '$trackName.txt'));
      if (!await originalFile.exists()) return ol('track_not_found');
      final lines = await originalFile.readAsLines();
      if (lines.length < 8) return ol('invalid_track_format');

      List<String> points = lines.sublist(7);
      int closestPointIndex = -1;
      double minDistance = double.infinity;

      for (int i = 0; i < points.length; i++) {
        final parts = points[i].trim().split(' ');
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          final distance = _calculateDistance(lat, lng, cutPoint.latitude, cutPoint.longitude);
          if (distance < minDistance) { minDistance = distance; closestPointIndex = i; }
        }
      }

      if (closestPointIndex <= 0 || closestPointIndex >= points.length - 1) return ol('cut_failed_snackbar');

      await _createNewTrackFromPoints(trackName, '1', points.sublist(0, closestPointIndex + 1));
      await _createNewTrackFromPoints(trackName, '2', points.sublist(closestPointIndex));
      await originalFile.delete();
      await listTracks();
      return ol('cut_success_snackbar');
    } catch (e) { return '${ol('cut_failed_snackbar')}: $e'; }
  }

  Future<void> _createNewTrackFromPoints(String originalName, String suffix, List<String> points) async {
    if (points.isEmpty) return;
    final newTrackName = '$originalName$suffix';
    List<LatLng> latLngs = [];
    List<String> validPoints = [];
    List<DateTime> timestamps = [];
    int totalPauseDuration = 0;

    for (var p in points) {
      final parts = p.trim().split(' ');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          latLngs.add(LatLng(lat, lng));
          validPoints.add(p.trim());
          if (parts.length > 3) { try { timestamps.add(DateTime.parse(parts[3])); } catch (_) {} }
          for (var part in parts) { if (part.startsWith('pause:')) totalPauseDuration += int.tryParse(part.substring(6)) ?? 0; }
        }
      }
    }

    if (latLngs.isEmpty) return;
    final bounds = HandleBounds.fromPoints(latLngs);
    final String boundsData = '${bounds.southwest.latitude} ${bounds.southwest.longitude} ${bounds.northeast.latitude} ${bounds.northeast.longitude}';
    timestamps.sort();
    var dateFormat = DateFormat("d MMMM yyyy HH'h'mm", 'fr_FR');
    final String startTime = timestamps.isNotEmpty ? dateFormat.format(timestamps.first) : "";
    final String endTime = timestamps.isNotEmpty ? dateFormat.format(timestamps.last) : "";
    int totalDuration = timestamps.isNotEmpty ? timestamps.last.difference(timestamps.first).inSeconds : 0;
    int movingTime = max(0, totalDuration - totalPauseDuration);
    double totalDist = 0.0;
    for (int i = 0; i < latLngs.length - 1; i++) { totalDist += _calculateDistance(latLngs[i].latitude, latLngs[i].longitude, latLngs[i+1].latitude, latLngs[i+1].longitude); }

    final header = '$newTrackName\n$boundsData\n$startTime\n$endTime\n$totalDuration\n$movingTime\n${totalDist.toStringAsFixed(2)}';
    await writeTrack(newTrackName, '$header\n${validPoints.join('\n')}');
  }

  Future<int> addNoteOrPhotoToTrack(String trackName, LatLng point, {String? note, String? vignette}) async {
    final file = File(p.join(trackPath, '$trackName.txt'));
    if (!await file.exists()) return -1;
    List<String> lines = await file.readAsLines();
    if (lines.length < 8) return -1;
    int closestIdx = -1;
    double minDist = double.infinity;
    for (int i = 7; i < lines.length; i++) {
      final parts = lines[i].split(' ');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          final dist = _calculateDistance(lat, lng, point.latitude, point.longitude);
          if (dist < minDist) { minDist = dist; closestIdx = i; }
        }
      }
    }
    if (closestIdx != -1) {
      String line = lines[closestIdx];
      if (note != null && note.trim().isNotEmpty) line += ' ${Uri.encodeComponent(note.trim())}';
      if (vignette != null) line += ' vignette:$vignette';
      lines[closestIdx] = line;
      await file.writeAsString(lines.join('\n'));
      await listTracks();
    }
    return closestIdx;
  }

  Future<void> updateNote(String trackName, int lineIndex, String newNote) async {
    final file = File(p.join(trackPath, '$trackName.txt'));
    if (!await file.exists()) return;
    List<String> lines = await file.readAsLines();
    if (lineIndex >= lines.length) return;
    List<String> parts = lines[lineIndex].split(' ');
    String newLine = "${parts[0]} ${parts[1]} ${parts[2]} ${parts[3]}";
    
    if (newNote.trim().isNotEmpty) {
      newLine += " ${Uri.encodeComponent(newNote.trim())}";
    }
    
    for (int i = 4; i < parts.length; i++) { 
      if (parts[i].startsWith("vignette:") || parts[i].startsWith("pause:")) {
        newLine += " ${parts[i]}"; 
      }
    }
    lines[lineIndex] = newLine;
    await file.writeAsString(lines.join('\n'));
    await listTracks();
  }

  Future<void> deleteVignetteFromTrack(String trackName, int lineIndex) async {
    final file = File(p.join(trackPath, '$trackName.txt'));
    if (!await file.exists()) return;
    List<String> lines = await file.readAsLines();
    if (lineIndex >= lines.length) return;
    
    List<String> parts = lines[lineIndex].split(' ');
    String newLine = "${parts[0]} ${parts[1]} ${parts[2]} ${parts[3]}";
    
    for (int i = 4; i < parts.length; i++) { 
      if (!parts[i].startsWith("vignette:")) {
        newLine += " ${parts[i]}"; 
      }
    }
    
    lines[lineIndex] = newLine;
    await file.writeAsString(lines.join('\n'));
    await listTracks();
  }

  Future<void> deleteNoteAndPhotoFromTrack(String trackName, int lineIndex) async {
    final file = File(p.join(trackPath, '$trackName.txt'));
    if (!await file.exists()) return;
    List<String> lines = await file.readAsLines();
    if (lineIndex >= lines.length) return;
    
    List<String> parts = lines[lineIndex].split(' ');
    // On ne garde que les 4 premières parties (lat lng alt time) et éventuellement la pause
    String newLine = "${parts[0]} ${parts[1]} ${parts[2]} ${parts[3]}";
    
    for (int i = 4; i < parts.length; i++) { 
      if (parts[i].startsWith("pause:")) {
        newLine += " ${parts[i]}"; 
      }
    }
    
    lines[lineIndex] = newLine;
    await file.writeAsString(lines.join('\n'));
    await listTracks();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p)/2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  Future<String> exportTracksToTempFile(List<Track> tracksToExport, String fileName) async {
    final archive = Archive();
    for (var track in tracksToExport) {
      final file = File(p.join(_trackPath, '${track.name}.txt'));
      if (await file.exists()) {
        final content = await file.readAsBytes();
        archive.addFile(ArchiveFile('${track.name}.txt', content.length, content));
      }
    }
    if (archive.isEmpty) throw Exception(ol('no_track_selected'));
    final encodedZip = ZipEncoder().encode(archive);
    if (encodedZip == null) throw Exception(ol('error_creating_zip'));
    final tempZipFile = File(p.join((await getTemporaryDirectory()).path, '$fileName.zip'));
    await tempZipFile.writeAsBytes(encodedZip);
    return tempZipFile.path;
  }

  Future<String> exportArchivesToTempFile({String fileName = 'backup'}) async {
    final archive = Archive();
    final archiveDir = Directory(archivePath);
    if (!await archiveDir.exists()) throw Exception(ol('no_archives_found'));
    
    final files = archiveDir.listSync().whereType<File>().where((f) => f.path.endsWith('.txt')).toList();
    if (files.isEmpty) throw Exception(ol('no_archives_to_export'));

    for (var file in files) {
       final content = await file.readAsBytes();
       archive.addFile(ArchiveFile(p.basename(file.path), content.length, content));
    }
    final encodedZip = ZipEncoder().encode(archive);
    if (encodedZip == null) throw Exception(ol('error_creating_zip'));
    final tempZipFile = File(p.join((await getTemporaryDirectory()).path, '$fileName.zip'));
    await tempZipFile.writeAsBytes(encodedZip);
    return tempZipFile.path;
  }

  Future<String> importSharedTracks() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
      if (result == null || result.files.single.path == null) return ol('import_cancelled');
      final bytes = await File(result.files.single.path!).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      int count = 0;
      for (final file in archive) {
        if (file.isFile) {
           final destPath = p.join(trackPath, p.basename(file.name));
           if (!await File(destPath).exists()) {
              await File(destPath).writeAsBytes(file.content as List<int>);
              count++;
           }
        }
      }
      await listTracks();
      return "${ol('tracks_imported_success')} $count ${ol('new_tracks')}";
    } catch (e) { return "${ol('error_importing_tracks')}: $e"; }
  }

  Future<String> importArchives() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
      if (result == null || result.files.single.path == null) return ol('import_cancelled');
      final bytes = await File(result.files.single.path!).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final localArchiveDir = Directory(archivePath);
      if (!await localArchiveDir.exists()) await localArchiveDir.create();
      int count = 0;
      for (final file in archive) {
        if (file.isFile) {
           final destPath = p.join(archivePath, p.basename(file.name));
           if (!await File(destPath).exists()) {
              await File(destPath).writeAsBytes(file.content as List<int>);
              count++;
           }
        }
      }
      await listArchivedTracks();
      return "${ol('archives_imported_success')} $count ${ol('new_archives')}";
    } catch (e) { return "${ol('error_importing_archives')}: $e"; }
  }

  void sortTracks() {
    int Function(Track, Track) compare;
    switch (_sortState.criterion) {
      case SortCriterion.name: compare = (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()); break;
      case SortCriterion.distance: compare = (a, b) => a.distance.compareTo(b.distance); break;
      case SortCriterion.duration: compare = (a, b) => a.duree.compareTo(b.duree); break;
      case SortCriterion.date: compare = (a, b) => _parseDate(a.start).compareTo(_parseDate(b.start)); break;
    }
    _tracks.sort((a, b) => _sortState.direction == SortDirection.ascending ? compare(a, b) : -compare(a, b));
    _archivedTracks.sort((a, b) => _sortState.direction == SortDirection.ascending ? compare(a, b) : -compare(a, b));
  }

  DateTime _parseDate(String dateStr) {
    try { return DateFormat("d MMMM yyyy HH'h'mm", 'fr_FR').parse(dateStr); }
    catch (_) { try { return DateTime.parse(dateStr); } catch (_) { return DateTime.fromMillisecondsSinceEpoch(0); } }
  }

  void clearDisplayData() { _tracksToDisplay = []; _trackCoordinates = []; isMergingPreview = false; trackNameForDisplay = ""; }
}
