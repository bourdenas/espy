import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/details/game_tags.dart';
import 'package:espy/widgets/library/filter_chips.dart';
import 'package:espy/widgets/library/tags_context_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Force to render the view when GameDetails (e.g. game tags) are updated.
    context.watch<GameDetailsModel>();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: FilterChips(),
        ),
        Expanded(
          child: Scrollbar(
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
                            tag: '${entry.id}_cover',
                            child: CircleAvatar(
                                foregroundImage: NetworkImage(
                                    '${Urls.imageProvider}/t_thumb/${entry.cover}.jpg'))),
                        title: Text(entry.name),
                        subtitle: Text(
                            '${DateTime.fromMillisecondsSinceEpoch(entry.releaseDate?.toInt() ?? 0 * 1000).year}'),
                        trailing: Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: [
                            for (final tag in entry.userData.tags)
                              TagChip(tag, entry)
                          ],
                        ),
                        onTap: () => context
                            .read<EspyRouterDelegate>()
                            .showGameDetails('${entry.id}'),
                      ),
                      onPointerDown: (PointerDownEvent event) async =>
                          await showTagsContextMenu(context, event, entry),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
