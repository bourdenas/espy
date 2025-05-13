import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/widgets/stats/category_stats.dart';
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
      width: 480,
      child: Container(
        alignment: AlignmentDirectional.topCenter,
        child: ListView(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: [
            const SizedBox(height: 8),
            CategoryStats(),
            const SizedBox(height: 28),
            GenreStats(libraryEntries),
            const SizedBox(height: 24),
            KeywordCloud(libraryEntries),
            const SizedBox(height: 28),
            RatingStats(libraryEntries),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
