import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/track.dart';

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
                        fontSize: 16,
                        color: Colors.brown,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            track.start,
                            style: const TextStyle(color: Colors.black87, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.straighten, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          '${track.distance.toStringAsFixed(2)} km',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Indicateur de sélection (optionnel)
              if (track.isDone)
                const Icon(Icons.check_circle, color: Colors.blue, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
