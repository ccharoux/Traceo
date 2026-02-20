import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';

import '../components/routs.dart';
import '../components/stats_row.dart';
import '../models/location_service.dart';
import '../models/home_service.dart';
import '../models/settings_state.dart';

class StatsScreen extends StatelessWidget {
  static const String id = '/stats';

  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocaData, HomeService, SettingsState>(
      builder: (context, locaData, homeService, settings, child) {
        String dep;
        if (locaData.startTime.isNotEmpty) {
          final parts = locaData.startTime.split(' ');
          final timePart = parts.length > 1 ? parts[1] : '';
          final datePart = parts.isNotEmpty ? parts[0] : '';
          dep =
              '${ol('departure')} ${timePart.substring(0, timePart.length > 8 ? 8 : timePart.length)} - $datePart';
        } else {
          dep = ol('departure');
        }

        final String walkingTime = locaData.walkingTime.toString();

        double currentHeading = 0.0;
        
        if (locaData.trace.length > 1 && locaData.speedValue > 1.0) { 
             final p1 = locaData.trace[locaData.trace.length - 2];
             final p2 = locaData.trace.last;
             currentHeading = Geolocator.bearingBetween(
               p1.latitude, p1.longitude,
               p2.latitude, p2.longitude
             );
             if (currentHeading < 0) currentHeading += 360;
        } else if (locaData.trace.isNotEmpty) {
             currentHeading = locaData.trace.last.heading;
        }

        double targetBearing = 0.0;
        double targetDistMeters = 0.0;
        if (locaData.activeTarget != null && locaData.trace.isNotEmpty) {
           final p = locaData.trace.last;
           double tLat = locaData.activeTarget!.latitude;
           double tLon = locaData.activeTarget!.longitude;

           if (locaData.activeTarget!.isRoute && locaData.activeTarget!.routePoints != null) {
             final wp = locaData.activeTarget!.routePoints![locaData.currentWaypointIndex];
             tLat = wp['lat'];
             tLon = wp['lon'];
           }

           targetBearing = Geolocator.bearingBetween(
             p.latitude, p.longitude,
             tLat, tLon
           );
           if (targetBearing < 0) targetBearing += 360;
           
           targetDistMeters = Geolocator.distanceBetween(
             p.latitude, p.longitude,
             tLat, tLon
           );
        }

        double relativeAngle = targetBearing - currentHeading;
        if (relativeAngle > 180) relativeAngle -= 360;
        if (relativeAngle < -180) relativeAngle += 360;

        final scaffoldMessenger = ScaffoldMessenger.of(context);

        String destinationText = locaData.activeTarget?.name ?? ol('start_point');
        if (locaData.activeTarget != null && locaData.activeTarget!.isRoute && locaData.activeTarget!.routePoints != null) {
          final wpName = locaData.activeTarget!.routePoints![locaData.currentWaypointIndex]['name'];
          destinationText = "${locaData.activeTarget!.name} par $wpName";
        }

        // Préparation des formats selon les métriques
        final String formattedTargetDist = settings.formatDistance(targetDistMeters);
        final String formattedTraveled = settings.formatDistance(locaData.travelledLengthDble);
        final String formattedSpeed = settings.formatSpeed(locaData.speedValue / 3.6);
        
        // Altitude : mètres ou pieds selon l'unité
        final double currentAltMeters = locaData.trace.isNotEmpty ? locaData.trace.last.altitude : 0.0;
        final String formattedAltitude = settings.formatAltitude(currentAltMeters);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.brown,
            foregroundColor: Colors.white,
            title: Text(
              (locaData.activeTarget?.isAerodrome ?? true)
                  ? "${ol('flying_to')} ${locaData.activeTarget?.name}"
                  : ol('trip_stats')
            ),
          ),
          body: SingleChildScrollView(
            child: Container(
              color: const Color(0xFFF5F5DC), 
              constraints:
                  BoxConstraints(minHeight: MediaQuery.of(context).size.height),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                   if (locaData.activeTarget?.isAerodrome == true &&
                       locaData.activeTarget?.vacUrl != null &&
                       locaData.activeTarget!.vacUrl!.isNotEmpty)
                     Align(
                       alignment: Alignment.topLeft,
                       child: IconButton(
                         icon: const Icon(Icons.description, color: Colors.green, size: 30),
                         tooltip: ol('vac_url_title'),
                         onPressed: () async {
                           String path = locaData.activeTarget!.vacUrl!;
                           if (path.startsWith('http')) {
                             final url = Uri.parse(path);
                             try {
                               if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                 throw 'Could not launch $url';
                               }
                             } catch (e) {
                               scaffoldMessenger.showSnackBar(
                                 SnackBar(content: Text("${ol('error_prefix')} $e")),
                               );
                             }
                           } else {
                             final result = await OpenFilex.open(path);
                             if (result.type != ResultType.done) {
                               scaffoldMessenger.showSnackBar(
                                 SnackBar(content: Text("${ol('error_prefix')} ${result.message}")),
                               );
                             }
                           }
                         },
                       ),
                     ),
                  Text(
                    dep,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ol('destination'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.brown,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    destinationText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StatsRow(
                    firstElem: ol('straight_distance'),
                    secondElem: ol('traveled'),
                    thirdElem: formattedTargetDist,
                    fourthElem: formattedTraveled,
                    colour: Colors
                        .brown,
                    fontSize: 20,
                  ),
                  StatsRow(
                    firstElem: ol('altitude'),
                    secondElem: ol('speed'),
                    thirdElem: formattedAltitude,
                    fourthElem: formattedSpeed,
                    fontSize: 20,
                    colour: Colors.brown,
                  ),
                  StatsRow(
                    firstElem: ol('target_bearing'),
                    secondElem: ol('course_followed'),
                    thirdElem: '${targetBearing.toStringAsFixed(0)}°',
                    fourthElem: '${currentHeading.toStringAsFixed(0)}°',
                    colour: Colors.brown,
                    fontSize: 20,
                  ),
                  StatsRow(
                    firstElem: ol('duration'),
                    secondElem: ol('moving'),
                    thirdElem:
                        affTime((locaData.dureeInt ?? 0).toString(), true),
                    fourthElem: affTime(walkingTime, true),
                    colour: Colors.brown,
                    fontSize: 20,
                  ),
                  const SizedBox(height: 30),

                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CustomPaint(
                            painter: MyPainter(angleValue: relativeAngle.toInt()),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          relativeAngle.toInt() == 0
                              ? "OK"
                              : "${relativeAngle.abs().toStringAsFixed(0)}° ${relativeAngle > 0 ? ol('right') : ol('left')}",
                          style: const TextStyle(
                              color: Colors.brown,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MyPainter extends CustomPainter {
  final int angleValue;

  MyPainter({required this.angleValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintCircle = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 2, paintCircle);

    final paintVertical = Paint()
      ..color = Colors.brown
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
        center, Offset(center.dx, 5),
        paintVertical);

    double angleRad = (angleValue - 90) * math.pi / 180;

    final paintNeedle = Paint()
      ..color = Colors.red
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final needleLen = radius - 5;
    final endX = center.dx + needleLen * math.cos(angleRad);
    final endY = center.dy + needleLen * math.sin(angleRad);

    canvas.drawLine(center, Offset(endX, endY), paintNeedle);

    canvas.drawCircle(center, 4, paintVertical..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return (oldDelegate as MyPainter).angleValue != angleValue;
  }
}
