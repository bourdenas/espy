import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:uuid/uuid.dart';

class TimelineView extends StatelessWidget {
  const TimelineView(
    this.libraryEntries, {
    super.key,
    this.libraryView,
  });

  final Iterable<LibraryEntry> libraryEntries;
  final LibraryViewMode? libraryView;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final now = DateTime.now();

    final groups = <int, List<LibraryEntry>>{};
    for (final entry in libraryEntries) {
      final releaseYear = entry.digest.releaseYear;
      groups.putIfAbsent(releaseYear, () => []).add(entry);
    }
    final years = groups.keys.toList()..sort((a, b) => -a.compareTo(b));

    final nodes = <Node>[];
    if (years.last == 1970) {
      years.removeLast();
      nodes.add(Node(DateTime.utc(1970), groups[1970] ?? []));
    }

    for (int i = 0; i < years.length; ++i) {
      final (curr, next) =
          (years[i], i + 1 < years.length ? years[i + 1] : years[i] - 1);
      nodes.add(Node(DateTime.utc(curr), groups[curr] ?? []));

      if (curr - next == 2) {
        nodes.add(Node(DateTime.utc((curr + next) ~/ 2), []));
      }
    }

    final tileSize = isMobile ? 240.0 : 370.0;
    return Timeline.tileBuilder(
      primary: true,
      shrinkWrap: true,
      builder: TimelineTileBuilder.connected(
        itemCount: nodes.length,
        itemExtent: tileSize,
        connectorBuilder: (context, index, connectorType) =>
            connectorBuilder(context, nodes[index], nodes[index + 1]),
        indicatorBuilder: (context, index) => buttonBuilder(
          context,
          nodes[index],
          now,
          (String label) {
            final id = Uuid().v4();
            context
                .read<LibraryViewModel>()
                .addEntries(id, nodes[index].libraryEntries);
            context.pushNamed(
              'view',
              queryParameters: {'title': label, 'view': id},
            );
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
  return src.date.year == 1970 || diff.inDays > 370
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
  void Function(String) onPressed,
) {
  final label =
      node.date.year > 1970 ? DateFormat('y').format(node.date) : 'TBA';

  return SizedBox(
    width: 64,
    child: node.date.compareTo(now) < 0
        ? IconButton.filled(
            icon: Text(label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                )),
            onPressed: () => onPressed(label),
          )
        : IconButton.outlined(
            icon: Text(label),
            onPressed: () => onPressed(label),
          ),
  );
}
