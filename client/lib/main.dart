import 'package:espy/firebase_options.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/modules/models/recent_model.dart';
import 'package:espy/modules/models/user_data_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:espy/pages/espy_app.dart'
    if (dart.library.js) 'package:espy/pages/espy_app_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppConfigModel()..loadLocalPref()),
      ChangeNotifierProvider(create: (_) => UserDataModel()),
      ChangeNotifierProxyProvider<UserDataModel, GameLibraryModel>(
        create: (_) => GameLibraryModel(),
        update: (_, userDataModel, model) =>
            model!..update(userDataModel.userData),
      ),
      ChangeNotifierProxyProvider<UserDataModel, WishlistModel>(
        create: (_) => WishlistModel(),
        update: (_, userDataModel, model) =>
            model!..update(userDataModel.userData),
      ),
      ChangeNotifierProxyProvider<UserDataModel, RecentModel>(
        create: (_) => RecentModel(),
        update: (_, userDataModel, model) =>
            model!..update(userDataModel.userData),
      ),
      ChangeNotifierProxyProvider<GameLibraryModel, GameTagsModel>(
        create: (_) => GameTagsModel(),
        update: (_, libraryModel, model) {
          return model!..update(libraryModel.userId, libraryModel.entries);
        },
      ),
      ChangeNotifierProxyProvider2<GameLibraryModel, GameTagsModel,
          GameEntriesModel>(
        create: (_) => GameEntriesModel(),
        update: (_, libraryModel, gameTagsModel, model) {
          return model!..update(libraryModel.entries, gameTagsModel);
        },
      ),
      ChangeNotifierProxyProvider3<GameEntriesModel, RecentModel, GameTagsModel,
          HomeSlatesModel>(
        create: (_) => HomeSlatesModel(),
        update: (_, gameEntriesModel, recentModel, gameTagsModel, model) {
          return model!..update(gameEntriesModel, recentModel, gameTagsModel);
        },
      ),
    ],
    child: EspyApp(),
  ));
}
