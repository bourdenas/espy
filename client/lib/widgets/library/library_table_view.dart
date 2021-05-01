import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryTableView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                .watch<GameEntriesModel>()
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
                        DataCell(Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: [
                            for (final tag in entry.details.tag)
                              TagChip(tag, entry)
                          ],
                        )),
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
