import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/proto/library.pb.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showTagsContextMenu(
    BuildContext context, PointerDownEvent event, GameEntry entry) async {
  if (event.kind != PointerDeviceKind.mouse ||
      event.buttons != kSecondaryMouseButton) {
    return;
  }

  final overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;

  final selectedTag = await showMenu<String>(
    context: context,
    items: context
        .read<GameDetailsModel>()
        .allTags
        .map((tag) => CheckedPopupMenuItem(
              child: Text(tag),
              value: tag,
              checked: entry.details.tag.contains(tag),
            ))
        .toList(),
    position:
        RelativeRect.fromSize(event.position & Size(48, 48), overlay.size),
  );

  if (selectedTag == null) {
    return;
  }

  if (entry.details.tag.contains(selectedTag)) {
    entry.details.tag.remove(selectedTag);
  } else {
    // NB: I don't get it why just "entry.details.tag.add(tag);"
    // fails and I need to clone GameDetails to edit it.
    entry.details = GameDetails()
      ..mergeFromMessage(entry.details)
      ..tag.add(selectedTag);
  }
  context.read<GameDetailsModel>().postDetails(entry);
}
