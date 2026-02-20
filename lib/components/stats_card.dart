import 'dart:math';

import 'package:flutter/material.dart';
import '../models/location_service.dart';
import 'routs.dart';

class StatsCard extends StatelessWidget {
  final LocaData locaData;
  final String target;

  const StatsCard({super.key, required this.locaData, required this.target});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${ol('to')} $target",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Transform.rotate(
              angle: (locaData.angle * (pi / 180)),
              child: Icon(
                Icons.navigation,
                size: 60,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              children: [
                _buildStatItem(context, locaData.speed, ol('speed')),
                _buildStatItem(context, locaData.travelledLength, ol('distance')),
                _buildStatItem(context, locaData.duree, ol('duration')),
                _buildStatItem(context, locaData.altitude, ol('altitude')),
                _buildStatItem(context, locaData.distanceTarget, ol('target_distance')),
                _buildStatItem(context, locaData.bearingToTarget, ol('target_bearing')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
      ],
    );
  }
}
