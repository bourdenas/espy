import 'package:espy/modules/models/config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/appbar_search_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/filters_model.dart';
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
      ChangeNotifierProvider(create: (context) => AppConfig()),
      ChangeNotifierProvider(create: (context) => EspyRouterDelegate()),
      ChangeNotifierProvider(
          create: (context) => UserModel()..signInAuthenticatedUser()),
      ChangeNotifierProvider(create: (context) => AppBarSearchModel()),
      ChangeNotifierProxyProvider<UserModel, GameLibraryModel>(
        create: (context) => GameLibraryModel(),
        update: (context, userModel, model) {
          if (userModel.signedIn && model != null) {
            // print("LOG(INFO): updating GameLibraryModel");
            return model..update(userModel.user.uid);
          }
          return model!;
        },
      ),
      ChangeNotifierProxyProvider<AppBarSearchModel, FiltersModel>(
        create: (context) => FiltersModel(),
        update: (context, appBarSearchModel, model) {
          // print("LOG(INFO): updating LibraryFiltersModel");
          return model!..update(appBarSearchModel.text);
        },
      ),
      ChangeNotifierProxyProvider<GameLibraryModel, GameTagsIndex>(
        create: (context) => GameTagsIndex(),
        update: (context, libraryModel, model) {
          // print("LOG(INFO): updating GameTagsIndex");
          return model!..update(libraryModel.entries);
        },
      ),
      ChangeNotifierProxyProvider2<GameTagsIndex, AppBarSearchModel,
          GameTagsModel>(
        create: (context) => GameTagsModel(),
        update: (context, indexModel, appBarSearchModel, model) {
          // print("LOG(INFO): updating GameTagsModel");
          return model!..update(indexModel, appBarSearchModel.text);
        },
      ),
      ChangeNotifierProxyProvider2<GameLibraryModel, FiltersModel,
          GameEntriesModel>(
        create: (context) => GameEntriesModel(),
        update: (context, libraryModel, filtersModel, model) {
          // print("LOG(INFO): updating GameEntriesModel");
          return model!..update(libraryModel.entries, filtersModel.filter);
        },
      ),
      ChangeNotifierProxyProvider<UserModel, UnknownEntriesModel>(
        create: (context) => UnknownEntriesModel(),
        update: (context, userModel, model) {
          // print("LOG(INFO): updating UnknownEntriesModel");
          return model!..update(userModel.user.uid);
        },
      ),
      ChangeNotifierProxyProvider2<UnknownEntriesModel, AppBarSearchModel,
          UnmatchedEntriesModel>(
        create: (context) => UnmatchedEntriesModel(),
        update: (context, unknownModel, appBarSearchModel, model) {
          // print("LOG(INFO): updating UnmatchedEntriesModel");
          return model!..update(unknownModel, appBarSearchModel.text);
        },
      ),
    ],
    child: EspyApp(),
  ));
}
