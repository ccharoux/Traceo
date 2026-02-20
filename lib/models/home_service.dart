import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';

import './home.dart';
import '../components/routs.dart';

class HomeService with ChangeNotifier {
  static const _homesKey = 'homes';
  static const _chosenHomeKey = 'chosenHome';
  List<Home> _homes = [];

  List<Home> get homes => _homes;

  HomeService() {
    loadHomes();
  }

  Future<void> loadHomes() async {
    final prefs = await SharedPreferences.getInstance();
    final homesJson = prefs.getStringList(_homesKey) ?? [];
    _homes = homesJson.map((json) => Home.fromJson(jsonDecode(json))).toList();
    _sortHomes();
    notifyListeners();
  }

  void _sortHomes() {
    _homes.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<bool> addHome(Home home) async {
    if (_homes.any((h) => h.name == home.name)) {
      return false; 
    }
    if (home.vacUrl != null && home.vacUrl!.startsWith('http')) {
      final localPath = await _downloadAndSaveVac(home.vacUrl!, home.name);
      home = home.copyWith(vacUrl: localPath);
    }
    _homes.add(home);
    await _saveHomesList();
    return true;
  }

  Future<String?> _downloadAndSaveVac(String url, String homeName) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '$homeName.pdf';
        final localFile = File(p.join(appDir.path, fileName));
        await localFile.writeAsBytes(response.bodyBytes);
        return localFile.path;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteHome(String homeName) async {
    final home = _homes.firstWhere((h) => h.name == homeName, orElse: () => Home(name: '', latitude: 0, longitude: 0));
    if (home.name.isNotEmpty && home.vacUrl != null && !home.vacUrl!.startsWith('http')) {
      try {
        final file = File(home.vacUrl!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Handle error if needed
      }
    }
    _homes.removeWhere((h) => h.name == homeName);
    await _saveHomesList();
  }
  
  Future<bool> renameHome(String oldName, String newName) async {
    if (oldName == newName) return true;
    if (_homes.any((h) => h.name == newName)) {
      return false;
    }
    final index = _homes.indexWhere((h) => h.name == oldName);
    if (index != -1) {
      Home homeToRename = _homes[index];
      String? newVacPath;

      if (homeToRename.vacUrl != null && !homeToRename.vacUrl!.startsWith('http')) {
        try {
          final oldFile = File(homeToRename.vacUrl!);
          if (await oldFile.exists()) {
            final directory = p.dirname(oldFile.path);
            final newFileName = '$newName.pdf';
            newVacPath = p.join(directory, newFileName);
            await oldFile.rename(newVacPath);
          }
        } catch (e) {
          // Handle error
        }
      }

      _homes[index] = homeToRename.copyWith(
        name: newName,
        vacUrl: newVacPath ?? homeToRename.vacUrl,
      );
      
      await _saveHomesList();
      return true;
    }
    return false;
  }

  Future<void> updateHome(Home updatedHome) async {
    final index = _homes.indexWhere((h) => h.name == updatedHome.name);
    if (index != -1) {
      if (updatedHome.vacUrl != null && updatedHome.vacUrl!.startsWith('http')) {
        final localPath = await _downloadAndSaveVac(updatedHome.vacUrl!, updatedHome.name);
        updatedHome = updatedHome.copyWith(vacUrl: localPath);
      }
      _homes[index] = updatedHome;
      await _saveHomesList();
    }
  }

  Future<void> _saveHomesList() async {
    _sortHomes();
    final prefs = await SharedPreferences.getInstance();
    final homesJson = _homes.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList(_homesKey, homesJson);
    notifyListeners();
  }

  Future<String> exportHomes({String fileName = 'destinations'}) async {
    await loadHomes();
    if (_homes.isEmpty) {
      return ol('no_destinations_to_export');
    }

    final tempDir = await getTemporaryDirectory();
    final jsonFile = File('${tempDir.path}/destinations.json');
    final homesJson = _homes.map((h) => h.toJson()).toList();
    await jsonFile.writeAsString(jsonEncode(homesJson));

    final archive = Archive();
    archive.addFile(ArchiveFile('destinations.json', jsonFile.lengthSync(), await jsonFile.readAsBytes()));

    for (final home in _homes) {
      if (home.vacUrl != null && !home.vacUrl!.startsWith('http')) {
        final vacFile = File(home.vacUrl!);
        if (await vacFile.exists()) {
          archive.addFile(ArchiveFile(p.basename(vacFile.path), vacFile.lengthSync(), await vacFile.readAsBytes()));
        }
      }
    }

    final zipFile = File('${tempDir.path}/$fileName.zip');
    final encoder = ZipEncoder();
    final outputStream = OutputFileStream(zipFile.path);
    encoder.encode(archive, output: outputStream);
    outputStream.close();

    await Share.shareXFiles([XFile(zipFile.path)], text: ol('export_destinations_share_text'));

    await jsonFile.delete();
    await zipFile.delete();

    return ol('export_success');
  }


  Future<String> importHomes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) {
      return ol('import_cancelled');
    }

    final file = File(result.files.single.path!);
    final inputStream = InputFileStream(file.path);
    final archive = ZipDecoder().decodeBuffer(inputStream);

    final jsonFile = archive.findFile('destinations.json');
    if (jsonFile == null) {
      return ol('import_error');
    }

    final jsonString = utf8.decode(jsonFile.content);
    final List<dynamic> homesJson = jsonDecode(jsonString);
    final List<Home> importedHomes =
        homesJson.map((json) => Home.fromJson(json)).toList();

    if (importedHomes.isEmpty) {
      return ol('no_destinations_in_file');
    }

    final appDir = await getApplicationDocumentsDirectory();

    for (var importedHome in importedHomes) {
      final vacFile = archive.findFile(p.basename(importedHome.vacUrl ?? ''));
      if (vacFile != null) {
        final localVacFile = File(p.join(appDir.path, p.basename(importedHome.vacUrl!)));
        await localVacFile.writeAsBytes(vacFile.content);
        importedHome = importedHome.copyWith(vacUrl: localVacFile.path);
      }
      _homes.removeWhere((h) => h.name == importedHome.name);
      _homes.add(importedHome);
    }

    await _saveHomesList();
    return "${importedHomes.length} ${ol('destinations_imported_success')}";

  }

  Future<void> saveChosenHome(Home home) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chosenHomeKey, jsonEncode(home.toJson()));
  }

  Future<Home?> getChosenHome() async {
    final prefs = await SharedPreferences.getInstance();
    final homeJson = prefs.getString(_chosenHomeKey);
    if (homeJson != null) {
      return Home.fromJson(jsonDecode(homeJson));
    }
    return null;
  }
}
