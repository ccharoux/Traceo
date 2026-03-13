import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  final String firstElem;
  final Color colour;
  final String secondElem;
  final String thirdElem;
  final String fourthElem;
  final double fontSize;

  const StatsRow({
    required this.firstElem,
    required this.colour,
    required this.secondElem,
    required this.thirdElem,
    required this.fourthElem,
    required this.fontSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  firstElem,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize * 0.8, // Slightly smaller for labels
                    color: colour,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  secondElem,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize * 0.8,
                    color: colour,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  thirdElem,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  fourthElem,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
