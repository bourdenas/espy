import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/widgets/stats/library_stats.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterSidePane extends StatelessWidget {
  const FilterSidePane(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  static const speedThreshold = 100;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final appConfig = context.watch<AppConfigModel>();

    return AnimatedPositioned(
      top: 0,
      right: appConfig.showBottomSheet ? -20 : -480,
      duration: Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onPanEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx > speedThreshold) {
            appConfig.showBottomSheet = false;
          } else if (details.velocity.pixelsPerSecond.dx < -speedThreshold) {
            appConfig.showBottomSheet = true;
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          child: Container(
            width: 520,
            height: height - 54,
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(appConfig.showBottomSheet
                        ? Icons.keyboard_arrow_right
                        : Icons.keyboard_arrow_left),
                    onPressed: () {
                      appConfig.showBottomSheet = !appConfig.showBottomSheet;
                    },
                  ),
                  SizedBox(height: 8),
                  LibraryStats(libraryEntries),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
