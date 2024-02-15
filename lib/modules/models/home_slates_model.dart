import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class HomeSlatesModel extends ChangeNotifier {
  List<SlateInfo> _slates = [];
  List<SlateInfo> _stacks = [];

  List<SlateInfo> get slates => _slates;
  List<SlateInfo> get stacks => _stacks;

  void update(
    AppConfigModel appConfigModel,
    TimelineModel timeline,
    UserLibraryModel libraryModel,
    WishlistModel wishlistModel,
    GameTagsModel tagsModel,
  ) {
    _slates = [
      SlateInfo('Library', libraryModel.entries.take(16), LibraryFilter()),
      SlateInfo('Wishlist', wishlistModel.entries.take(16), LibraryFilter()),
    ];

    _stacks = [
      if (appConfigModel.stacks.value == Stacks.collections)
        for (final collection in tagsModel.collections.nonSingleton)
          SlateInfo(
            collection,
            tagsModel.collections.games(collection),
            LibraryFilter(collections: {collection}),
          ),
      if (appConfigModel.stacks.value == Stacks.developers)
        for (final developer in tagsModel.developers.all)
          SlateInfo(
            developer,
            tagsModel.developers.games(developer),
            LibraryFilter(developers: {developer}),
          ),
      if (appConfigModel.stacks.value == Stacks.genres)
        for (final genre in tagsModel.genreTags.all)
          SlateInfo(
            genre.name,
            tagsModel.genreTags.games(genre.name),
            LibraryFilter(genreTags: {genre.encode()}),
          ),
    ];

    notifyListeners();
  }
}

class SlateInfo {
  SlateInfo(
    this.title,
    this.entries,
    this.filter,
  );

  String title;
  Iterable<LibraryEntry> entries = [];
  LibraryFilter filter;
}
