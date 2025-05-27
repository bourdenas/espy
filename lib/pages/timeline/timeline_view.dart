import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';

class TimelineView extends StatelessWidget {
  const TimelineView(this.libraryEntries, this.libraryView, {super.key});

  final Iterable<LibraryEntry> libraryEntries;
  final LibraryViewMode libraryView;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final now = DateTime.now();

    final groups = <int, List<LibraryEntry>>{};
    for (final entry in libraryEntries) {
      groups.putIfAbsent(entry.digest.releaseYear, () => []).add(entry);
    }
    final years = List.generate(now.year - 1979, (index) => (now.year - index));

    final nodes = years
        .map((year) => Node(DateTime.utc(year), groups[year] ?? []))
        .toList();

    final tileSize = isMobile ? 240.0 : 370.0;
    return Timeline.tileBuilder(
      primary: true,
      shrinkWrap: true,
      builder: TimelineTileBuilder.connected(
        itemCount: years.length,
        itemExtent: tileSize,
        connectorBuilder: (context, index, connectorType) =>
            connectorBuilder(context, nodes[index], nodes[index + 1]),
        indicatorBuilder: (context, index) => buttonBuilder(
          context,
          nodes[index],
          now,
          () {
            context.read<CustomViewModel>().games = nodes[index].libraryEntries;
            context.pushNamed('view');
          },
        ),
        nodePositionBuilder: (context, index) => .02,
        contentsBuilder: (context, index) {
          final libraryEntries = nodes[index].libraryEntries;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: TileCarousel(
              tileSize: isMobile
                  ? const TileSize(width: 133, height: 190)
                  : const TileSize(width: 227, height: 320),
              tiles: libraryEntries
                  .map((libraryEntry) => TileData(
                        image:
                            '${Urls.imageProvider}/t_cover_big/${libraryEntry.cover}.jpg',
                        onTap: () => context.pushNamed('details',
                            pathParameters: {'gid': '${libraryEntry.id}'}),
                      ))
                  .toList(),
            ),
          );
        },
        // oppositeContentsBuilder: (context, index) {
        //   final now = DateTime.now().millisecondsSinceEpoch / 1000;
        //
        //   return Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 8),
        //     child: releases[index].games.first.releaseDate <= now
        //         ? SizedBox(
        //             width: 4,
        //             child: Container(color: Colors.orangeAccent),
        //           )
        //         : Container(),
        //   );
        // },
      ),
    );
  }
}

class Node {
  final DateTime date;
  final List<LibraryEntry> libraryEntries;

  const Node(this.date, this.libraryEntries);
}

Widget connectorBuilder(BuildContext context, Node src, Node? dst) {
  final color = Theme.of(context).colorScheme.primary;

  final diff = src.date.difference(dst?.date ?? DateTime.utc(1970));
  return diff.inDays > 370
      ? DashedLineConnector(
          dash: 8,
          gap: 6,
          thickness: 4,
          color: color,
        )
      : SolidLineConnector(
          thickness: 4,
          color: color,
        );
}

Widget buttonBuilder(
  BuildContext context,
  Node node,
  DateTime now,
  void Function()? onPressed,
) {
  final label = DateFormat('y').format(node.date);

  return SizedBox(
    width: 64,
    child: node.date.compareTo(now) < 0
        ? IconButton.filled(
            icon: Text(label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                )),
            onPressed: onPressed,
          )
        : IconButton.outlined(
            icon: Text(label),
            onPressed: onPressed,
          ),
  );
}
