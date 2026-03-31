import 'package:intl/intl.dart';

class Track {
  String name;
  String bounds;
  String start;
  String end;
  int duree;
  int moving;
  double distance;
  bool isDone;
  String? vignetteBase64; // La vignette embarquée

  Track({
    required this.name,
    required this.bounds,
    required this.start,
    required this.end,
    required this.duree,
    required this.moving,
    required this.distance,
    this.isDone = false,
    this.vignetteBase64,
  });

  void toggleDone() {
    isDone = !isDone;
  }

  factory Track.fromLines(List<String> lines) {
    String? foundVignette;
    if (lines.length > 7) {
      for (int i = 7; i < lines.length; i++) {
        if (lines[i].contains('vignette:')) {
          final parts = lines[i].split(' ');
          for (var part in parts) {
            if (part.startsWith('vignette:')) {
              foundVignette = part.substring(9);
              break;
            }
          }
        }
        if (foundVignette != null) break;
      }
    }

    final startStr = lines[2];
    final endStr = lines[3];
    int duree = int.tryParse(lines[4]) ?? 0;

    try {
      final DateFormat df = DateFormat("d MMMM yyyy HH'h'mm", 'fr_FR');
      final DateTime startDate = df.parse(startStr);
      final DateTime endDate = df.parse(endStr);
      duree = endDate.difference(startDate).inSeconds;
    } catch (_) {
      // On garde la durée du fichier si le parsing échoue (ex: format différent)
    }

    return Track(
      name: lines[0],
      bounds: lines[1],
      start: startStr,
      end: endStr,
      duree: duree,
      moving: int.tryParse(lines[5]) ?? 0,
      distance: double.tryParse(lines[6]) ?? 0.0,
      vignetteBase64: foundVignette,
    );
  }
}
