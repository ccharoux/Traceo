import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/routs.dart';
import '../components/track_tile.dart';
import '../models/track_data.dart';

class TrackView extends StatelessWidget {
  final bool isSelectionMode;
  final bool isArchiveView;

  const TrackView({
    super.key,
    this.isSelectionMode = false,
    this.isArchiveView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackData>(
      builder: (context, trackData, child) {
        if (trackData.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final tracks = isArchiveView ? trackData.archivedTracks : trackData.tracks;

        if (tracks.isEmpty) {
          return Center(
            child: Text(
              isArchiveView ? ol('no_archives_found') : ol('no_tracks_found'),
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero, // Force la liste à ignorer les marges système
          itemCount: tracks.length + 1, // +1 pour l'espace en bas
          itemBuilder: (context, index) {
            // Ajoute un espaceur à la fin pour que le dernier élément ne soit pas caché
            if (index == tracks.length) {
              return const SizedBox(height: 100);
            }
            
            final track = tracks[index];
            return TrackTile(
              track: track,
              onTap: () {
                if (isSelectionMode) {
                  Navigator.of(context).pop(track.name);
                } else {
                  if (isArchiveView) {
                    trackData.toggleArchiveDone(index);
                  } else {
                    trackData.toggleDone(index);
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}
