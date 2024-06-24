import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/genres_mapping.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LibraryStats extends StatelessWidget {
  const LibraryStats(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  Widget build(BuildContext context) {
    if (libraryEntries.isEmpty) {
      return Container();
    }

    final genreGroupsPop = {};
    for (final entry in libraryEntries) {
      if (entry.digest.espyGenres.isEmpty) {
        genreGroupsPop['Unknown'] = (genreGroupsPop['Unknown'] ?? 0) + 1;
      }
      for (final genre in entry.digest.espyGenres) {
        genreGroupsPop[Genres.groupOfGenre(genre) ?? 'Unknown'] =
            (genreGroupsPop[Genres.groupOfGenre(genre) ?? 'Unknown'] ?? 0) + 1;
      }
    }

    const colors = {
      'Adventure': Colors.blue,
      'RPG': Colors.deepOrange,
      'Strategy': Colors.orange,
      'Shooter': Colors.green,
      'Platformer': Colors.deepPurple,
      'Simulator': Colors.teal,
      'Arcade': Colors.lightGreen,
      'Casual': Colors.pink,
      'Unknown': Colors.grey,
    };

    const sliceStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Colors.black, blurRadius: 2)],
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 240,
        child: Row(
          children: [
            Column(
              // mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in Genres.groups)
                  if (genreGroupsPop[group] != null)
                    Indicator(
                      color: colors[group] ?? Colors.grey,
                      text: group,
                      isSquare: true,
                    ),
                if (genreGroupsPop['Unknown'] != null)
                  Indicator(
                    color: colors['Unknown']!,
                    text: 'Unknown',
                    isSquare: true,
                  ),
              ],
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
                    for (final group in Genres.groups)
                      if (genreGroupsPop[group] != null)
                        PieChartSectionData(
                          color: colors[group],
                          value: genreGroupsPop[group],
                          title: '${genreGroupsPop[group]}',
                          radius: 60,
                          titleStyle: sliceStyle,
                        ),
                    if (genreGroupsPop['Unknown'] != null)
                      PieChartSectionData(
                        color: colors['Unknown'],
                        value: genreGroupsPop['Unknown'],
                        title: '${genreGroupsPop["Unknown"]}',
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

class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor,
  });
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(
          width: 6,
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        )
      ],
    );
  }
}
