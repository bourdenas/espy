import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
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
    AppConfigModel appConfigModel,
  ) {
    _SlateInfo slate(String title, LibraryFilter filter,
        [Iterable<LibraryEntry>? entries]) {
      return _SlateInfo(
          title: title,
          filter: filter,
          entries: entries ?? gameEntries.filter(filter));
    }

    _slates = [
      slate('Library', LibraryFilter(view: LibraryView.IN_LIBRARY)),
      slate('Wishlist', LibraryFilter(view: LibraryView.WISHLIST)),
      slate('Recent', LibraryFilter(), gameEntries.getRecentEntries()),
    ];

    _stacks = [
      if (appConfigModel.stacks.value == Stacks.COLLECTIONS)
        for (final collection in tagsModel.collections.nonSingleton)
          slate(collection, LibraryFilter(collections: {collection})),
      if (appConfigModel.stacks.value == Stacks.GENRES)
        for (final tag in tagsModel.userTags.tagByPopulationInCluster('genre'))
          slate(tag.name, LibraryFilter(tags: {tag.name})),
      if (appConfigModel.stacks.value == Stacks.STYLES)
        for (final tag in tagsModel.userTags.tagByPopulationInCluster('style'))
          slate(tag.name, LibraryFilter(tags: {tag.name})),
      if (appConfigModel.stacks.value == Stacks.THEMES)
        for (final tag in tagsModel.userTags.tagByPopulationInCluster('theme'))
          slate(tag.name, LibraryFilter(tags: {tag.name})),
    ];

    notifyListeners();
  }
}

class _SlateInfo {
  _SlateInfo({
    required this.title,
    required this.entries,
    required this.filter,
  });

  String title;
  Iterable<LibraryEntry> entries = [];
  LibraryFilter filter;
}
