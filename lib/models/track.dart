
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

    return Track(
      name: lines[0],
      bounds: lines[1],
      start: lines[2],
      end: lines[3],
      duree: int.tryParse(lines[4]) ?? 0,
      moving: int.tryParse(lines[5]) ?? 0,
      distance: double.tryParse(lines[6]) ?? 0.0,
      vignetteBase64: foundVignette,
    );
  }
}
