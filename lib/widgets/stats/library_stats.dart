import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/widgets/stats/genre_stats.dart';
import 'package:espy/widgets/stats/keyword_cloud.dart';
import 'package:espy/widgets/stats/rating_stats.dart';
import 'package:flutter/material.dart';

class LibraryStats extends StatelessWidget {
  const LibraryStats(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Container(
        alignment: AlignmentDirectional.topStart,
        child: ListView(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          children: [
            const SizedBox(width: 8),
            GenreStats(libraryEntries),
            const SizedBox(width: 64),
            KeywordCloud(libraryEntries),
            const SizedBox(width: 64),
            RatingStats(libraryEntries),
          ],
        ),
      ),
    );
  }
}
