import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      SlateInfo('Library', libraryModel.entries.take(16),
          (context) => updateLibraryView(context, LibraryFilter())),
      SlateInfo('Wishlist', wishlistModel.entries.take(16),
          (context) => context.goNamed('wishlist')),
    ];

    _stacks = [
      if (appConfigModel.stacks.value == Stacks.genres)
        for (final genre in tagsModel.genres.all)
          SlateInfo(
            genre,
            tagsModel.genres.games(genre),
            (context) =>
                updateLibraryView(context, LibraryFilter(genre: genre)),
          ),
      if (appConfigModel.stacks.value == Stacks.collections)
        for (final collection in tagsModel.collections.nonSingleton)
          SlateInfo(
            collection,
            tagsModel.collections.games(collection),
            (context) => updateLibraryView(
                context, LibraryFilter(collection: collection)),
          ),
      if (appConfigModel.stacks.value == Stacks.developers)
        for (final developer in tagsModel.developers.all)
          SlateInfo(
            developer,
            tagsModel.developers.games(developer),
            (context) =>
                updateLibraryView(context, LibraryFilter(developer: developer)),
          ),
    ];

    notifyListeners();
  }
}

class SlateInfo {
  SlateInfo(
    this.title,
    this.entries,
    this.onTap,
  );

  String title;
  Iterable<LibraryEntry> entries = [];
  void Function(BuildContext) onTap;
}
