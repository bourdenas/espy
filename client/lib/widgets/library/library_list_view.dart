import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/config_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/details/game_tags.dart';
import 'package:espy/widgets/library/library_view.dart';
import 'package:espy/widgets/library/tags_context_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryListView extends LibraryView {
  const LibraryListView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final games = context.watch<GameEntriesModel>().games;

    return Scrollbar(
      child: ListView(
        restorationId: 'list_view_game_entries_offset',
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: games
            .map(
              (entry) => Listener(
                child: ListTile(
                  leading: Hero(
                    tag: '${entry.id}_cover',
                    child: CircleAvatar(
                      foregroundImage: NetworkImage(
                          '${Urls.imageProvider}/t_thumb/${entry.cover}.jpg'),
                    ),
                  ),
                  title: Text(entry.name),
                  subtitle: Text(
                      '${DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000).year}'),
                  trailing: context.read<AppConfig>().isNotMobile
                      ? Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: [
                            for (final tag in entry.userData.tags)
                              TagChip(tag: tag)
                          ],
                        )
                      : null,
                  onTap: () => context
                      .read<EspyRouterDelegate>()
                      .showGameDetails('${entry.id}'),
                ),
                onPointerDown: (PointerDownEvent event) async =>
                    showTagsContextMenu(context, event, entry),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  int visibleEntries(BuildContext context) =>
      (context.size!.height / _tileHeight).ceil();

  @override
  double get scrollThreshold => 8 * _tileHeight;

  static const _tileHeight = 64.0;
}
