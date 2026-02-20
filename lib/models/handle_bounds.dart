// Fichier : lib/models/handle_bounds.dart

import 'dart:math'; // Importer la bibliothèque math pour min et max
import 'package:google_maps_flutter/google_maps_flutter.dart';
// Supposant que `logger` est défini ici.

class HandleBounds {
  double minLat = 90.0;
  double minLng = 180.0;
  double maxLat = -90.0;
  double maxLng = -180.0;

  /// Met à jour les limites actuelles en analysant une chaîne de caractères
  /// au format "minLat minLng maxLat maxLng".
  void updateBoundsFromString(String boundsString) {
    final parts = boundsString
        .split(' ')
        .map((p) => double.tryParse(p))
        .toList();

    if (parts.length == 4 && parts.every((p) => p != null)) {
      final newMinLat = parts[0]!;
      final newMinLng = parts[1]!;
      final newMaxLat = parts[2]!;
      final newMaxLng = parts[3]!;

      minLat = min(minLat, newMinLat);
      minLng = min(minLng, newMinLng);
      maxLat = max(maxLat, newMaxLat);
      maxLng = max(maxLng, newMaxLng);
    }
  }
  String getBoundsString() {
    return '$minLat $minLng $maxLat $maxLng';
  }
  /// Prend deux boîtes englobantes sous forme de chaînes "minLat,minLng,maxLat,maxLng"
  /// et retourne une nouvelle chaîne représentant la boîte qui englobe les deux.
  String compareBounds(String bounds1, String bounds2) {
    try {
      List<double> b1 = bounds1.split(',').map(double.parse).toList();
      List<double> b2 = bounds2.split(',').map(double.parse).toList();

      // Ajout d'une vérification pour la robustesse
      if (b1.length != 4 || b2.length != 4) {
        throw const FormatException("Les chaînes de limites doivent contenir 4 nombres.");
      }

      double minLat = min(b1[0], b2[0]);
      double minLng = min(b1[1], b2[1]);
      double maxLat = max(b1[2], b2[2]);
      double maxLng = max(b1[3], b2[3]);

      return '$minLat,$minLng,$maxLat,$maxLng';
    } catch (e) {
      print(
          "Erreur dans compareBounds: $e. Bounds1: '$bounds1', Bounds2: '$bounds2'");
      return bounds2;
    }
  }

  /// Calcule et retourne la boîte englobante (LatLngBounds) à partir d'une liste de positions GPS.
  /// Lance une exception si la liste de points est vide pour éviter les erreurs.
  static LatLngBounds fromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      // Il est préférable de lancer une erreur claire plutôt que de retourner une valeur invalide.
      throw ArgumentError("La liste de points ne peut pas être vide pour calculer les limites.");
    }

    // On initialise les valeurs avec le premier point de la liste.
    double minLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLat = points.first.latitude;
    double maxLng = points.first.longitude;

    // On parcourt le reste de la liste pour trouver les extrêmes.
    for (final point in points) {
      minLat = min(minLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLat = max(maxLat, point.latitude);
      maxLng = max(maxLng, point.longitude);
    }

    // On construit et retourne l'objet LatLngBounds.
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
