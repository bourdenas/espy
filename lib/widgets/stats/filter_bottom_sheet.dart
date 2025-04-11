import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/widgets/stats/library_stats.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  static const speedThreshold = 100;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final appConfig = context.watch<AppConfigModel>();

    return AnimatedPositioned(
      left: 0,
      bottom: appConfig.showBottomSheet ? -12 : -280,
      duration: Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onPanEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy > speedThreshold) {
            appConfig.showBottomSheet = false;
          } else if (details.velocity.pixelsPerSecond.dy < -speedThreshold) {
            appConfig.showBottomSheet = true;
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          child: Container(
            width: width - 80,
            height: 330,
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  IconButton(
                    icon: Icon(appConfig.showBottomSheet
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up),
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
