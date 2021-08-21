import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showTagsContextMenu(
    BuildContext context, PointerDownEvent event, LibraryEntry entry) async {
  if (event.kind != PointerDeviceKind.mouse ||
      event.buttons != kSecondaryMouseButton) {
    return;
  }

  final overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;

  final selectedTag = await showMenu<String>(
    context: context,
    items: context
        .read<GameTagsIndex>()
        .tags
        .map((tag) => CheckedPopupMenuItem(
              child: Text(tag),
              value: tag,
              checked: entry.userData.tags.contains(tag),
            ))
        .toList(),
    position:
        RelativeRect.fromSize(event.position & Size(48, 48), overlay.size),
  );

  if (selectedTag == null) {
    return;
  }

  if (entry.userData.tags.contains(selectedTag)) {
    entry.userData.tags.remove(selectedTag);
  } else {
    entry.userData = GameUserData(tags: entry.userData.tags + [selectedTag]);
  }
  context.read<GameLibraryModel>().postDetails(entry);
}
