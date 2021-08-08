import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/details/game_tags.dart';
import 'package:espy/widgets/library/filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryTableView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Force to render the view when GameDetails (e.g. game tags) are updated.
    // context.watch<GameLibraryModel>();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: FilterChips(),
        ),
        Expanded(
          child: Scrollbar(
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
                      .watch<GameEntriesModel>()
                      .games
                      .map((entry) => DataRow(
                            cells: [
                              DataCell(
                                Row(children: [
                                  CircleAvatar(
                                      foregroundImage: NetworkImage(
                                          '${Urls.imageProvider}/t_thumb/${entry.cover}.jpg')),
                                  Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8)),
                                  Text(entry.name),
                                ]),
                                onTap: () => context
                                    .read<EspyRouterDelegate>()
                                    .showGameDetails('${entry.id}'),
                              ),
                              DataCell(Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: [
                                  for (final tag in entry.userData.tags)
                                    TagChip(tag, entry)
                                ],
                              )),
                              DataCell(Text(
                                  '${DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000).year}')),
                            ],
                          ))
                      .toList(),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
