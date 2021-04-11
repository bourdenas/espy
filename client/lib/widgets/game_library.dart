import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/game_card.dart';
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
        child: view == LibraryView.GRID
            ? gridView(context)
            : view == LibraryView.LIST
                ? listView(context)
                : tableView(context),
      ),
    ]);
  }

  Widget gridView(BuildContext context) {
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
              onTap: () => context.read<EspyRouterDelegate>().gameId =
                  '${entry.game.id}',
              child: GameCard(
                entry: entry,
              )))
          .toList(),
    ));
  }

  Widget listView(BuildContext context) {
    return Scrollbar(
      child: ListView(
        restorationId: 'list_view_game_entries_offset',
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: context
            .watch<GameLibraryModel>()
            .games
            .map(
              (entry) => ListTile(
                leading: CircleAvatar(
                    foregroundImage: NetworkImage(
                        '${Urls.imageProvider}/t_thumb/${entry.game.cover.imageId}.jpg')),
                title: Row(children: [
                  Text(entry.game.name),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8)),
                  Text(entry.details.tag.join(", ")),
                ]),
                subtitle: Text(
                    '${DateTime.fromMillisecondsSinceEpoch(entry.game.firstReleaseDate.seconds.toInt() * 1000).year}'),
                onTap: () => context.read<EspyRouterDelegate>().gameId =
                    '${entry.game.id}',
              ),
            )
            .toList(),
      ),
    );
  }

  Widget tableView(BuildContext context) {
    return Scrollbar(
      child: ListView(
        restorationId: 'table_view_game_entries_offset',
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          DataTable(
            dividerThickness: 0,
            sortColumnIndex: 2,
            columns: [
              DataColumn(
                label: Text(
                  'TITLE',
                  // style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              DataColumn(
                label: Text(
                  'TAGS',
                  // style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              DataColumn(
                label: Text(
                  'YEAR',
                  // style: TextStyle(fontStyle: FontStyle.italic),
                ),
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
                              .gameId = '${entry.game.id}',
                        ),
                        DataCell(Text(entry.details.tag.join(", "))),
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
