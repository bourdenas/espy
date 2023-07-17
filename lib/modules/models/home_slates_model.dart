import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class HomeSlatesModel extends ChangeNotifier {
  List<SlateInfo> _slates = [];
  List<SlateInfo> _stacks = [];

  List<SlateInfo> get slates => _slates;
  List<SlateInfo> get stacks => _stacks;

  void update(
    LibraryEntriesModel gameEntries,
    WishlistModel wishlistModel,
    GameTagsModel tagsModel,
    AppConfigModel appConfigModel,
  ) {
    SlateInfo slate(String title, LibraryFilter filter,
        [Iterable<LibraryEntry>? entries]) {
      return SlateInfo(
          title: title,
          filter: filter,
          entries: entries ?? gameEntries.filter(filter));
    }

    _slates = [
      slate('Library', LibraryFilter(view: LibraryView.inLibrary)),
      slate('Wishlist', LibraryFilter(view: LibraryView.wishlist)),
      slate('Recent', LibraryFilter(), gameEntries.getRecentEntries()),
    ];

    _stacks = [
      if (appConfigModel.stacks.value == Stacks.collections)
        for (final collection in tagsModel.collections.nonSingleton)
          slate(collection, LibraryFilter(collections: {collection})),
      if (appConfigModel.stacks.value == Stacks.genres)
        for (final genre in tagsModel.genreTags.all)
          slate(genre.name, LibraryFilter(genreTags: {genre.encode()})),
      if (appConfigModel.stacks.value == Stacks.tags)
        for (final tag in tagsModel.userTags.tagByPopulationInCluster('genre'))
          slate(tag.name, LibraryFilter(tags: {tag.name})),
      if (appConfigModel.stacks.value == Stacks.styles)
        for (final tag in tagsModel.userTags.tagByPopulationInCluster('style'))
          slate(tag.name, LibraryFilter(tags: {tag.name})),
      if (appConfigModel.stacks.value == Stacks.themes)
        for (final tag in tagsModel.userTags.tagByPopulationInCluster('theme'))
          slate(tag.name, LibraryFilter(tags: {tag.name})),
    ];

    notifyListeners();
  }
}

class SlateInfo {
  SlateInfo({
    required this.title,
    required this.entries,
    required this.filter,
  });

  String title;
  Iterable<LibraryEntry> entries = [];
  LibraryFilter filter;
}
