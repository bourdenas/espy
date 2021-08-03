import 'package:espy/modules/models/appbar_search_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/library_filters_model.dart';
import 'package:espy/modules/models/unmatched_entries_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:espy/widgets/espy_app.dart'
    if (dart.library.js) 'package:espy/widgets/espy_app_web.dart';

Future<void> main() async {
  await Firebase.initializeApp();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
          create: (context) => UserModel()..signInAuthenticatedUser()),
      ChangeNotifierProvider(create: (context) => EspyRouterDelegate()),
      ChangeNotifierProvider(create: (context) => AppBarSearchModel()),
      ChangeNotifierProxyProvider<UserModel, GameLibraryModel>(
        create: (context) => GameLibraryModel(),
        update: (context, userModel, model) {
          if (userModel.signedIn && model != null) {
            return model..update(userModel.user.uid);
          }
          return model!;
        },
      ),
      ChangeNotifierProxyProvider<AppBarSearchModel, LibraryFiltersModel>(
        create: (context) => LibraryFiltersModel(),
        update: (context, appBarSearchModel, model) =>
            model!..update(appBarSearchModel.text),
      ),
      ChangeNotifierProxyProvider3<UserModel, GameLibraryModel,
          AppBarSearchModel, GameDetailsModel>(
        create: (context) => GameDetailsModel(),
        update: (context, userModel, libraryModel, appBarSearchModel, model) {
          if (userModel.signedIn && model != null) {
            return model
              ..update(userModel.user.uid, libraryModel.library,
                  appBarSearchModel.text);
          }
          return model!;
        },
      ),
      ChangeNotifierProxyProvider2<GameLibraryModel, LibraryFiltersModel,
          GameEntriesModel>(
        create: (context) => GameEntriesModel(),
        update: (context, libraryModel, filtersModel, model) =>
            model!..update(libraryModel.library, filtersModel.filter),
      ),
      ChangeNotifierProxyProvider<UserModel, UnknownEntriesModel>(
        create: (context) => UnknownEntriesModel(),
        update: (context, userModel, model) =>
            model!..update(userModel.user.uid),
      ),
      ChangeNotifierProxyProvider2<UnknownEntriesModel, AppBarSearchModel,
          UnmatchedEntriesModel>(
        create: (context) => UnmatchedEntriesModel(),
        update: (context, unknownModel, appBarSearchModel, model) =>
            model!..update(unknownModel, appBarSearchModel.text),
      ),
    ],
    child: EspyApp(),
  ));
}
