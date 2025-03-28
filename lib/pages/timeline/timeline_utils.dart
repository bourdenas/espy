import 'package:espy/modules/documents/calendar.dart';
import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';

Widget connectorBuilder(
    BuildContext context, List<ReleaseEvent> releases, int index) {
  final color = switch (((int.tryParse(releases[0].year) ?? 0) -
          (int.tryParse(releases[index].year) ?? 0)) %
      4) {
    int x when x == 0 => Colors.redAccent,
    int x when x == 1 => Colors.blueAccent,
    int x when x == 2 => Colors.amberAccent,
    int x when x == 3 => Colors.greenAccent,
    _ => Colors.white,
  };

  final diff = releases[index]
      .games
      .first
      .release
      .difference(releases[index + 1].games.first.release);
  return diff.inDays >= 5
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
  List<ReleaseEvent> releases,
  int index,
  int now,
  void Function()? onPressed,
) {
  return SizedBox(
    width: 64,
    child: releases[index].games.first.releaseDate <= now
        ? IconButton.filled(
            icon: Text(releases[index].label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                )),
            onPressed: onPressed,
          )
        : IconButton.outlined(
            icon: Text(releases[index].label),
            onPressed: onPressed,
          ),
  );
}
