import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../components/routs.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? vignetteBytes;
    if (track.vignetteBase64 != null) {
      try {
        vignetteBytes = base64Decode(track.vignetteBase64!);
      } catch (e) {
        debugPrint("Error decoding vignette: $e");
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 2,
      color: track.isDone ? Colors.blue[50] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Vignette carrée à gauche
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: vignetteBytes != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    vignetteBytes,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
                    : const Icon(Icons.map_outlined, color: Colors.grey, size: 40),
              ),
              const SizedBox(width: 15),
              // Informations de la trace
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.brown,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            track.start,
                            style: const TextStyle(color: Colors.black87, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Ligne Distance et Temps de marche
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.straighten, size: 13, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text(
                              '${track.distance.toStringAsFixed(2)} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.directions_walk, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                              affTime(track.moving.toString(),false),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Indicateur de sélection
              if (track.isDone)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.check_circle, color: Colors.blue, size: 24),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
