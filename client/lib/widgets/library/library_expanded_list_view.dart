import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/details/game_tags.dart';
import 'package:espy/widgets/library/library_view.dart';
import 'package:espy/widgets/library/tags_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryExpandedListView extends LibraryView {
  const LibraryExpandedListView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filter =
        context.select((EspyRouterDelegate delegate) => delegate.filter);
    final games = context.watch<GameEntriesModel>().getEntries(filter);

    Widget title(LibraryEntry entry) {
      return Row(
        children: [
          Text(
            entry.name,
            // style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            style: Theme.of(context).textTheme.headline5,
          ),
        ],
      );
    }

    Widget content(LibraryEntry entry) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              title(entry),
              metadata(entry),
              tags(entry),
            ],
          ),
        ),
      );
    }

    Widget tile(LibraryEntry entry) {
      return Row(
        children: [
          poster(entry),
          content(entry),
        ],
      );
    }

    return Scrollbar(
      child: ListView(
        restorationId: 'expanded_list_view_game_entries_offset',
        children: games
            .map(
              (entry) => Listener(
                child: ListTile(
                  title: tile(entry),
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

  Widget poster(LibraryEntry entry) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Hero(
        tag: '${entry.id}_cover',
        child: CachedNetworkImage(
          imageUrl: '${Urls.imageProvider}/t_cover_med/${entry.cover}.jpg',
          errorWidget: (context, url, error) => Icon(Icons.error),
          fit: BoxFit.fitHeight,
        ),
      ),
    );
  }

  Widget metadata(LibraryEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
                '${DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000).year}'),
          ),
          // Text(entry.storeEntries.map((e) => e.storefront).join(', ')),
        ],
      ),
    );
  }

  Widget tags(LibraryEntry entry) {
    // return Expanded(
    //   child: ListView(
    //     shrinkWrap: true,
    //     scrollDirection: Axis.horizontal,
    //     children: [
    //       for (final tag in entry.userData.tags)
    //         Padding(
    //           padding: const EdgeInsets.all(2),
    //           child: TagChip(tag: tag),
    //         ),
    //     ],
    //   ),
    // );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          for (final store in entry.storeEntries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: StoreChip(store),
            ),
          for (final tag in entry.userData.tags)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: TagChip(tag: tag),
            ),
        ],
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
