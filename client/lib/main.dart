import 'package:espy/modules/models/appbar_search_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/library_filters_model.dart';
import 'package:espy/modules/models/unmatched_entries_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:espy/widgets/espy_app.dart'
    if (dart.library.js) 'package:espy/widgets/espy_app_web.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => EspyRouterDelegate()),
      ChangeNotifierProvider(create: (context) => AppBarSearchModel()),
      ChangeNotifierProvider(
        create: (context) => GameLibraryModel()..fetch(),
        lazy: false,
      ),
      ChangeNotifierProxyProvider<AppBarSearchModel, LibraryFiltersModel>(
        create: (context) => LibraryFiltersModel(),
        update: (context, appBarSearchModel, model) =>
            model!..update(appBarSearchModel.text),
      ),
      ChangeNotifierProxyProvider2<GameLibraryModel, AppBarSearchModel,
          GameDetailsModel>(
        create: (context) => GameDetailsModel(),
        update: (context, libraryModel, appBarSearchModel, model) =>
            model!..update(libraryModel.library, appBarSearchModel.text),
      ),
      ChangeNotifierProxyProvider2<GameLibraryModel, LibraryFiltersModel,
          GameEntriesModel>(
        create: (context) => GameEntriesModel(),
        update: (context, libraryModel, filtersModel, model) =>
            model!..update(libraryModel.library, filtersModel.filter),
      ),
      ChangeNotifierProxyProvider2<GameLibraryModel, AppBarSearchModel,
          UnmatchedEntriesModel>(
        create: (context) => UnmatchedEntriesModel(),
        update: (context, libraryModel, appBarSearchModel, model) =>
            model!..update(libraryModel.library, appBarSearchModel.text),
      ),
    ],
    child: EspyApp(),
  ));
}
