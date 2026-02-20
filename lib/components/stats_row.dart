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
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                firstElem,
                style: TextStyle(
                  fontSize: fontSize,
                  color: colour,
                ),
              ),
              Text(
                secondElem,
                style: TextStyle(
                  fontSize: fontSize,
                  color: colour,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                thirdElem,
                style: TextStyle(color: Colors.black, fontSize: fontSize),
              ),
              Text(
                fourthElem,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
