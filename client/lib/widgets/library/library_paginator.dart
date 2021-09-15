import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/widgets/library/filter_chips.dart';
import 'package:espy/widgets/library/library_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryPaginator extends StatefulWidget {
  final LibraryView _view;

  LibraryPaginator(this._view);

  @override
  _LibraryPaginatorState createState() => _LibraryPaginatorState(_view);
}

class _LibraryPaginatorState extends State<LibraryPaginator> {
  final LibraryView _view;

  _LibraryPaginatorState(this._view);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final visibleEntries = _view.visibleEntries(context);
      if (visibleEntries > context.read<GameEntriesModel>().games.length) {
        context
            .read<GameLibraryModel>()
            .fetch(limit: (visibleEntries * 1.5).ceil());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        final visibleEntries = _view.visibleEntries(context);
        if (visibleEntries > context.read<GameEntriesModel>().games.length) {
          context.read<GameLibraryModel>().fetch(limit: visibleEntries);
        }

        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: FilterChips(),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  final visibleEntries = _view.visibleEntries(context);

                  if (scrollInfo.metrics.maxScrollExtent -
                          scrollInfo.metrics.pixels <
                      _view.scrollThreshold) {
                    context
                        .read<GameLibraryModel>()
                        .fetch(limit: visibleEntries);
                  }

                  return true;
                },
                child: _view,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
