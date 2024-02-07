import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../Models/run.dart';

class FirebaseConnection {
  Future<void> addRegister(Run run) async {
    await Firebase.initializeApp();
    final firebase = FirebaseFirestore.instance;

    await firebase
        .collection('run')
        .doc()
        .withConverter(
          fromFirestore: _fromFirestore,
          toFirestore: _toFirestore,
        )
        .set(run);
  }

  Run _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, _) {
    return Run(
      distance: doc['distance'],
      time: doc['time'],
      pace: doc['pace'],
      laps: doc['laps'],
      datetime: doc['datetime'],
    );
  }

  Map<String, dynamic> _toFirestore(Run run, _) {
    return {
      'distance': run.distance,
      'time': run.time,
      'pace': run.pace,
      'laps': run.laps,
      'datetime': run.datetime,
    };
  }
}
