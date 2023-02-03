import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class HomeSlatesModel extends ChangeNotifier {
  List<_SlateInfo> _slates = [];
  List<_SlateInfo> _stacks = [];

  List<_SlateInfo> get slates => _slates;
  List<_SlateInfo> get stacks => _stacks;

  void update(
    GameEntriesModel gameEntries,
    WishlistModel wishlistModel,
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
      slate('Library', filter: LibraryFilter()),
      slate('Wishlist', entries: wishlistModel.wishlist),
      slate('Recent', entries: gameEntries.getRecentEntries()),
    ];

    _stacks = [
      for (final tag in tagsModel.tagClusterByPopulation('genre'))
        slate(tag.name, filter: LibraryFilter(tags: {tag.name})),
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
