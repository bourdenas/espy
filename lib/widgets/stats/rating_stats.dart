import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/scores.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiver/iterables.dart';

class RatingStats extends StatefulWidget {
  const RatingStats(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  State<RatingStats> createState() => _GenreStatsState();
}

class _GenreStatsState extends State<RatingStats> {
  static const unknownLabel = 'Unrated';

  final ratingPops = <String, int>{};
  int unknownPops = 0;
  String? selectedGenre;

  @override
  void initState() {
    super.initState();

    final filter = context.read<LibraryFilterModel>().filter;
    buildPops(filter);
  }

  void buildPops(LibraryFilter filter) {
    ratingPops.clear();
    unknownPops = 0;

    // Build Genre histograms.
    for (final entry in widget.libraryEntries) {
      if (entry.scores.espyScore == null) {
        unknownPops += 1;
      }
      final title = entry.scores.title;
      ratingPops[title] = (ratingPops[title] ?? 0) + 1;
    }
    ratingPops[unknownLabel] = unknownPops;
  }

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<LibraryFilterModel>().filter;
    setState(() => buildPops(filter));

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 240,
        width: 360,
        child: BarChart(
          BarChartData(
            maxY:
                (((ratingPops.values.toList()..sort()).last / 10.0).ceil() * 10)
                    .toDouble(),
            barTouchData: BarTouchData(
              enabled: false,
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: getTitles,
                  reservedSize: 32,
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 32,
                  showTitles: true,
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (final item in enumerate(scoreTitles))
                buildRatingBar(
                    item.index, ratingPops[item.value]?.toDouble() ?? 0)
            ],
            groupsSpace: 2,
            gridData: const FlGridData(show: false),
          ),
        ),
      ),
    );
  }

  BarChartGroupData buildRatingBar(int ratingClassIndex, double y) {
    return BarChartGroupData(
      x: ratingClassIndex,
      barsSpace: 0,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.amber,
          borderRadius: BorderRadius.zero,
          // borderDashArray: x >= 4 ? [4, 4] : null,
          width: 32,
          // borderSide: BorderSide(color: widget.barColor, width: 2.0),
        ),
      ],
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    final symbols = ['⭐', '👍', '✔️', '🤨', '👎', '🤷‍♂️'];

    Widget text = Text(
      symbols[value.toInt()],
      style: style,
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: text,
    );
  }
}
