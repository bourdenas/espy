import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/library/library_grid_view.dart';
import 'package:espy/widgets/library/library_list_view.dart';
import 'package:espy/widgets/library/library_table_view.dart';
import 'package:espy/widgets/library/unmatched_view.dart';
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
        ? LibraryGridView()
        : view == LibraryView.LIST
            ? LibraryListView()
            : LibraryTableView();

    if (context.watch<EspyRouterDelegate>().path.isUnmatchedPage) {
      viewWidget = UnmatchedView();
    }

    final filter = context.watch<GameEntriesModel>().filter;
    return Column(children: [
      Container(
          padding: EdgeInsets.all(16),
          child: Row(children: [
            for (final company in filter.companies) ...[
              InputChip(
                label: Text('${company.name}'),
                backgroundColor: Colors.red[900],
                onDeleted: () {
                  context.read<GameEntriesModel>().removeCompanyFilter(company);
                },
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
            ],
            for (final collection in filter.collections) ...[
              InputChip(
                label: Text('${collection.name}'),
                backgroundColor: Colors.indigo[800],
                onDeleted: () {
                  context
                      .read<GameEntriesModel>()
                      .removeCollectionFilter(collection);
                },
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
            ],
            for (final tag in filter.tags) ...[
              InputChip(
                label: Text(tag),
                onDeleted: () {
                  context.read<GameEntriesModel>().removeTagFilter(tag);
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
}
