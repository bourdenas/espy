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
      child: ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        children: [
          GenreStats(libraryEntries),
          const SizedBox(width: 64),
          RatingStats(libraryEntries),
          const SizedBox(width: 64),
          KeywordCloud(libraryEntries),
        ],
      ),
    );
  }
}
