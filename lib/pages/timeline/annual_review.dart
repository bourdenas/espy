import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/timeline.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AnnualReview extends StatelessWidget {
  const AnnualReview({super.key, required this.year});

  final String year;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final today = DateFormat('d MMM').format(DateTime.now());

    return FutureBuilder(
      future: context.watch<TimelineModel>().gamesIn(year),
      builder: (BuildContext context, AsyncSnapshot<AnnualReviewDoc> snapshot) {
        return snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData
            ? timeline(today, snapshot.data!, isMobile)
            : Container();
      },
    );
  }

  Widget timeline(String today, AnnualReviewDoc review, bool isMobile) {
    final groups = [
      ('Releases', review.releases),
      if (review.indies.isNotEmpty) ('Indies', review.indies),
      if (review.earlyAccess.isNotEmpty) ('Early Access', review.earlyAccess),
      if (review.debug.isNotEmpty) ('Debug', review.debug),
    ];

    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        for (final (label, digests) in groups)
          TileShelve(
            title: '$label (${digests.length})',
            color: Colors.grey,
            entries:
                digests.map((digest) => LibraryEntry.fromGameDigest(digest)),
          ),
      ],
    );
  }
}
