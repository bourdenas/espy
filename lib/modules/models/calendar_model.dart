import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/calendar.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class CalendarModel extends ChangeNotifier {
  List<GameDigest> gamesIn(int year) {
    return _calendar?['$year'] ?? [];
  }

  Map<String, List<GameDigest>>? _calendar;

  Future<CalendarModel> load() async {
    if (_calendar == null) {
      final doc = await FirebaseFirestore.instance
          .collection('espy')
          .doc('calendar')
          .withConverter<Calendar>(
            fromFirestore: (snapshot, _) => Calendar.fromJson(snapshot.data()!),
            toFirestore: (calendar, _) => {},
          )
          .get();

      final calendar = doc.data() ?? const Calendar();
      _calendar = {};
      for (final year in calendar.years) {
        _calendar![year.label] = year.games;
      }
    }

    return this;
  }
}
