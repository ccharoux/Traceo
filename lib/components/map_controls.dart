import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final VoidCallback onToggleMapView;
  final bool isTopDownView;
  final bool isTracking;

  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.onToggleMapView,
    required this.isTopDownView,
    required this.isTracking,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: Column(
        children: [
          _buildControlButton(context, Icons.zoom_in, onZoomIn),
          const SizedBox(height: 8),
          _buildControlButton(context, Icons.zoom_out, onZoomOut),
          const SizedBox(height: 8),
          _buildControlButton(context, Icons.my_location, onMyLocation),
          if (isTracking)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildControlButton(
                context,
                isTopDownView ? Icons.explore_off : Icons.explore,
                onToggleMapView,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton(BuildContext context, IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.brown[700]),
        ),
      ),
    );
  }
}
