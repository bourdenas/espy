import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/scores.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiver/iterables.dart';

class RatingStats extends StatelessWidget {
  const RatingStats(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  Widget build(BuildContext context) {
    // Get a copy of the currect refinement.
    final refinement =
        context.watch<RefinementModel>().refinement.add(LibraryFilter());
    final selectedScore = refinement.score;
    // Remove score from refinement to make the bar chart stable to selections.
    refinement.score = null;

    // Build scores histograms.
    final ratingPops = <String, int>{};
    for (final entry in libraryEntries.where((e) => refinement.pass(e))) {
      final title = entry.scores.title;
      if (title != 'Unknown') {
        ratingPops[title] = (ratingPops[title] ?? 0) + 1;
      }
    }

    if (ratingPops.isEmpty) {
      return Container();
    }

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
                enabled: true,
                touchCallback:
                    (FlTouchEvent event, BarTouchResponse? barTouchResponse) {
                  if (!event.isInterestedForInteractions ||
                      event is! FlTapDownEvent ||
                      barTouchResponse == null ||
                      barTouchResponse.spot == null) {
                    return;
                  }

                  final filter = LibraryFilter(
                      score:
                          ratings[barTouchResponse.spot!.touchedBarGroupIndex]);

                  if (context.read<RefinementModel>().refinement.score !=
                      filter.score) {
                    context.read<RefinementModel>().add(filter);
                  } else {
                    context.read<RefinementModel>().subtract(filter);
                  }
                }),
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
                    item.index,
                    ratingPops[item.value]?.toDouble() ?? 0,
                    item.value == selectedScore)
            ],
            groupsSpace: 2,
            gridData: const FlGridData(show: false),
          ),
        ),
      ),
    );
  }

  BarChartGroupData buildRatingBar(
      int ratingClassIndex, double y, bool selected) {
    return BarChartGroupData(
      x: ratingClassIndex,
      barsSpace: 0,
      barRods: [
        BarChartRodData(
          toY: y,
          color: ratingClassIndex < 5
              ? (selected ? Colors.lightBlue : Colors.amber)
              : Colors.transparent,
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

    Widget text = Text(
      labels[value.toInt()],
      style: style,
    );

    return SideTitleWidget(
      meta: meta,
      space: 16,
      child: text,
    );
  }
}

const ratings = ['Excellent', 'Great', 'Good', 'Mixed', 'Bad'];
const labels = ['⭐', '👍', '✔️', '🤨', '👎'];
