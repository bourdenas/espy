import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/proto/library.pb.dart';
import 'package:espy/widgets/game_card.dart';
import 'package:espy/widgets/game_tags.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum LibraryView {
  GRID,
  LIST,
  TABLE,
}

class GameLibrary extends StatelessWidget {
  final LibraryView view;

  const GameLibrary({Key? key, required this.view}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var viewWidget = view == LibraryView.GRID
        ? _gridView(context)
        : view == LibraryView.LIST
            ? _listView(context)
            : _tableView(context);

    if (context.watch<EspyRouterDelegate>().showUnmatched) {
      viewWidget = _umatchedListView(context);
    }

    final filter = context.watch<GameLibraryModel>().filter;
    return Column(children: [
      Container(
          padding: EdgeInsets.all(16),
          child: Row(children: [
            for (final company in filter.companies) ...[
              InputChip(
                label: Text('${company.name}'),
                backgroundColor: Colors.red[700],
                onDeleted: () {
                  context.read<GameLibraryModel>().removeCompanyFilter(company);
                },
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
            ],
            for (final collection in filter.collections) ...[
              InputChip(
                label: Text('${collection.name}'),
                backgroundColor: Colors.indigo[700],
                onDeleted: () {
                  context
                      .read<GameLibraryModel>()
                      .removeCollectionFilter(collection);
                },
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
            ],
            for (final tag in filter.tags) ...[
              InputChip(
                label: Text(tag),
                onDeleted: () {
                  context.read<GameLibraryModel>().removeTagFilter(tag);
                },
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
            ],
          ])),
      Expanded(
        child: viewWidget,
      ),
    ]);
  }

  Widget _gridView(BuildContext context) {
    return Scrollbar(
        child: GridView.extent(
      restorationId: 'grid_view_game_entries_grid_offset',
      maxCrossAxisExtent: 300,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      childAspectRatio: .75,
      children: context
          .watch<GameLibraryModel>()
          .games
          .map((entry) => InkResponse(
              enableFeedback: true,
              onTap: () => context
                  .read<EspyRouterDelegate>()
                  .showGameDetails('${entry.game.id}'),
              child: Listener(
                child: GameCard(
                  entry: entry,
                ),
                onPointerDown: (PointerDownEvent event) async =>
                    await _showEntryContextMenu(context, event, entry),
              )))
          .toList(),
    ));
  }

  Widget _listView(BuildContext context) {
    return Scrollbar(
      child: ListView(
        restorationId: 'list_view_game_entries_offset',
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: context
            .watch<GameLibraryModel>()
            .games
            .map(
              (entry) => Listener(
                child: ListTile(
                  leading: CircleAvatar(
                      foregroundImage: NetworkImage(
                          '${Urls.imageProvider}/t_thumb/${entry.game.cover.imageId}.jpg')),
                  title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.game.name),
                        GameChipsBar(entry),
                      ]),
                  subtitle: Text(
                      '${DateTime.fromMillisecondsSinceEpoch(entry.game.firstReleaseDate.seconds.toInt() * 1000).year}'),
                  onTap: () => context
                      .read<EspyRouterDelegate>()
                      .showGameDetails('${entry.game.id}'),
                ),
                onPointerDown: (PointerDownEvent event) async =>
                    await _showEntryContextMenu(context, event, entry),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _umatchedListView(BuildContext context) {
    return Scrollbar(
      child: ListView(
        restorationId: 'list_view_unmatched_game_entries_offset',
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: context
            .watch<GameLibraryModel>()
            .unmatchedGames
            .map(
              (storeEntry) => Listener(
                child: ListTile(
                  title: Row(children: [
                    Text(storeEntry.title),
                  ]),
                  subtitle: Text('${storeEntry.store}'),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _showEntryContextMenu(
      BuildContext context, PointerDownEvent event, GameEntry entry) async {
    if (event.kind != PointerDeviceKind.mouse ||
        event.buttons != kSecondaryMouseButton) {
      return;
    }

    final overlay =
        Overlay.of(context)!.context.findRenderObject() as RenderBox;

    final selectedTag = await showMenu<String>(
      context: context,
      items: context
          .read<GameLibraryModel>()
          .tags
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
    context.read<GameLibraryModel>().postDetails(entry);
  }

  Widget _tableView(BuildContext context) {
    return Scrollbar(
      child: ListView(
        restorationId: 'table_view_game_entries_offset',
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          DataTable(
            dividerThickness: 0,
            sortColumnIndex: 2,
            columns: [
              DataColumn(label: Text('TITLE')),
              DataColumn(label: Text('TAGS')),
              DataColumn(
                label: Text('YEAR'),
                numeric: true,
              ),
            ],
            rows: context
                .watch<GameLibraryModel>()
                .games
                .map((entry) => DataRow(
                      cells: [
                        DataCell(
                          Row(children: [
                            CircleAvatar(
                                foregroundImage: NetworkImage(
                                    '${Urls.imageProvider}/t_thumb/${entry.game.cover.imageId}.jpg')),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8)),
                            Text(entry.game.name),
                          ]),
                          onTap: () => context
                              .read<EspyRouterDelegate>()
                              .showGameDetails('${entry.game.id}'),
                        ),
                        DataCell(GameChipsBar(entry)),
                        DataCell(Text(
                            '${DateTime.fromMillisecondsSinceEpoch(entry.game.firstReleaseDate.seconds.toInt() * 1000).year}')),
                      ],
                    ))
                .toList(),
          )
        ],
      ),
    );
  }
}
