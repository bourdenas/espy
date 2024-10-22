import 'package:espy/widgets/stats/legend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:quiver/iterables.dart';

class EspyPieChart extends StatelessWidget {
  const EspyPieChart(
    this.items, {
    super.key,
    this.itemPops,
    this.selectedItem,
    this.palette,
    this.onItemTap,
    this.backLabel,
    this.onBack,
  });

  final List<String> items;
  final Map<String, int>? itemPops;
  final String? selectedItem;
  final List<Color?>? palette;
  final void Function(String selectedItem)? onItemTap;
  final String? backLabel;
  final void Function()? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 240,
        child: Row(
          children: [
            Legend(
              items,
              itemPops: itemPops,
              selectedItem: selectedItem,
              palette: palette ?? defaultPalette,
              onItemTap: onItemTap,
              backLabel: backLabel,
              onBack: onBack,
            ),
            if (itemPops?.isNotEmpty != null) chart(),
          ],
        ),
      ),
    );
  }

  AspectRatio chart() {
    return AspectRatio(
      aspectRatio: 1,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback:
                (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
              if (!event.isInterestedForInteractions ||
                  event is! FlTapDownEvent ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                return;
              }

              int index = pieTouchResponse.touchedSection!.touchedSectionIndex;
              if (index >= 0 && index < items.length && onItemTap != null) {
                for (final item in enumerate(items)) {
                  if (itemPops![item.value] == null) {
                    ++index;
                  }
                  if (index == item.index) {
                    onItemTap!(items[index]);
                    break;
                  }
                }
              }
            },
          ),
          borderData: FlBorderData(
            show: false,
          ),
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          startDegreeOffset: -90,
          sections: [
            for (final item in enumerate(items))
              if (itemPops![item.value] != null)
                PieChartSectionData(
                  color: palette?[item.index % items.length] ??
                      defaultPalette[item.index % items.length],
                  value: itemPops![item.value] as double?,
                  title: '${itemPops![item.value]}',
                  radius: selectedItem == item.value ? 72 : 60,
                  titleStyle: sliceStyle,
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

const defaultPalette = [
  Colors.blue,
  Colors.red,
  Colors.green,
  Colors.amber,
  Colors.lightBlue,
  Colors.purple,
  Colors.orange,
  Colors.lime,
  Colors.pink,
  Colors.grey,
];
