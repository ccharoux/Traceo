import 'package:flutter/material.dart';

class TrackingFab extends StatelessWidget {
  final bool isTracking;
  final bool isSimulating;
  final VoidCallback onStartTracking;
  final VoidCallback onStopTracking;
  final VoidCallback onStopSimulation;

  const TrackingFab({
    super.key,
    required this.isTracking,
    required this.isSimulating,
    required this.onStartTracking,
    required this.onStopTracking,
    required this.onStopSimulation,
  });

  @override
  Widget build(BuildContext context) {
    if (isSimulating) {
      return FloatingActionButton(
        onPressed: onStopSimulation,
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.stop_circle_outlined),
      );
    }
    return FloatingActionButton(
      onPressed: isTracking ? onStopTracking : onStartTracking,
      backgroundColor: isTracking ? Colors.redAccent : Colors.greenAccent,
      child: Icon(isTracking ? Icons.stop : Icons.play_arrow),
    );
  }
}
