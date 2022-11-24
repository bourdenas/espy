import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class HomeSlatesModel extends ChangeNotifier {
  List<_SlateInfo> _slates = [];

  List<_SlateInfo> get slates => _slates;

  void update(GameEntriesModel gameEntries, GameTagsModel tagsModel) {
    _SlateInfo slate(String title, LibraryFilter filter) {
      final filteredEntries = gameEntries.getEntries(filter: filter);
      return _SlateInfo(title: title, filter: filter, entries: filteredEntries);
    }

    _slates = [
      slate('GOG', LibraryFilter(stores: {'gog'})),
      slate('Steam', LibraryFilter(stores: {'steam'})),
      slate('EGS', LibraryFilter(stores: {'egs'})),
      slate('Battle.Net', LibraryFilter(stores: {'battle.net'})),
      for (final tag in tagsModel.tagsByPopulation)
        slate(tag, LibraryFilter(tags: {tag})),
    ];

    notifyListeners();
  }
}

class _SlateInfo {
  _SlateInfo({
    required this.title,
    required this.filter,
    required this.entries,
  });

  String title;
  LibraryFilter filter;
  Iterable<LibraryEntry> entries = [];
}
