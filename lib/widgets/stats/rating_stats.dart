import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/scores.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
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
    // Get a copy of the currect filter.
    final filter = context.watch<FilterModel>().filter.add(LibraryFilter());
    final selectedScore = filter.score;

    // Remove score from filter to make the bar chart stable to selections.
    filter.score = null;
    final model = FilterModel.create(filter, context.read<AppConfigModel>());

    // Build scores histograms.
    final ratingPops = <String, int>{};
    for (final entry in model.processLibraryEntries(libraryEntries)) {
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

                  if (context.read<FilterModel>().filter.score !=
                      filter.score) {
                    context.read<FilterModel>().add(filter);
                  } else {
                    context.read<FilterModel>().subtract(filter);
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
    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Icon(icons[value.toInt()]),
    );
  }
}

const ratings = ['Excellent', 'Great', 'Good', 'Mixed', 'Bad'];
const icons = [
  Icons.star,
  Icons.thumb_up,
  Icons.check,
  Icons.sentiment_dissatisfied,
  Icons.thumb_down
];
