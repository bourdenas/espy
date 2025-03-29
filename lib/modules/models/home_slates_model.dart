import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeSlatesModel extends ChangeNotifier {
  List<SlateInfo> _slates = [];
  List<SlateInfo> _stacks = [];

  List<SlateInfo> get slates => _slates;
  List<SlateInfo> get stacks => _stacks;

  void update(
    AppConfigModel appConfigModel,
    UserLibraryModel libraryModel,
    WishlistModel wishlistModel,
    GameTagsModel tagsModel,
  ) {
    _slates = [
      SlateInfo(
        'New in library',
        libraryModel.entries.take(16).where((e) =>
            DateTime.now().difference(
                (DateTime.fromMillisecondsSinceEpoch(e.addedDate * 1000))) <
            const Duration(days: 30)),
        (context) {
          context.read<CustomViewModel>().clear();
          updateLibraryView(context);
        },
      ),
      SlateInfo(
        'Wishlist',
        wishlistModel.entries.take(16),
        (context) {
          context.read<CustomViewModel>().games =
              context.read<WishlistModel>().entries;
          context.pushNamed('wishlist');
        },
      ),
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
            (context) => context
                .pushNamed('collection', pathParameters: {'name': collection}),
          ),
      if (appConfigModel.stacks.value == Stacks.developers)
        for (final company in tagsModel.developers.all)
          SlateInfo(
            company,
            tagsModel.developers.games(company),
            (context) =>
                context.pushNamed('company', pathParameters: {'name': company}),
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
