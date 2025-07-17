import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/widgets/loading_spinner.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:espy/widgets/tiles/tile_size.dart';
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
    this.libraryView = LibraryViewMode.year,
  });

  final Iterable<LibraryEntry> libraryEntries;
  final LibraryViewMode libraryView;

  List<Node> createAnnualNodes() {
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

    return nodes;
  }

  List<Node> createMonthlyNodes() {
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

    for (final year in years) {
      final monthlyGroups = <int, List<LibraryEntry>>{};
      for (final entry in groups[year] ?? <LibraryEntry>[]) {
        final releaseMonth = entry.digest.release.month;
        monthlyGroups.putIfAbsent(releaseMonth, () => []).add(entry);
      }
      final months = monthlyGroups.keys.toList()
        ..sort((a, b) => -a.compareTo(b));

      for (final month in months) {
        nodes.add(Node(DateTime.utc(year, month), monthlyGroups[month] ?? []));
      }
    }

    return nodes;
  }

  List<Node> createWeeklyNodes() {
    final today = DateTime.now().toUtc();
    final entries = libraryEntries
        .where((entry) => entry.digest.release.difference(today).inDays < 15)
        .toList()
      ..sort((l, r) => l.releaseDate.compareTo(r.releaseDate));

    final groups = <int, List<LibraryEntry>>{};
    for (final entry in entries) {
      final daysOff = entry.digest.release.weekday - 1;
      final hoursOff = entry.digest.release.hour;
      final week = entry.digest.release
          .subtract(Duration(days: daysOff, hours: hoursOff));
      groups.putIfAbsent(week.millisecondsSinceEpoch, () => []).add(entry);
    }

    final nodes = <Node>[];
    for (final group in groups.entries) {
      nodes.add(
          Node(DateTime.fromMillisecondsSinceEpoch(group.key), group.value));
    }
    nodes.sort((l, r) => -l.date.compareTo(r.date));

    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    if (libraryEntries.isEmpty) {
      return LoadingSpinner(message: 'Retrieving data...');
    }

    final isMobile = AppConfigModel.isMobile(context);
    final now = DateTime.now();

    final nodes = switch (libraryView) {
      LibraryViewMode.flat => createWeeklyNodes(),
      LibraryViewMode.month => createMonthlyNodes(),
      LibraryViewMode.year => createAnnualNodes(),
    };

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
      ),
    );
  }

  Widget connectorBuilder(BuildContext context, Node src, Node? dst) {
    final color = Theme.of(context).colorScheme.primary;

    final diff = src.date.difference(dst?.date ?? DateTime.utc(1970));
    return src.date.year == 1970 ||
            diff.inDays >
                switch (libraryView) {
                  LibraryViewMode.flat => 7,
                  LibraryViewMode.month => 31,
                  LibraryViewMode.year => 370,
                }
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
    final label = node.date.year > 1970
        ? switch (libraryView) {
            LibraryViewMode.flat => DateFormat('MMM d').format(node.date),
            LibraryViewMode.month => DateFormat('MMM y').format(node.date),
            LibraryViewMode.year => DateFormat('y').format(node.date),
          }
        : 'TBA';

    return SizedBox(
      width: 64,
      child: node.date.compareTo(now) < 0 && node.date.year != 1970
          ? IconButton.filled(
              icon: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              onPressed: () => onPressed(label),
            )
          : IconButton.outlined(
              icon: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              onPressed: () => onPressed(label),
            ),
    );
  }
}

class Node {
  final DateTime date;
  final List<LibraryEntry> libraryEntries;

  const Node(this.date, this.libraryEntries);
}
