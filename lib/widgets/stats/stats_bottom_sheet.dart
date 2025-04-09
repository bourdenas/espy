import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/widgets/stats/library_stats.dart';
import 'package:flutter/material.dart';

class StatsBottomSheet extends StatefulWidget {
  const StatsBottomSheet(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  State<StatsBottomSheet> createState() => _StatsBottomSheetState();
}

class _StatsBottomSheetState extends State<StatsBottomSheet> {
  static const speedThreshold = 100;

  bool showBottomSheet = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // final height = MediaQuery.of(context).size.height;

    return AnimatedPositioned(
      left: 0,
      bottom: showBottomSheet ? -12 : -280,
      duration: Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onPanEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy > speedThreshold) {
            setState(() {
              showBottomSheet = false;
            });
          } else if (details.velocity.pixelsPerSecond.dy < -speedThreshold) {
            setState(() {
              showBottomSheet = true;
            });
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
                    icon: Icon(showBottomSheet
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up),
                    onPressed: () {
                      setState(() {
                        showBottomSheet = !showBottomSheet;
                      });
                    },
                  ),
                  SizedBox(height: 8),
                  LibraryStats(widget.libraryEntries),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
