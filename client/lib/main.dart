import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
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
      ChangeNotifierProvider(
        create: (context) {
          final model = GameLibraryModel();
          model.fetch();
          return model;
        },
        lazy: false,
      ),
      ChangeNotifierProxyProvider<GameLibraryModel, GameDetailsModel>(
        create: (context) => GameDetailsModel(),
        update: (context, libraryModel, model) =>
            model!..update(libraryModel.library),
      ),
      ChangeNotifierProxyProvider2<GameLibraryModel, GameDetailsModel,
          GameEntriesModel>(
        create: (context) => GameEntriesModel(),
        update: (context, libraryModel, detailsModel, model) =>
            model!..update(libraryModel.library),
      ),
      ChangeNotifierProxyProvider<GameLibraryModel, UnmatchedEntriesModel>(
        create: (context) => UnmatchedEntriesModel(),
        update: (context, libraryModel, model) =>
            model!..update(libraryModel.library),
      ),
    ],
    child: EspyApp(),
  ));
}
