import 'package:flutter/material.dart';
import 'dart:math' as math;

class CompassWidget extends StatelessWidget {
  final double heading;

  const CompassWidget({super.key, required this.heading});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (heading * (math.pi / 180) * -1),
      child: Image.asset(
        'assets/compass.png',
        width: 100,
        height: 100,
      ),
    );
  }
}
