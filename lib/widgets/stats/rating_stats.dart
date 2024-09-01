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
  static const unknownLabel = 'Unknown';

  final ratingPops = <String, int>{};
  String? selectedGenre;

  @override
  void initState() {
    super.initState();

    final filter = context.read<LibraryFilterModel>().filter;
    buildPops(filter);
  }

  void buildPops(LibraryFilter filter) {
    ratingPops.clear();

    // Build Genre histograms.
    for (final entry in widget.libraryEntries.where((e) => filter.pass(e))) {
      final title = entry.scores.title;
      ratingPops[title] = (ratingPops[title] ?? 0) + 1;
    }
    ratingPops[unknownLabel] = 0;
  }

  @override
  Widget build(BuildContext context) {
    final refinement = context.watch<RefinementModel>().refinement;
    setState(() => buildPops(refinement));

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
              for (final item
                  in enumerate(scoreTitles).take(scoreTitles.length - 1))
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
          color: ratingClassIndex < 5 ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.zero,
          borderDashArray: ratingClassIndex == 5 ? [4, 4] : null,
          width: 32,
          borderSide: ratingClassIndex == 5
              ? const BorderSide(color: Colors.amber, width: 2.0)
              : null,
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
