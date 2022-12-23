import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/modules/models/recent_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class HomeSlatesModel extends ChangeNotifier {
  List<_SlateInfo> _slates = [];

  List<_SlateInfo> get slates => _slates;

  void update(
    GameEntriesModel gameEntries,
    RecentModel recentModel,
    GameTagsModel tagsModel,
  ) {
    _SlateInfo slate(
      String title, {
      LibraryFilter? filter,
      Iterable<LibraryEntry>? entries,
    }) {
      final filteredEntries = gameEntries.getEntries(filter: filter);
      return _SlateInfo(
          title: title, filter: filter, entries: entries ?? filteredEntries);
    }

    _slates = [
      slate('GOG', filter: LibraryFilter(stores: {'gog'})),
      slate('Steam', filter: LibraryFilter(stores: {'steam'})),
      slate('EGS', filter: LibraryFilter(stores: {'egs'})),
      slate('Battle.Net', filter: LibraryFilter(stores: {'battle.net'})),
      slate('Recent',
          entries: recentModel.recent
              .map((e) => gameEntries.getEntryById(e.libraryEntryId)!)),
      for (final tag in tagsModel.tagsByPopulation)
        slate(tag, filter: LibraryFilter(tags: {tag})),
    ];

    notifyListeners();
  }
}

class _SlateInfo {
  _SlateInfo({
    required this.title,
    required this.entries,
    this.filter,
  });

  String title;
  Iterable<LibraryEntry> entries = [];
  LibraryFilter? filter;
}
