import 'package:cloud_firestore/cloud_firestore.dart';

class Run {
  Run({
    required this.distance,
    required this.time,
    required this.pace,
    required this.laps,
    required this.datetime,
  });

  double distance;
  String time;
  String pace;
  int laps;
  Timestamp datetime;
}
