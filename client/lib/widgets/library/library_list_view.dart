import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/game_tags.dart';
import 'package:espy/widgets/library/tags_context_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView(
        restorationId: 'list_view_game_entries_offset',
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: context
            .watch<GameEntriesModel>()
            .games
            .map(
              (entry) => Listener(
                child: ListTile(
                  leading: Hero(
                      tag: '${entry.game.id}_cover',
                      child: CircleAvatar(
                          foregroundImage: NetworkImage(
                              '${Urls.imageProvider}/t_thumb/${entry.game.cover.imageId}.jpg'))),
                  title: Text(entry.game.name),
                  subtitle: Text(
                      '${DateTime.fromMillisecondsSinceEpoch(entry.game.firstReleaseDate.seconds.toInt() * 1000).year}'),
                  trailing: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      for (final tag in entry.details.tag) TagChip(tag, entry)
                    ],
                  ),
                  onTap: () => context
                      .read<EspyRouterDelegate>()
                      .showGameDetails('${entry.game.id}'),
                ),
                onPointerDown: (PointerDownEvent event) async =>
                    await showTagsContextMenu(context, event, entry),
              ),
            )
            .toList(),
      ),
    );
  }
}
