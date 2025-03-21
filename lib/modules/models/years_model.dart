import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/calendar.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class YearsModel extends ChangeNotifier {
  Future<AnnualReviewDoc> gamesIn(String year) async {
    final cache = _annualReviews[year];
    if (cache != null) {
      return cache;
    }

    final doc = await FirebaseFirestore.instance
        .collection('espy')
        .doc(year)
        .withConverter<AnnualReviewDoc>(
          fromFirestore: (snapshot, _) =>
              AnnualReviewDoc.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => {},
        )
        .get();

    final review = doc.data() ?? const AnnualReviewDoc();
    _annualReviews[year] = review;

    return review;
  }

  Future<List<AnnualReviewDoc>> getYears(Iterable<String> years) async {
    final reviews = <AnnualReviewDoc>[];
    for (final year in years) {
      reviews.add(await gamesIn(year));
    }
    return reviews;
  }

  final Map<String, AnnualReviewDoc> _annualReviews = {};
}
