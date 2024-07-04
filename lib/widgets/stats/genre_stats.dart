import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/genres_mapping.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/stats/legend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiver/iterables.dart';

class GenreStats extends StatelessWidget {
  const GenreStats(this.libraryEntries, this.filter, {super.key});

  final Iterable<LibraryEntry> libraryEntries;
  final LibraryFilter filter;

  @override
  Widget build(BuildContext context) {
    final genreGroup = filter.genreGroup ?? Genres.groupOfGenre(filter.genre);
    final selectedGenre = filter.genre;
    if (libraryEntries.isEmpty || genreGroup == null) {
      // genreGroup == 'Unknown') {

      return Container();
    }

    final genresPop = {};
    for (final entry in libraryEntries) {
      if (entry.digest.espyGenres.isEmpty) {
        genresPop[unknownLabel] = (genresPop[unknownLabel] ?? 0) + 1;
      }
      for (final genre in entry.digest.espyGenres) {
        if (Genres.groupOfGenre(genre) == genreGroup) {
          genresPop[genre] = (genresPop[genre] ?? 0) + 1;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 240,
        child: Row(
          children: [
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LegendKey(
                    color: Colors.white,
                    text: selectedGenre ?? genreGroup,
                    isSquare: true,
                    icon: Icons.keyboard_arrow_left,
                    onTap: () {
                      if (filter.genre != null) {
                        filter.genre = null;
                      } else {
                        filter.genreGroup = null;
                      }
                      context.read<LibraryFilterModel>().filter = filter;
                    },
                  ),
                  const SizedBox(height: 4),
                  for (final genre in enumerate(
                      Genres.genresInGroup(genreGroup) ?? [unknownLabel]))
                    if (genresPop[genre.value] != null)
                      LegendKey(
                        color: legendColors[genre.index % legendColors.length],
                        text: genre.value,
                        isSquare: true,
                        onTap: () {
                          final updated =
                              filter.add(LibraryFilter(genre: genre.value));
                          context.read<LibraryFilterModel>().filter = updated;
                        },
                      ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: [
                    for (final genre in enumerate(
                        Genres.genresInGroup(genreGroup) ?? [unknownLabel]))
                      if (genresPop[genre.value] != null)
                        PieChartSectionData(
                          color:
                              legendColors[genre.index % legendColors.length],
                          value: genresPop[genre.value],
                          title: '${genresPop[genre.value]}',
                          radius: 60,
                          titleStyle: sliceStyle,
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const sliceStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
);

const unknownLabel = '';
