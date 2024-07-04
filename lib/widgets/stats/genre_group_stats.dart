import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/genres_mapping.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/stats/legend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiver/iterables.dart';

class GenreGroupStats extends StatelessWidget {
  const GenreGroupStats(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  Widget build(BuildContext context) {
    if (libraryEntries.isEmpty) {
      return Container();
    }

    final genreGroupsPop = {};
    for (final entry in libraryEntries) {
      if (entry.digest.espyGenres.isEmpty) {
        genreGroupsPop[unknownLabel] = (genreGroupsPop[unknownLabel] ?? 0) + 1;
      }
      for (final genre in entry.digest.espyGenres) {
        final group = Genres.groupOfGenre(genre) ?? unknownLabel;
        genreGroupsPop[group] = (genreGroupsPop[group] ?? 0) + 1;
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
                  for (final group in enumerate(Genres.groups))
                    if (genreGroupsPop[group.value] != null)
                      LegendKey(
                        color: legendColors[group.value],
                        text: group.value,
                        isSquare: true,
                        onTap: () {
                          final filter =
                              context.read<LibraryFilterModel>().filter;
                          final updated = filter
                              .add(LibraryFilter(genreGroup: group.value));
                          context.read<LibraryFilterModel>().filter = updated;
                        },
                      ),
                  if (genreGroupsPop[unknownLabel] != null)
                    LegendKey(
                      color: Colors.grey,
                      text: unknownLabel,
                      isSquare: true,
                      onTap: () {
                        final filter =
                            context.read<LibraryFilterModel>().filter;
                        final updated =
                            filter.add(LibraryFilter(genreGroup: unknownLabel));
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
                    for (final group in enumerate(Genres.groups))
                      if (genreGroupsPop[group.value] != null)
                        PieChartSectionData(
                          color: legendColors[group.value],
                          value: genreGroupsPop[group.value],
                          title: '${genreGroupsPop[group.value]}',
                          radius: 60,
                          titleStyle: sliceStyle,
                        ),
                    if (genreGroupsPop[unknownLabel] != null)
                      PieChartSectionData(
                        color: Colors.grey,
                        value: genreGroupsPop[unknownLabel],
                        title: '${genreGroupsPop[unknownLabel]}',
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

const unknownLabel = 'Unknown';
