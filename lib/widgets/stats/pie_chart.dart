import 'package:espy/widgets/stats/legend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:quiver/iterables.dart';

class EspyPieChart extends StatelessWidget {
  const EspyPieChart(
    this.items, {
    super.key,
    this.itemsPop,
    this.selectedItem,
    this.palette,
    this.unknownLabel,
    this.onItemTap,
    this.backLabel,
    this.onBack,
  });

  final List<String> items;
  final Map<String, int>? itemsPop;
  final String? selectedItem;
  final List<Color?>? palette;
  final String? unknownLabel;
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
            legend(),
            if (itemsPop?.isNotEmpty != null) chart(),
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
            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
          ),
          borderData: FlBorderData(
            show: false,
          ),
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          sections: [
            for (final item in enumerate(items))
              if (itemsPop![item.value] != null)
                PieChartSectionData(
                  color: palette?[item.index % items.length] ??
                      defaultPalette[item.index % items.length],
                  value: itemsPop![item.value] as double?,
                  title: '${itemsPop![item.value]}',
                  radius: 60,
                  titleStyle: sliceStyle,
                ),
            if (itemsPop![unknownLabel] != null)
              PieChartSectionData(
                color: Colors.grey,
                value: itemsPop![unknownLabel] as double?,
                title: '${itemsPop![unknownLabel]}',
                radius: 60,
                titleStyle: sliceStyle,
              ),
          ],
        ),
      ),
    );
  }

  SizedBox legend() {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (backLabel != null) ...[
            backButton(),
            const SizedBox(height: 4),
          ],
          for (final item in enumerate(items))
            LegendKey(
              color: palette?[item.index % items.length] ??
                  defaultPalette[item.index % items.length],
              text: item.value,
              textColor: item.value == selectedItem
                  ? Colors.blue
                  : itemsPop?[item.value] != null
                      ? Colors.white
                      : Colors.grey,
              isSquare: true,
              onTap: () => onItemTap?.call(item.value),
            ),
          if (unknownLabel != null && itemsPop?[unknownLabel] != null)
            LegendKey(
              color: Colors.grey,
              text: unknownLabel!,
              isSquare: true,
              onTap: () => onItemTap?.call(unknownLabel!),
            ),
        ],
      ),
    );
  }

  Widget backButton() {
    return LegendKey(
      color: Colors.white,
      text: backLabel!,
      isSquare: true,
      icon: Icons.keyboard_arrow_left,
      onTap: () => onBack?.call(),
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
  Colors.deepOrange,
  Colors.grey,
];
