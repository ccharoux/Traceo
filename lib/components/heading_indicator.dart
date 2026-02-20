import 'dart:math' as math;
import 'package:flutter/material.dart';

// CustomPainter to draw the compass, inspired by the one in stats_screen.
class CompassPainter extends CustomPainter {
  final double angleValue; // The angle difference in degrees

  CompassPainter({required this.angleValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw the background circle for better visibility
    final paintCircle = Paint()
      ..color = Colors.brown.withAlpha(200) // Semi-transparent background
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paintCircle);

    final paintCircleStroke = Paint()
      ..color = Colors.white.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 2, paintCircleStroke);


    // 2. Draw the vertical line representing the user's current heading (always UP)
    final paintHeading = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - radius + 5), // Pointing up
      paintHeading
    );

    // 3. Draw the needle pointing to the target's bearing
    // angleValue is relative to the user's heading. 0 means target is straight ahead.
    // Canvas 0 degrees is East (3 o'clock). We offset by -90 to make 0 degrees North (12 o'clock).
    double angleRad = (angleValue - 90) * math.pi / 180;

    final paintNeedle = Paint()
      ..color = Colors.red[400]!
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final needleLen = radius - 5;
    final endX = center.dx + needleLen * math.cos(angleRad);
    final endY = center.dy + needleLen * math.sin(angleRad);

    canvas.drawLine(center, Offset(endX, endY), paintNeedle);
    
    // Draw a center dot
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return (oldDelegate as CompassPainter).angleValue != angleValue;
  }
}


class HeadingIndicator extends StatelessWidget {
  final double bearingToTarget;
  final double currentHeading;

  const HeadingIndicator({
    super.key,
    required this.bearingToTarget,
    required this.currentHeading,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the difference between the bearing to target and current heading
    double angleDiff = (bearingToTarget - currentHeading);
    
    // Normalize angle to be between -180 and 180 degrees
    if (angleDiff > 180) angleDiff -= 360;
    if (angleDiff < -180) angleDiff += 360;
    
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0), // Space from the top edge
        child: SizedBox(
            width: 100, // Size of the compass
            height: 100,
            child: CustomPaint(
              painter: CompassPainter(angleValue: angleDiff),
            ),
        ),
      ),
    );
  }
}
